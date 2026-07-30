from datetime import datetime

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..extensions import db


class FinalPick(db.Model):
    """One member's single favorite, chosen from what they swiped right on.

    Keyed on (party_id, user_id): a member has exactly one final pick and
    re-submitting replaces it. The composite FK mirrors swipes — a pick can
    only name an option that belongs to the same party.
    """

    __tablename__ = "final_picks"

    party_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("parties.id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    option_id: Mapped[int] = mapped_column(BigInteger, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    user = relationship("User")
    option = relationship(
        "Option",
        primaryjoin=(
            "and_(FinalPick.party_id == foreign(Option.party_id), "
            "FinalPick.option_id == foreign(Option.id))"
        ),
        viewonly=True,
        uselist=False,
    )

    __table_args__ = (
        ForeignKeyConstraint(
            ["party_id", "option_id"],
            ["options.party_id", "options.id"],
            ondelete="CASCADE",
            name="fk_final_picks_party_option",
        ),
    )
