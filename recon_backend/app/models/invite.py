import hmac
import secrets
from datetime import datetime
from hashlib import sha256
from typing import Optional

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, Integer, String, func, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..extensions import db

# Crockford base32: no I, L, O or U, so codes can be read aloud without
# ambiguity and O/0 and I/1 confusion is recoverable in normalize().
CODE_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
CODE_LENGTH = 10  # 32^10 = 50 bits


def new_code():
    raw = "".join(secrets.choice(CODE_ALPHABET) for _ in range(CODE_LENGTH))
    return f"{raw[:5]}-{raw[5:]}"


def normalize(code):
    cleaned = (code or "").upper().replace("-", "").replace(" ", "")
    return cleaned.replace("I", "1").replace("L", "1").replace("O", "0")


def hash_code(code, pepper):
    """Keyed hash, not a slow KDF.

    Join has to be an O(1) index lookup, so bcrypt is out. HMAC keeps the
    exact-match index while ensuring a database dump isn't a ready-made list
    of joinable parties.
    """
    return hmac.new(pepper, normalize(code).encode(), sha256).digest()


class Invite(db.Model):
    __tablename__ = "invites"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    party_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("parties.id", ondelete="CASCADE"), nullable=False
    )
    code_hmac: Mapped[bytes] = mapped_column(db.LargeBinary(32), nullable=False, unique=True)
    # first two characters in the clear, for support only
    code_prefix: Mapped[str] = mapped_column(String(2), nullable=False)

    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    max_uses: Mapped[Optional[int]] = mapped_column(Integer)
    uses: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    created_by: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    party = relationship("Party")

    __table_args__ = (
        Index(
            "uq_invites_one_live_per_party",
            "party_id",
            unique=True,
            postgresql_where=text("revoked_at IS NULL"),
        ),
    )

    def is_usable(self, now):
        if self.revoked_at is not None:
            return False
        if self.expires_at <= now:
            return False
        return self.max_uses is None or self.uses < self.max_uses
