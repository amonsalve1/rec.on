import logging
from urllib.parse import quote

import requests

from .base import ProviderUnavailable

log = logging.getLogger(__name__)

WIKIDATA_API = "https://www.wikidata.org/w/api.php"
THUMB_WIDTH = 800
TIMEOUT_S = 5
MAX_IDS = 50  # wbgetentities hard limit per request


def commons_file_url(value, width=THUMB_WIDTH):
    """A stable thumbnail URL for a commons file name.

    Special:FilePath redirects to the current upload location, so we never
    have to compute the hashed upload path ourselves; width makes commons
    serve a thumbnail instead of a full-resolution photo.
    """
    name = value.strip()
    if name.startswith("File:"):
        name = name[len("File:"):]
    name = name.strip().replace(" ", "_")
    if not name:
        return None
    return f"https://commons.wikimedia.org/wiki/Special:FilePath/{quote(name)}?width={width}"


def parse_p18(payload):
    """Map wikidata entity ids to their P18 (image) commons file names."""
    out = {}
    for entity_id, entity in (payload.get("entities") or {}).items():
        claims = ((entity or {}).get("claims") or {}).get("P18", [])
        for claim in claims:
            value = ((claim.get("mainsnak") or {}).get("datavalue") or {}).get("value")
            if isinstance(value, str) and value:
                out[entity_id] = value
                break
    return out


class WikidataImages:
    """One batched wbgetentities call resolves images for a whole deck."""

    name = "wikidata"

    def __init__(self, user_agent, session=None, endpoint=WIKIDATA_API):
        self.user_agent = user_agent
        self.session = session or requests.Session()
        self.endpoint = endpoint

    def fetch(self, ids):
        try:
            response = self.session.get(
                self.endpoint,
                params={
                    "action": "wbgetentities",
                    "ids": "|".join(ids[:MAX_IDS]),
                    "props": "claims",
                    "format": "json",
                },
                headers={"User-Agent": self.user_agent},
                timeout=TIMEOUT_S,
            )
            response.raise_for_status()
            return response.json()
        except Exception as err:
            raise ProviderUnavailable(str(err))
