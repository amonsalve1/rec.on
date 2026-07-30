from app.models import FinalPick
from tests.conftest import invite_code


def start(client, host, party):
    response = client.post(f"/v1/parties/{party['id']}/start", headers=host)
    assert response.status_code == 200, response.get_json()


def option_ids(client, headers, party):
    response = client.get(f"/v1/parties/{party['id']}/options", headers=headers)
    assert response.status_code == 200, response.get_json()
    return [option["id"] for option in response.get_json()["options"]]


def join(client, host, guest, party):
    code = invite_code(client, host, party)
    response = client.post("/v1/parties/join", json={"invite_code": code}, headers=guest)
    assert response.status_code == 200, response.get_json()


def pick(client, headers, party, option_id):
    return client.post(
        f"/v1/parties/{party['id']}/picks", json={"option_id": option_id}, headers=headers
    )


def spin(client, headers, party):
    return client.post(f"/v1/parties/{party['id']}/spin", headers=headers)


def swipe(client, headers, party, option_id, liked=True):
    return client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": option_id, "liked": liked},
        headers=headers,
    )


def test_submitting_a_pick_counts_the_member_once(client, host, party):
    ids = option_ids(client, host, party)
    start(client, host, party)

    first = pick(client, host, party, ids[0])
    replaced = pick(client, host, party, ids[1])

    assert first.status_code == 201
    assert first.get_json()["party"]["submitted_count"] == 1
    assert replaced.status_code == 200
    assert replaced.get_json()["party"]["submitted_count"] == 1
    assert replaced.get_json()["pick"]["option"]["id"] == ids[1]
    assert FinalPick.query.count() == 1


def test_picks_wait_for_the_party_to_start(client, host, party):
    ids = option_ids(client, host, party)

    response = pick(client, host, party, ids[0])
    assert response.status_code == 409
    assert response.get_json()["error"]["code"] == "invalid_state"


def test_picking_an_option_from_nowhere_is_a_404(client, host, party):
    start(client, host, party)

    response = pick(client, host, party, 999_999)
    assert response.status_code == 404
    assert response.get_json()["error"]["code"] == "option_not_found"


def test_members_can_read_everyones_picks(client, host, guest, party):
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    pick(client, host, party, ids[0])
    pick(client, guest, party, ids[1])

    response = client.get(f"/v1/parties/{party['id']}/picks", headers=guest)
    assert response.status_code == 200
    picks = response.get_json()["picks"]
    assert {p["username"] for p in picks} == {"toli", "mei"}
    assert {p["option"]["id"] for p in picks} == {ids[0], ids[1]}


def test_progress_reports_swipes_and_picks_per_member(client, host, guest, party):
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": ids[0], "liked": True},
        headers=host,
    )
    pick(client, host, party, ids[0])

    response = client.get(f"/v1/parties/{party['id']}/progress", headers=guest)
    assert response.status_code == 200
    payload = response.get_json()
    entries = {e["username"]: e for e in payload["progress"]}

    assert payload["option_count"] == party["option_count"]
    assert entries["toli"]["swiped_count"] == 1
    assert entries["toli"]["has_picked"] is True
    assert entries["mei"]["swiped_count"] == 0
    assert entries["mei"]["has_picked"] is False


def test_spin_waits_for_every_active_member(client, host, guest, party):
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    pick(client, host, party, ids[0])

    response = spin(client, host, party)
    assert response.status_code == 409
    body = response.get_json()["error"]
    assert body["code"] == "not_everyone_picked"
    assert body["details"] == {"picked": 1, "needed": 2}


def test_spin_completes_the_party_with_a_winner_from_the_picks(client, host, guest, party):
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    pick(client, host, party, ids[0])
    pick(client, guest, party, ids[1])

    response = spin(client, guest, party)
    assert response.status_code == 200
    result = response.get_json()["party"]

    assert result["state"] == "complete"
    assert result["winner"]["id"] in (ids[0], ids[1])


def test_spin_is_idempotent_once_a_winner_exists(client, host, party):
    ids = option_ids(client, host, party)
    start(client, host, party)
    pick(client, host, party, ids[0])

    first = spin(client, host, party)
    second = spin(client, host, party)

    assert first.status_code == 200
    assert second.status_code == 200
    assert second.get_json()["party"]["winner"] == first.get_json()["party"]["winner"]
    assert second.get_json()["party"]["version"] == first.get_json()["party"]["version"]


def test_no_more_swipes_or_picks_after_completion(client, host, party):
    ids = option_ids(client, host, party)
    start(client, host, party)
    pick(client, host, party, ids[0])
    spin(client, host, party)

    late_swipe = client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": ids[0], "liked": True},
        headers=host,
    )
    late_pick = pick(client, host, party, ids[1])

    assert late_swipe.status_code == 409
    assert late_pick.status_code == 409


def test_non_members_see_nothing(client, host, guest, party):
    ids = option_ids(client, host, party)
    start(client, host, party)
    pick(client, host, party, ids[0])

    assert pick(client, guest, party, ids[0]).status_code == 404
    assert client.get(f"/v1/parties/{party['id']}/picks", headers=guest).status_code == 404
    assert client.get(f"/v1/parties/{party['id']}/progress", headers=guest).status_code == 404
    assert client.get(f"/v1/parties/{party['id']}/results", headers=guest).status_code == 404
    assert spin(client, guest, party).status_code == 404


def test_highest_approval_beats_the_picks(client, host, guest, party):
    """The approval count decides; picks only arbitrate ties."""
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    swipe(client, host, party, ids[0], liked=True)
    swipe(client, guest, party, ids[0], liked=True)
    swipe(client, guest, party, ids[1], liked=True)
    pick(client, host, party, ids[1])
    pick(client, guest, party, ids[1])

    response = spin(client, host, party)
    assert response.status_code == 200
    assert response.get_json()["party"]["winner"]["id"] == ids[0]


def test_tied_leaders_go_to_the_picked_option(client, host, guest, party):
    """A zero-pick option can never win a tie lottery."""
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    swipe(client, host, party, ids[0], liked=True)
    swipe(client, guest, party, ids[1], liked=True)
    pick(client, host, party, ids[0])
    pick(client, guest, party, ids[0])

    response = spin(client, host, party)
    assert response.status_code == 200
    assert response.get_json()["party"]["winner"]["id"] == ids[0]


def test_single_member_party_spins_from_likes_alone(client, host, party):
    """The solo flow: no pick step, winner drawn from the liked options."""
    ids = option_ids(client, host, party)
    start(client, host, party)

    swipe(client, host, party, ids[0], liked=True)
    swipe(client, host, party, ids[1], liked=False)

    response = spin(client, host, party)
    assert response.status_code == 200
    assert response.get_json()["party"]["winner"]["id"] == ids[0]


def test_spin_with_no_signal_is_a_conflict(client, host, party):
    option_ids(client, host, party)
    start(client, host, party)

    response = spin(client, host, party)
    assert response.status_code == 409
    assert response.get_json()["error"]["code"] == "no_votes"


def test_a_leavers_votes_stop_counting(client, host, guest, party):
    """The electorate is whoever is still in the party at spin time."""
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    swipe(client, guest, party, ids[1], liked=True)
    swipe(client, host, party, ids[0], liked=True)
    pick(client, host, party, ids[0])

    left = client.post(f"/v1/parties/{party['id']}/leave", headers=guest)
    assert left.status_code == 204

    response = spin(client, host, party)
    assert response.status_code == 200
    assert response.get_json()["party"]["winner"]["id"] == ids[0]


def test_results_reports_approvals_and_picks_per_option(client, host, guest, party):
    join(client, host, guest, party)
    ids = option_ids(client, host, party)
    start(client, host, party)

    swipe(client, host, party, ids[0], liked=True)
    swipe(client, guest, party, ids[0], liked=True)
    swipe(client, guest, party, ids[1], liked=False)
    pick(client, host, party, ids[0])
    pick(client, guest, party, ids[1])

    response = client.get(f"/v1/parties/{party['id']}/results", headers=host)
    assert response.status_code == 200
    payload = response.get_json()
    rows = {row["option"]["id"]: row for row in payload["results"]}

    assert rows[ids[0]]["approvals"] == 2
    assert rows[ids[0]]["picks"] == 1
    assert rows[ids[1]]["approvals"] == 0
    assert rows[ids[1]]["picks"] == 1
    assert payload["results"][0]["option"]["id"] == ids[0]  # sorted by approvals
    assert payload["winner"] is None

    spin(client, host, party)
    after = client.get(f"/v1/parties/{party['id']}/results", headers=host)
    assert after.get_json()["winner"]["id"] == ids[0]
