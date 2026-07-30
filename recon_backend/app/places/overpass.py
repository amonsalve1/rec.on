import logging

import requests

from .base import PlaceCandidate, ProviderUnavailable
from .wikimedia import commons_file_url

log = logging.getLogger(__name__)

ENDPOINT = "https://overpass-api.de/api/interpreter"
AMENITIES = "^(restaurant|fast_food|cafe)$"
TIMEOUT_S = 10
RETRIES = 1

QUERY = """[out:json][timeout:25];
(
  way["amenity"~"{amenities}"](around:{radius},{lat},{lon});
  node["amenity"~"{amenities}"](around:{radius},{lat},{lon});
);
out center;
"""


def build_address(tags):
    """Assemble a street address from OSM's addr:* keys.

    Ported from the client's extractAddress. OSM tagging is inconsistent
    enough that this has to try several shapes before giving up.
    """
    full = (tags.get("addr:full") or "").strip()
    if full:
        return full

    parts = []
    house = (tags.get("addr:housenumber") or "").strip()
    street = (tags.get("addr:street") or "").strip()
    if house and street:
        parts.append(f"{house} {street}")
    elif street:
        parts.append(street)
    elif house:
        parts.append(house)

    for key in ("addr:suburb",):
        if tags.get(key):
            parts.append(tags[key].strip())

    city = (tags.get("addr:city") or tags.get("addr:place") or "").strip()
    if city:
        parts.append(city)
    for key in ("addr:state", "addr:postcode"):
        if tags.get(key):
            parts.append(tags[key].strip())

    return ", ".join(parts) or None


def build_tags(tags):
    out = []
    cuisine = (tags.get("cuisine") or "").strip()
    if cuisine:
        # OSM packs multiple cuisines into one semicolon-delimited value
        out.extend(part.strip() for part in cuisine.split(";") if part.strip())
    amenity = (tags.get("amenity") or "").strip()
    if amenity:
        out.append(amenity.replace("_", " ").title())
    return out


def build_image(tags):
    """An image URL straight from OSM tags, when the mapper provided one.

    `image` is a direct URL; `wikimedia_commons` is a File: reference that
    Special:FilePath can serve. Neither costs a network call.
    """
    image = (tags.get("image") or "").strip()
    if image.startswith(("http://", "https://")):
        return image

    commons = (tags.get("wikimedia_commons") or "").strip()
    if commons.startswith("File:"):
        return commons_file_url(commons)

    return None


def parse(payload):
    """Turn an Overpass response into candidates, de-duplicated by name."""
    candidates, seen = [], set()
    for element in payload.get("elements", []):
        tags = element.get("tags") or {}
        name = (tags.get("name") or "").strip()
        if not name or name.lower() in seen:
            continue
        seen.add(name.lower())

        center = element.get("center") or {}
        candidates.append(
            PlaceCandidate(
                name=name,
                address=build_address(tags),
                lat=element.get("lat", center.get("lat")),
                lon=element.get("lon", center.get("lon")),
                tags=build_tags(tags),
                image_url=build_image(tags),
                external_id=f"{element.get('type')}/{element.get('id')}",
                wikidata=(tags.get("wikidata") or "").strip() or None,
                raw=element,
            )
        )
    return candidates
class OverpassProvider:
    name = "overpass"

    def __init__(self, user_agent, session=None, endpoint=ENDPOINT):
        # overpass fair use asks for a contact address in the user agent
        self.user_agent = user_agent
        self.session = session or requests.Session()
        self.endpoint = endpoint

    def fetch(self, *, lat, lon, radius_m):
        query = QUERY.format(amenities=AMENITIES, radius=radius_m, lat=lat, lon=lon)
        last = None
        for attempt in range(RETRIES + 1):
            try:
                response = self.session.post(
                    self.endpoint,
                    data={"data": query},
                    headers={"User-Agent": self.user_agent},
                    timeout=TIMEOUT_S,
                )
                response.raise_for_status()
                return response.json()
            except Exception as err:
                last = err
                log.warning("overpass attempt %s failed: %s", attempt + 1, err)
        raise ProviderUnavailable(str(last))

    def search(self, *, topic, lat, lon, radius_m, limit):
        if lat is None or lon is None:
            raise ProviderUnavailable("overpass needs coordinates")
        return parse(self.fetch(lat=lat, lon=lon, radius_m=radius_m))[:limit]
