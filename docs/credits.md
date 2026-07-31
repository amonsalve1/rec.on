# Image credits

Bundled artwork for the home topic cards. All three are CC0 (public domain
dedication) from Wikimedia Commons, so no attribution is legally required —
recorded here anyway so the provenance is traceable and the licence can be
re-checked before any store release.

| Asset | Source file (Wikimedia Commons) | Licence |
|---|---|---|
| `TopicFood` | Pepperoni and mushroom pizza - Massachusetts.jpg | CC0 |
| `TopicStudy` | Coffee in Montreal (Unsplash).jpg | CC0 |
| `TopicMovie` | Kalee projectors at the Cinema Museum, London.jpg | CC0 |

Each was downscaled to 600x780 and cropped to portrait for the card frame.
The movie image is cropped up from the bottom so the museum signage in the
original is out of frame.

Option artwork inside the app is not bundled: it is resolved at runtime from
the option's OpenStreetMap `image`/`wikimedia_commons` tag, or from its
Wikidata P18 image, and served through the backend
(`recon_backend/app/places/wikimedia.py`). Those images carry their own
licences on Commons.
