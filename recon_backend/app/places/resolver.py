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
                return candidates, provider.name

        try:
            payload = provider.fetch(lat=lat, lon=lon, radius_m=radius_m)
            _store(key, payload)
            candidates = parse(payload)[:limit]
            if candidates:
                return candidates, provider.name
            log.info("overpass returned nothing near %s,%s - falling back", lat, lon)
        except ProviderUnavailable as err:
            log.warning("overpass unavailable, falling back to seed: %s", err)

    return SeedProvider().search(topic=topic, limit=limit), SeedProvider.name
