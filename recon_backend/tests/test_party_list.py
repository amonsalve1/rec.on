from app.extensions import db
from app.models import Party
from tests.conftest import invite_code


def create_party(client, headers, title="Dinner"):
    response = client.post(
        "/v1/parties",
        json={"title": title, "topic": "movie"},
        headers=headers,
    )
    assert response.status_code == 201, response.get_json()
    return response.get_json()["party"]


def listed(client, headers):
    response = client.get("/v1/parties", headers=headers)
    assert response.status_code == 200, response.get_json()
    return response.get_json()["parties"]


def test_list_returns_only_your_own_live_parties(client, host, guest):
    mine = create_party(client, host, title="Mine")
    create_party(client, guest, title="Theirs")

    rows = listed(client, host)
    assert [p["title"] for p in rows] == ["Mine"]
    assert rows[0]["id"] == mine["id"]


def test_list_reports_your_progress(client, host, party):
    options = client.get(f"/v1/parties/{party['id']}/options", headers=host)
    ids = [o["id"] for o in options.get_json()["options"]]
    client.post(f"/v1/parties/{party['id']}/start", headers=host)

    client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": ids[0], "liked": True},
        headers=host,
    )

    rows = listed(client, host)
    assert rows[0]["viewer"] == {"swiped_count": 1, "has_picked": False}

    client.post(
        f"/v1/parties/{party['id']}/picks", json={"option_id": ids[0]}, headers=host
    )
    assert listed(client, host)[0]["viewer"]["has_picked"] is True


def test_progress_is_per_viewer(client, host, guest, party):
    code = invite_code(client, host, party)
    client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)

    options = client.get(f"/v1/parties/{party['id']}/options", headers=host)
    ids = [o["id"] for o in options.get_json()["options"]]
    client.post(f"/v1/parties/{party['id']}/start", headers=host)
    client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": ids[0], "liked": True},
        headers=host,
    )

    assert listed(client, host)[0]["viewer"]["swiped_count"] == 1
    assert listed(client, guest)[0]["viewer"]["swiped_count"] == 0


def test_finished_and_left_parties_drop_off_the_list(client, host, guest, party):
    code = invite_code(client, host, party)
    client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)

    assert len(listed(client, guest)) == 1
    client.post(f"/v1/parties/{party['id']}/leave", headers=guest)
    assert listed(client, guest) == []

    row = Party.query.filter_by(public_id=party["id"]).one()
    row.state = "complete"
    db.session.commit()
    assert listed(client, host) == []


def test_list_needs_auth(client):
    assert client.get("/v1/parties").status_code == 401
