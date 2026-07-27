from app.extensions import db
from app.models import Party
from tests.conftest import invite_code


def test_join_with_a_valid_code(client, host, guest, party):
    code = invite_code(client, host, party)
    response = client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)

    assert response.status_code == 200
    assert response.get_json()["party"]["member_count"] == 2


def test_join_tolerates_how_a_code_gets_retyped(client, host, guest, party):
    code = invite_code(client, host, party)
    mangled = code.replace("-", "").lower()
    response = client.post("/v1/parties/join", json={"invite_code": mangled}, headers=guest)
    assert response.status_code == 200


def test_join_is_idempotent(client, host, guest, party):
    code = invite_code(client, host, party)
    client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)
    again = client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)

    assert again.status_code == 200
    assert again.get_json()["party"]["member_count"] == 2


def test_bad_code_is_rejected(client, guest):
    response = client.post("/v1/parties/join", json={"invite_code": "AAAAA-BBBBB"}, headers=guest)
    assert response.status_code == 404
    assert response.get_json()["error"]["code"] == "invalid_code"


def test_minting_a_new_code_revokes_the_old_one(client, host, guest, party):
    old = invite_code(client, host, party)
    invite_code(client, host, party)

    response = client.post("/v1/parties/join", json={"invite_code": old}, headers=guest)
    assert response.status_code == 410
    assert response.get_json()["error"]["code"] == "code_revoked"


def test_cannot_join_once_swiping_has_started(client, app, host, guest, party):
    code = invite_code(client, host, party)
    row = Party.query.filter_by(public_id=party["id"]).one()
    row.option_count, row.state = 5, "swiping"
    db.session.commit()

    response = client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)
    assert response.status_code == 409
    assert response.get_json()["error"]["code"] == "party_already_started"


def test_start_requires_options(client, host, party):
    response = client.post(f"/v1/parties/{party['id']}/start", headers=host)
    assert response.status_code == 422
    assert response.get_json()["error"]["code"] == "not_enough_options"
