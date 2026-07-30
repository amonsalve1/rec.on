import hashlib
import logging
from datetime import timedelta

from flask import current_app

from ..extensions import db
from ..models import ProviderCache
from ..services.access_tokens import utcnow
from .base import ProviderUnavailable
from .overpass import OverpassProvider, parse
from .seed import SeedProvider
from .wikimedia import WikidataImages, commons_file_url, parse_p18

log = logging.getLogger(__name__)

CACHE_TTL = timedelta(hours=24)
DEFAULT_LIMIT = 8

# only restaurants are geographic. movies and study spots never were, even on
# the client, so they go straight to the catalogue.
GEOGRAPHIC_TOPICS = {"restaurant"}


def cache_key(provider, topic, lat, lon, radius_m):
    raw = f"{provider}|{topic}|{lat}|{lon}|{radius_m}"
    return hashlib.sha256(raw.encode()).hexdigest()


def _cached(key):
    row = db.session.get(ProviderCache, key)
    if row is None:
        return None
    if row.expires_at <= utcnow():
        db.session.delete(row)
        return None
    return row.payload


def _store(key, payload):
    now = utcnow()
    db.session.merge(
        ProviderCache(cache_key=key, payload=payload, fetched_at=now, expires_at=now + CACHE_TTL)
    )


def overpass_provider():
    return OverpassProvider(user_agent=current_app.config["OVERPASS_USER_AGENT"])


def wikidata_provider():
    return WikidataImages(user_agent=current_app.config["OVERPASS_USER_AGENT"])


def fill_images(candidates):
    """Resolve commons images for candidates that carry a wikidata id.

    One batched wbgetentities call for the whole deck, cached like the
    overpass payloads. Images are decorative: any failure leaves image_url
    null and never blocks party creation.
    """
    missing = [c for c in candidates if not c.image_url and c.wikidata]
    ids = sorted({c.wikidata for c in missing})
    if not ids:
        return candidates

    key = cache_key("wikidata", "p18", "|".join(ids), None, None)
    payload = _cached(key)
    if payload is None:
        try:
            payload = wikidata_provider().fetch(ids)
            _store(key, payload)
        except ProviderUnavailable as err:
            log.warning("wikidata unavailable, options ship without images: %s", err)
            return candidates

    images = parse_p18(payload)
    for candidate in missing:
        file_name = images.get(candidate.wikidata)
        if file_name:
            candidate.image_url = commons_file_url(file_name)
    return candidates


def resolve(*, topic, lat=None, lon=None, radius_m=2000, limit=DEFAULT_LIMIT):
    """Find candidates for a party, falling back to the seed catalogue.

    Returns (candidates, provider_name). The provider name is stored on every
    option so a party built from fallback data is identifiable later.
    """
    if topic in GEOGRAPHIC_TOPICS and lat is not None and lon is not None:
        provider = overpass_provider()
        key = cache_key(provider.name, topic, lat, lon, radius_m)

        payload = _cached(key)
        if payload is not None:
            candidates = parse(payload)[:limit]
            if candidates:
                return fill_images(candidates), provider.name

        try:
            payload = provider.fetch(lat=lat, lon=lon, radius_m=radius_m)
            _store(key, payload)
            candidates = parse(payload)[:limit]
            if candidates:
                return fill_images(candidates), provider.name
            log.info("overpass returned nothing near %s,%s - falling back", lat, lon)
        except ProviderUnavailable as err:
            log.warning("overpass unavailable, falling back to seed: %s", err)

    return SeedProvider().search(topic=topic, limit=limit), SeedProvider.name
