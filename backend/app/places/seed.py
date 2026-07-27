from .base import PlaceCandidate, ProviderUnavailable

# Moved off the client, where these lived in PartyOptionsGenerator and were
# served silently whenever location or Overpass failed. A party built from
# these is still a real party, but it is recorded as provider='seed' so a
# degraded one is diagnosable afterwards instead of looking identical to a
# party built from real nearby places.
SEEDS = {
    "restaurant": [
        ("Olive Garden", ["Italian", "Casual"]),
        ("Sushi Sake", ["Japanese", "Sushi"]),
        ("Chipotle", ["Mexican", "Fast Casual"]),
        ("Thai Express", ["Thai", "Quick"]),
        ("Five Guys", ["Burgers", "Fast Food"]),
        ("Domino's Pizza", ["Pizza", "Delivery"]),
        ("Panda Express", ["Chinese", "Fast Food"]),
        ("Texas Roadhouse", ["Steakhouse", "Sit Down"]),
    ],
    "movie": [
        ("The Matrix", ["Sci-Fi", "Action"]),
        ("Inception", ["Sci-Fi", "Thriller"]),
        ("The Dark Knight", ["Action", "Crime"]),
        ("Pulp Fiction", ["Crime", "Drama"]),
        ("Interstellar", ["Sci-Fi", "Drama"]),
        ("The Shawshank Redemption", ["Drama"]),
        ("Fight Club", ["Drama", "Thriller"]),
        ("Goodfellas", ["Crime", "Drama"]),
    ],
    "activity": [
        ("Library", ["Quiet", "Free"]),
        ("Coffee Shop", ["Casual", "Wifi"]),
        ("Study Room", ["Quiet", "Bookable"]),
        ("Campus Cafe", ["Casual", "Food"]),
        ("Quiet Lounge", ["Quiet", "Comfortable"]),
        ("Study Hall", ["Quiet", "Large"]),
        ("Outdoor Patio", ["Outdoors", "Seasonal"]),
        ("Study Center", ["Quiet", "Group Friendly"]),
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
            PlaceCandidate(name=name, tags=list(tags), external_id=f"seed/{topic}/{index}")
            for index, (name, tags) in enumerate(entries[:limit])
        ]
