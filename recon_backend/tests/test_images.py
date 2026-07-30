from app.places.overpass import parse
from app.places.wikimedia import commons_file_url, parse_p18


def element(id_, name, extra_tags=None):
    return {
        "type": "node",
        "id": id_,
        "lat": 42.45,
        "lon": -76.47,
        "tags": {"name": name, "amenity": "restaurant", **(extra_tags or {})},
    }


def create_party(client, host):
    response = client.post(
        "/v1/parties",
        json={
            "title": "Dinner",
            "topic": "restaurant",
            "location": {"lat": 42.4534891, "lon": -76.4735249},
        },
        headers=host,
    )
    assert response.status_code == 201, response.get_json()
    return response.get_json()["party"]


def options_of(client, host, party):
    response = client.get(f"/v1/parties/{party['id']}/options", headers=host)
    assert response.status_code == 200
    return {o["name"]: o for o in response.get_json()["options"]}


def test_commons_file_url_normalizes_the_file_name():
    url = commons_file_url("File:Joe's Diner (exterior).jpg")
    assert url == (
        "https://commons.wikimedia.org/wiki/Special:FilePath/"
        "Joe%27s_Diner_%28exterior%29.jpg?width=800"
    )


def test_parse_p18_takes_the_first_image_claim():
    payload = {
        "entities": {
            "Q1": {"claims": {"P18": [{"mainsnak": {"datavalue": {"value": "A.jpg"}}}]}},
            "Q2": {"claims": {}},
        }
    }
    assert parse_p18(payload) == {"Q1": "A.jpg"}


def test_parse_maps_osm_image_tags():
    payload = {
        "elements": [
            element(1, "Direct", {"image": "https://example.com/photo.jpg"}),
            element(2, "Commons", {"wikimedia_commons": "File:Commons Cafe.jpg"}),
            element(3, "Linked", {"wikidata": "Q42"}),
            element(4, "Bare"),
        ]
    }
    by_name = {c.name: c for c in parse(payload)}

    assert by_name["Direct"].image_url == "https://example.com/photo.jpg"
    assert "Special:FilePath/Commons_Cafe.jpg" in by_name["Commons"].image_url
    assert by_name["Linked"].image_url is None
    assert by_name["Linked"].wikidata == "Q42"
    assert by_name["Bare"].image_url is None


def test_wikidata_images_reach_the_created_options(client, host, stub_overpass, stub_wikidata):
    stub_overpass(
        {
            "elements": [
                element(1, "Linked", {"wikidata": "Q42"}),
                element(2, "Bare"),
            ]
        }
    )
    stub_wikidata(
        {"entities": {"Q42": {"claims": {"P18": [{"mainsnak": {"datavalue": {"value": "Linked Cafe.jpg"}}}]}}}}
    )

    party = create_party(client, host)
    options = options_of(client, host, party)

    assert "Special:FilePath/Linked_Cafe.jpg" in options["Linked"]["image_url"]
    assert options["Bare"]["image_url"] is None


def test_wikidata_failure_never_blocks_creation(client, host, stub_overpass):
    """The autouse guard makes wikidata unavailable; images just stay null."""
    stub_overpass(
        {
            "elements": [
                element(1, "Linked", {"wikidata": "Q42"}),
                element(2, "Also linked", {"wikidata": "Q43"}),
            ]
        }
    )

    party = create_party(client, host)
    options = options_of(client, host, party)

    assert party["option_count"] == 2
    assert all(o["image_url"] is None for o in options.values())


def test_direct_osm_images_skip_the_wikidata_call(client, host, stub_overpass):
    """Candidates with tag-level images need no lookup at all."""
    stub_overpass(
        {
            "elements": [
                element(1, "Direct", {"image": "https://example.com/a.jpg"}),
                element(2, "Commons", {"wikimedia_commons": "File:B.jpg"}),
            ]
        }
    )

    party = create_party(client, host)
    options = options_of(client, host, party)

    assert options["Direct"]["image_url"] == "https://example.com/a.jpg"
    assert "Special:FilePath/B.jpg" in options["Commons"]["image_url"]