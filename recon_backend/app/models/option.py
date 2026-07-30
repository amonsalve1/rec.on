from datetime import datetime
from typing import Optional

from sqlalchemy import (
    ARRAY,
    BigInteger,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..extensions import db


class Option(db.Model):
    """A candidate in a party, with the metadata the client used to invent.

    The old server stored options as bare text, which is why the client had to
    smuggle address/image/tags back through the final-pick endpoint as a
    JSON string inside a JSON string, and why anyone who joined late saw
    "Address unknown" on every card.
    """

    __tablename__ = "options"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    party_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("parties.id", ondelete="CASCADE"), nullable=False
    )
    # canonical order, assigned once. this is the deterministic tiebreak key.
    position: Mapped[int] = mapped_column(SmallInteger, nullable=False)

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    address: Mapped[Optional[str]] = mapped_column(String(300))
    # full precision: this is a public venue, not a person
    lat: Mapped[Optional[float]] = mapped_column(Numeric(9, 6))
    lon: Mapped[Optional[float]] = mapped_column(Numeric(9, 6))
    tags: Mapped[list] = mapped_column(ARRAY(Text), nullable=False, server_default=text("'{}'"))
    image_url: Mapped[Optional[str]] = mapped_column(String(500))

    provider: Mapped[str] = mapped_column(String(20), nullable=False)
    provider_place_id: Mapped[Optional[str]] = mapped_column(String(100))
    # raw upstream blob for debugging; never serialized to a client
    provider_payload: Mapped[Optional[dict]] = mapped_column(JSONB)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    # explicit: parties.winner_option_id adds a second FK path between these
    # tables, and this relationship means "the party this option belongs to"
    party = relationship("Party", foreign_keys=[party_id])

    __table_args__ = (
        UniqueConstraint("party_id", "position", name="uq_options_party_position"),
        # exists so swipes can carry a composite FK and be structurally unable
        # to reference an option from a different party
        UniqueConstraint("party_id", "id", name="uq_options_party_id"),
        Index(
            "uq_options_provider_place",
            "party_id",
            "provider",
            "provider_place_id",
            unique=True,
            postgresql_where=text("provider_place_id IS NOT NULL"),
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "position": self.position,
            "name": self.name,
            "address": self.address,
            "lat": float(self.lat) if self.lat is not None else None,
            "lon": float(self.lon) if self.lon is not None else None,
            "tags": list(self.tags or []),
            "image_url": self.image_url,
        }


class ProviderCache(db.Model):
    """Overpass enforces a fair-use policy and will throttle under load.

    Keyed on coordinates already rounded to 3dp, which both maximises hit rate
    and means we never persist a precise fix.
    """

    __tablename__ = "provider_cache"

    cache_key: Mapped[str] = mapped_column(String(64), primary_key=True)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    fetched_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
