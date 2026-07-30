from datetime import timedelta

from app.extensions import db
from app.models import Party
from app.services.access_tokens import utcnow


def age_out(public_id):
    row = Party.query.filter_by(public_id=public_id).one()
    row.swipe_deadline_at = utcnow() - timedelta(minutes=1)
    db.session.commit()
    return row


def test_sweep_expires_stale_parties(app, client, host, party):
    age_out(party["id"])

    result = app.test_cli_runner().invoke(args=["sweep-expired"])
    assert "expired 1 parties" in result.output

    response = client.get(f"/v1/parties/{party['id']}", headers=host)
    assert response.get_json()["party"]["state"] == "expired"


def test_sweep_leaves_live_and_finished_parties_alone(app, client, host, party):
    row = Party.query.filter_by(public_id=party["id"]).one()
    row.state = "complete"
    row.swipe_deadline_at = utcnow() - timedelta(minutes=1)
    db.session.commit()

    result = app.test_cli_runner().invoke(args=["sweep-expired"])
    assert "expired 0 parties" in result.output

    response = client.get(f"/v1/parties/{party['id']}", headers=host)
    assert response.get_json()["party"]["state"] == "complete"


def test_swept_party_rejects_further_play(app, client, host, party):
    started = client.post(f"/v1/parties/{party['id']}/start", headers=host)
    assert started.status_code == 200
    age_out(party["id"])

    app.test_cli_runner().invoke(args=["sweep-expired"])

    response = client.post(
        f"/v1/parties/{party['id']}/swipes",
        json={"option_id": 1, "liked": True},
        headers=host,
    )
    assert response.status_code == 409
    assert response.get_json()["error"]["code"] == "invalid_state"
