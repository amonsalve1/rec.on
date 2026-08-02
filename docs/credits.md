# Image credits

The app bundles no photography. Home's topic cards are drawn from the
palette in `recon_frontend/recon/Utils/Constants.swift`, and option artwork
falls back to a lettered card when no picture exists.

Pictures that do appear are fetched at runtime and never redistributed with
the app: an option's image comes from its OpenStreetMap `image` or
`wikimedia_commons` tag, or from its Wikidata P18 image, resolved through
`recon_backend/app/places/wikimedia.py` and served as a Wikimedia Commons
`Special:FilePath` URL. Those files carry their own licences on Commons.

If bundled artwork is ever added, record the source file and licence here,
and prefer CC0 or public domain so no attribution is required in-app.
