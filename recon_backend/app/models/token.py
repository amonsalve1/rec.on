import hashlib
import secrets
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, String, Uuid, func, text
from sqlalchemy.orm import Mapped, mapped_column

from ..extensions import db

REFRESH_TOKEN_BYTES = 32


def new_refresh_secret():
    return secrets.token_urlsafe(REFRESH_TOKEN_BYTES)


def hash_refresh_secret(raw):
    """Plain SHA-256, deliberately.

    The input is 256 bits of uniform randomness, not a low-entropy password,
    so there is nothing for a slow KDF to protect against.
    """
    return hashlib.sha256(raw.encode()).digest()


class RefreshToken(db.Model):
    __tablename__ = "refresh_tokens"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    # every token minted by rotating an ancestor shares its family. revoking on
    # reuse kills the whole lineage, not just the one token presented.
    family_id: Mapped[uuid.UUID] = mapped_column(Uuid, nullable=False)
    token_hash: Mapped[bytes] = mapped_column(db.LargeBinary(32), nullable=False, unique=True)

    issued_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    family_expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    revoked_reason: Mapped[Optional[str]] = mapped_column(String(32))
    replaced_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        Uuid, ForeignKey("refresh_tokens.id", ondelete="SET NULL")
    )

    user_agent: Mapped[Optional[str]] = mapped_column(String(255))

    __table_args__ = (
        Index(
            "ix_refresh_tokens_user_active",
            "user_id",
            postgresql_where=text("revoked_at IS NULL"),
        ),
        Index("ix_refresh_tokens_family_id", "family_id"),
    )

    @property
    def is_revoked(self):
        return self.revoked_at is not None

    def revoke(self, reason, at):
        if self.revoked_at is None:
            self.revoked_at = at
            self.revoked_reason = reason
