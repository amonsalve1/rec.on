from .base import PlaceCandidate, ProviderUnavailable

# Moved off the client, where these lived in PartyOptionsGenerator and were
# served silently whenever location or Overpass failed. A party built from
# these is still a real party, but it is recorded as provider='seed' so a
# degraded one is diagnosable afterwards instead of looking identical to a
# party built from real nearby places.
# (name, tags, wikidata_id). The wikidata id is only present where the entry
# is a real-world subject with a commons image behind it — the resolver turns
# those into artwork. Generic entries ("Study Room") deliberately have none;
# the client draws its own card for those.
SEEDS = {
    "restaurant": [
        ("Olive Garden", ["Italian", "Casual"], "Q3045150"),
        ("Sushi Sake", ["Japanese", "Sushi"], None),
        ("Chipotle", ["Mexican", "Fast Casual"], "Q465751"),
        ("Thai Express", ["Thai", "Quick"], None),
        ("Five Guys", ["Burgers", "Fast Food"], "Q1439803"),
        ("Domino's Pizza", ["Pizza", "Delivery"], "Q839466"),
        ("Panda Express", ["Chinese", "Fast Food"], "Q1055786"),
        ("Texas Roadhouse", ["Steakhouse", "Sit Down"], "Q7708986"),
    ],
    "movie": [
        ("The Matrix", ["Sci-Fi", "Action"], "Q83495"),
        ("Inception", ["Sci-Fi", "Thriller"], "Q25188"),
        ("The Dark Knight", ["Action", "Crime"], "Q166262"),
        ("Pulp Fiction", ["Crime", "Drama"], "Q104123"),
        ("Interstellar", ["Sci-Fi", "Drama"], "Q13417189"),
        ("The Shawshank Redemption", ["Drama"], "Q172241"),
        ("Fight Club", ["Drama", "Thriller"], "Q190050"),
        ("Goodfellas", ["Crime", "Drama"], "Q184768"),
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
