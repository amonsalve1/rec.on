import logging

import requests

from .base import PlaceCandidate, ProviderUnavailable

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
                external_id=f"{element.get('type')}/{element.get('id')}",
                raw=element,
            )
        )
    return candidates
