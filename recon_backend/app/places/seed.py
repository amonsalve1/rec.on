from .base import PlaceCandidate, ProviderUnavailable

# Moved off the client, where these lived in PartyOptionsGenerator and were
# served silently whenever location or Overpass failed. A party built from
# these is still a real party, but it is recorded as provider='seed' so a
# degraded one is diagnosable afterwards instead of looking identical to a
# party built from real nearby places.
# (name, tags, wikidata_id). An id is present only where it was verified to
# name the right entity AND that entity has a P18 image; everything else is
# None and the client draws its own lettered card. Do not add an id from
# memory: check the label and the image first, or the deck ends up showing a
# photograph of something unrelated.
SEEDS = {
    "restaurant": [
        ("Olive Garden", ["Italian", "Casual"], "Q3045312"),
        ("Sushi Sake", ["Japanese", "Sushi"], None),
        ("Chipotle", ["Mexican", "Fast Casual"], "Q465751"),
        ("Thai Express", ["Thai", "Quick"], None),
        ("Five Guys", ["Burgers", "Fast Food"], None),
        ("Domino's Pizza", ["Pizza", "Delivery"], "Q839466"),
        ("Panda Express", ["Chinese", "Fast Food"], "Q136378163"),
        ("Texas Roadhouse", ["Steakhouse", "Sit Down"], None),
    ],
    "movie": [
        ("The Matrix", ["Sci-Fi", "Action"], "Q83495"),
        ("Inception", ["Sci-Fi", "Thriller"], "Q25188"),
        ("The Dark Knight", ["Action", "Crime"], None),
        ("Pulp Fiction", ["Crime", "Drama"], "Q104123"),
        ("Interstellar", ["Sci-Fi", "Drama"], None),
        ("The Shawshank Redemption", ["Drama"], None),
        ("Fight Club", ["Drama", "Thriller"], None),
        ("Goodfellas", ["Crime", "Drama"], None),
    ],
    "activity": [
        ("Library", ["Quiet", "Free"], None),
        ("Coffee Shop", ["Casual", "Wifi"], None),
        ("Study Room", ["Quiet", "Bookable"], None),
        ("Campus Cafe", ["Casual", "Food"], None),
        ("Quiet Lounge", ["Quiet", "Comfortable"], None),
        ("Study Hall", ["Quiet", "Large"], None),
        ("Outdoor Patio", ["Outdoors", "Seasonal"], None),
        ("Study Center", ["Quiet", "Group Friendly"], None),
    ],
}


class SeedProvider:
    """Fallback catalogue, and the only source for topics with no geography.

    Movies and study spots were never location-based even on the client; the
    Overpass path only ever made sense for restaurants.
    """

    name = "seed"

    def search(self, *, topic, lat=None, lon=None, radius_m=None, limit=8):
        entries = SEEDS.get(topic)
        if not entries:
            raise ProviderUnavailable(f"no seed catalogue for topic {topic!r}")
        return [
            PlaceCandidate(
                name=name,
                tags=list(tags),
                external_id=f"seed/{topic}/{index}",
                wikidata=wikidata,
            )
            for index, (name, tags, wikidata) in enumerate(entries[:limit])
        ]
