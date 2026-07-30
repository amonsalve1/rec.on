import secrets
import string
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    SmallInteger,
    String,
    func,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..extensions import db

TOPICS = ("restaurant", "movie", "activity")
PARTY_STATES = ("lobby", "swiping", "complete", "cancelled", "expired")
TERMINAL_STATES = ("complete", "cancelled", "expired")
ROLES = ("host", "member")
MEMBER_STATUSES = ("active", "left", "kicked")

MAX_MEMBERS = 20
MIN_OPTIONS = 2

_BASE62 = string.digits + string.ascii_letters


def new_public_id():
    """22 chars of base62 over 128 random bits.

    Replaces the sequential integer ids, which made every party on the server
    enumerable by anyone who could count.
    """
    value = int.from_bytes(secrets.token_bytes(16), "big")
    out = []
    while value:
        value, rem = divmod(value, 62)
        out.append(_BASE62[rem])
    return "".join(reversed(out)).rjust(22, "0")


class Party(db.Model):
    __tablename__ = "parties"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    public_id: Mapped[str] = mapped_column(
        String(22), nullable=False, unique=True, default=new_public_id
    )
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    topic: Mapped[str] = mapped_column(String(20), nullable=False)
    host_user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id"), nullable=False
    )
    state: Mapped[str] = mapped_column(
        String(20), nullable=False, default="lobby", server_default=text("'lobby'")
    )

    # denormalized so the 2s poll is one row read rather than three counts
    option_count: Mapped[int] = mapped_column(SmallInteger, nullable=False, server_default=text("0"))
    member_count: Mapped[int] = mapped_column(SmallInteger, nullable=False, server_default=text("0"))
    submitted_count: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, server_default=text("0")
    )

    center_lat: Mapped[Optional[float]] = mapped_column(Numeric(9, 6))
    center_lon: Mapped[Optional[float]] = mapped_column(Numeric(9, 6))
    radius_m: Mapped[Optional[int]] = mapped_column(Integer)
    provider: Mapped[Optional[str]] = mapped_column(String(20))

    # set when the spin lands; the party is complete from then on
    winner_option_id: Mapped[Optional[int]] = mapped_column(
        BigInteger,
        ForeignKey(
            "options.id",
            name="fk_parties_winner_option",
            use_alter=True,
            ondelete="SET NULL",
        ),
    )

    # bumped by every change a member could observe. drives the ETag.
    version: Mapped[int] = mapped_column(BigInteger, nullable=False, server_default=text("1"))

    swipe_deadline_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    closed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    members: Mapped[list["PartyMember"]] = relationship(
        back_populates="party", cascade="all, delete-orphan"
    )
    winner_option = relationship("Option", foreign_keys=[winner_option_id], post_update=True)

    __table_args__ = (
        CheckConstraint(f"topic IN {TOPICS}", name="ck_parties_topic"),
        CheckConstraint(f"state IN {PARTY_STATES}", name="ck_parties_state"),
        Index("ix_parties_host_user_id", "host_user_id"),
        Index("ix_parties_state_deadline", "state", "swipe_deadline_at"),
    )

    def bump(self):
        self.version += 1


class PartyMember(db.Model):
    __tablename__ = "party_members"

    party_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("parties.id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    role: Mapped[str] = mapped_column(String(10), nullable=False, server_default=text("'member'"))
    status: Mapped[str] = mapped_column(
        String(10), nullable=False, server_default=text("'active'")
    )
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    left_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    party: Mapped[Party] = relationship(back_populates="members")
    user = relationship("User")

    __table_args__ = (
        CheckConstraint(f"role IN {ROLES}", name="ck_party_members_role"),
        CheckConstraint(f"status IN {MEMBER_STATUSES}", name="ck_party_members_status"),
        Index(
            "uq_party_members_one_host",
            "party_id",
            unique=True,
            postgresql_where=text("role = 'host' AND status = 'active'"),
        ),
        Index("ix_party_members_user", "user_id", "joined_at"),
    )
