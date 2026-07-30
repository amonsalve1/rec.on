from dataclasses import dataclass, field
from typing import Optional, Protocol


@dataclass
class PlaceCandidate:
    """One candidate, normalized away from whatever the upstream shape was.

    Nothing above this layer knows Overpass exists.
    """

    name: str
    address: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None
    tags: list = field(default_factory=list)
    image_url: Optional[str] = None
    external_id: Optional[str] = None
    raw: Optional[dict] = None


class ProviderUnavailable(Exception):
    """Upstream failed in a way a retry might survive. Callers fall back."""


class PlacesProvider(Protocol):
    name: str

    def search(self, *, topic, lat, lon, radius_m, limit) -> list: ...
