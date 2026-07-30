from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..extensions import db


class Swipe(db.Model):
    """One member's verdict on one option.

    The primary key is (party_id, option_id, user_id), so a re-swipe is an
    update, never a duplicate row. The composite FK onto (party_id, id) of
    options — the reason uq_options_party_id exists — makes it structurally
    impossible to record a swipe against an option from a different party.
    """

    __tablename__ = "swipes"

    party_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("parties.id", ondelete="CASCADE"), primary_key=True
    )
    option_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )

    liked: Mapped[bool] = mapped_column(Boolean, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    party = relationship("Party")
    user = relationship("User")

    __table_args__ = (
        ForeignKeyConstraint(
            ["party_id", "option_id"],
            ["options.party_id", "options.id"],
            ondelete="CASCADE",
            name="fk_swipes_party_option",
        ),
        # the per-member progress/liked reads
        Index("ix_swipes_party_user", "party_id", "user_id"),
    )

    def to_dict(self):
        return {
            "option_id": self.option_id,
            "liked": self.liked,
        }
