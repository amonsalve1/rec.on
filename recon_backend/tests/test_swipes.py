from app.models import Swipe
from tests.conftest import invite_code


def start(client, host, party):
    response = client.post(f"/v1/parties/{party['id']}/start", headers=host)
    assert response.status_code == 200, response.get_json()


def option_ids(client, headers, party):
    response = client.get(f"/v1/parties/{party['id']}/options", headers=headers)
    assert response.status_code == 200, response.get_json()
    return [option["id"] for option in response.get_json()["options"]]


def swipe(client, headers, party, option_id, liked=True):
    return client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": option_id, "liked": liked},
        headers=headers,
    )


def test_swipe_records_a_verdict(client, host, party):
    ids = option_ids(client, host, party)
    start(client, host, party)

    response = swipe(client, host, party, ids[0], liked=True)
    assert response.status_code == 201
    assert response.get_json()["swipe"] == {"option_id": ids[0], "liked": True}


def test_reswipe_overwrites_instead_of_duplicating(client, host, party):
    ids = option_ids(client, host, party)
    start(client, host, party)

    first = swipe(client, host, party, ids[0], liked=True)
    second = swipe(client, host, party, ids[0], liked=False)

    assert first.status_code == 201
    assert second.status_code == 200
    assert second.get_json()["swipe"]["liked"] is False
    assert Swipe.query.count() == 1


def test_swipes_wait_for_the_party_to_start(client, host, party):
    ids = option_ids(client, host, party)

    response = swipe(client, host, party, ids[0])
    assert response.status_code == 409
    assert response.get_json()["error"]["code"] == "invalid_state"


def test_swiping_an_option_from_nowhere_is_a_404(client, host, party):
    start(client, host, party)

    response = swipe(client, host, party, 999_999)
    assert response.status_code == 404
    assert response.get_json()["error"]["code"] == "option_not_found"


def test_swipe_validates_its_body(client, host, party):
    ids = option_ids(client, host, party)
    start(client, host, party)

    bad_option = client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": "first", "liked": True},
        headers=host,
    )
    bad_liked = client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": ids[0], "liked": "yes"},
        headers=host,
    )

    assert bad_option.status_code == 400
    assert bad_option.get_json()["error"]["code"] == "invalid_option"
    assert bad_liked.status_code == 400
    assert bad_liked.get_json()["error"]["code"] == "invalid_liked"


def test_non_members_cannot_swipe_or_read(client, host, guest, party):
    ids = option_ids(client, host, party)
    start(client, host, party)

    response = swipe(client, guest, party, ids[0])
    read = client.get(f"/v1/parties/{party['id']}/swipes/me", headers=guest)

    # a non-member learns nothing, not even that the party exists
    assert response.status_code == 404
    assert read.status_code == 404


def test_swipes_me_returns_only_the_callers_rows(client, host, guest, party):
    code = invite_code(client, host, party)
    joined = client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)
    assert joined.status_code == 200

    ids = option_ids(client, host, party)
    start(client, host, party)

    swipe(client, host, party, ids[0], liked=True)
    swipe(client, host, party, ids[1], liked=False)
    swipe(client, guest, party, ids[0], liked=False)

    mine = client.get(f"/v1/parties/{party['id']}/swipes/me", headers=host)
    theirs = client.get(f"/v1/parties/{party['id']}/swipes/me", headers=guest)

    assert mine.status_code == 200
    assert mine.get_json()["swipes"] == [
        {"option_id": ids[0], "liked": True},
        {"option_id": ids[1], "liked": False},
    ]
    assert theirs.get_json()["swipes"] == [{"option_id": ids[0], "liked": False}]
