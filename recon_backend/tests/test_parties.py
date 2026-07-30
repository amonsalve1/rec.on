import pytest

from app.models import Party


def test_public_id_is_not_enumerable(party):
    assert len(party["id"]) == 22
    assert not party["id"].isdigit()


def test_coordinates_are_rounded_before_storage(app, party):
    row = Party.query.filter_by(public_id=party["id"]).one()
    assert float(row.center_lat) == 42.453
    assert float(row.center_lon) == -76.474


def test_creator_is_host_and_only_member(party):
    assert party["member_count"] == 1
    assert party["members"][0]["role"] == "host"
    assert party["state"] == "lobby"


def test_bad_topic_is_rejected(client, host):
    response = client.post("/v1/parties", json={"title": "x", "topic": "tapas"}, headers=host)
    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "invalid_topic"


def test_detail_supports_conditional_requests(client, host, party):
    first = client.get(f"/v1/parties/{party['id']}", headers=host)
    assert first.status_code == 200

    cached = client.get(
        f"/v1/parties/{party['id']}", headers={**host, "If-None-Match": first.headers["ETag"]}
    )
    assert cached.status_code == 304


@pytest.mark.parametrize(
    "method,suffix",
    [
        ("get", ""),
        ("post", "/start"),
        ("post", "/leave"),
        ("delete", ""),
        ("post", "/invite"),
    ],
)
def test_every_party_route_hides_the_party_from_non_members(
    client, guest, party, method, suffix
):
    """A non-member must not be able to tell a party exists."""
    response = getattr(client, method)(f"/v1/parties/{party['id']}{suffix}", headers=guest)
    assert response.status_code == 404
    assert response.get_json()["error"]["code"] == "party_not_found"


def test_unknown_party_looks_identical_to_a_forbidden_one(client, host, guest, party):
    missing = client.get("/v1/parties/" + "0" * 22, headers=host)
    forbidden = client.get(f"/v1/parties/{party['id']}", headers=guest)
    assert missing.status_code == forbidden.status_code == 404
    assert missing.get_json()["error"]["code"] == forbidden.get_json()["error"]["code"]


