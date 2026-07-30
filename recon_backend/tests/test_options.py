from app.models import Option, Party
from app.places.base import ProviderUnavailable


NEARBY = {
    "elements": [
        {
            "type": "node",
            "id": 1,
            "lat": 42.44,
            "lon": -76.5,
            "tags": {
                "name": "Xi'an Street Food",
                "amenity": "restaurant",
                "cuisine": "chinese",
                "addr:housenumber": "120",
                "addr:street": "Dryden Rd",
                "addr:city": "Ithaca",
            },
        },
        {
            "type": "node",
            "id": 2,
            "lat": 42.45,
            "lon": -76.49,
            "tags": {"name": "Collegetown Bagels", "amenity": "cafe"},
        },
    ]
}


def create_party(client, host, topic="restaurant", location=True):
    body = {"title": "Dinner", "topic": topic}
    if location:
        body["location"] = {"lat": 42.4534891, "lon": -76.4735249}
    response = client.post("/v1/parties", json=body, headers=host)
    assert response.status_code == 201, response.get_json()
    return response.get_json()["party"]


def test_server_builds_options_with_real_metadata(client, host, stub_overpass):
    stub_overpass(NEARBY)
    party = create_party(client, host)

    assert party["option_count"] == 2
    rows = Option.query.order_by(Option.position).all()
    assert rows[0].name == "Xi'an Street Food"
    assert rows[0].address == "120 Dryden Rd, Ithaca"
    assert rows[0].provider == "overpass"
    assert rows[0].provider_place_id == "node/1"


def test_client_cannot_supply_its_own_options(client, host, stub_overpass):
    stub_overpass(NEARBY)
    response = client.post(
        "/v1/parties",
        json={
            "title": "Dinner",
            "topic": "restaurant",
            "location": {"lat": 42.45, "lon": -76.47},
            "options": ["Somewhere I Picked", "Another"],
        },
        headers=host,
    )
    names = {o.name for o in Option.query.all()}
    assert response.status_code == 201
    assert "Somewhere I Picked" not in names


def test_overpass_failure_falls_back_and_records_it(client, host, stub_overpass):
    stub_overpass(fail=True)
    party = create_party(client, host)

    row = Party.query.filter_by(public_id=party["id"]).one()
    assert row.provider == "seed"
    assert party["option_count"] == 8
    # a degraded party must be identifiable afterwards
    assert {o.provider for o in Option.query.all()} == {"seed"}


def test_party_without_location_uses_the_catalogue(client, host):
    party = create_party(client, host, location=False)
    assert party["option_count"] == 8
    assert Party.query.filter_by(public_id=party["id"]).one().provider == "seed"


def test_movies_never_touch_overpass(client, host, stub_overpass):
    stub_overpass(fail=True)  # would raise if called
    party = create_party(client, host, topic="movie")

    names = {o.name for o in Option.query.all()}
    assert "The Matrix" in names
    assert party["option_count"] == 8


def test_options_endpoint_serves_the_deck(client, host, stub_overpass):
    stub_overpass(NEARBY)
    party = create_party(client, host)

    response = client.get(f"/v1/parties/{party['id']}/options", headers=host)
    assert response.status_code == 200

    payload = response.get_json()["options"]
    assert [o["position"] for o in payload] == [0, 1]
    assert payload[0]["tags"] == ["chinese", "Restaurant"]
    # raw upstream blob must never reach a client
    assert "provider_payload" not in payload[0]
    assert "provider" not in payload[0]


def test_options_are_hidden_from_non_members(client, guest, host, stub_overpass):
    stub_overpass(NEARBY)
    party = create_party(client, host)

    response = client.get(f"/v1/parties/{party['id']}/options", headers=guest)
    assert response.status_code == 404


def test_start_works_once_there_are_options(client, host, stub_overpass):
    stub_overpass(NEARBY)
    party = create_party(client, host)

    response = client.post(f"/v1/parties/{party['id']}/start", headers=host)
    assert response.status_code == 200
    assert response.get_json()["party"]["state"] == "swiping"
