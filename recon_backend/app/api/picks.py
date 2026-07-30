import secrets

from flask import Blueprint, jsonify
from sqlalchemy import func

from ..errors import BadRequest, Conflict, NotFound
from ..extensions import db
from ..models import FinalPick, Option, Swipe
from ..services.access_tokens import utcnow
from .auth import body
from .deps import current_party, current_user, party_scope
from .serializers import party_dict, pick_dict

bp = Blueprint("picks", __name__)


def _active_member_ids(party):
    return [m.user_id for m in party.members if m.status == "active"]


@bp.post("/<public_id>/picks")
@party_scope(require_state="swiping")
def submit(public_id):
    """Record the caller's one final pick; re-submitting replaces it.

    submitted_count only moves on a first submission, so it is the true
    number of members who have picked, not the number of submissions.
    """
    data = body()
    option_id = data.get("option_id")
    if isinstance(option_id, bool) or not isinstance(option_id, int):
        raise BadRequest("invalid_option", "option_id must be an integer")

    party = current_party()
    option = Option.query.filter_by(party_id=party.id, id=option_id).one_or_none()
    if option is None:
        raise NotFound("option_not_found", "no such option in this party")

    user = current_user()
    pick = db.session.get(FinalPick, (party.id, user.id))
    created = pick is None
    if created:
        pick = FinalPick(party_id=party.id, user_id=user.id, option_id=option_id)
        db.session.add(pick)
        party.submitted_count += 1
    else:
        pick.option_id = option_id
    party.bump()
    db.session.commit()

    return jsonify(pick=pick_dict(pick), party=party_dict(party)), (201 if created else 200)


@bp.get("/<public_id>/picks")
@party_scope()
def all_picks(public_id):
    party = current_party()
    rows = (
        FinalPick.query.filter_by(party_id=party.id)
        .order_by(FinalPick.created_at.asc())
        .all()
    )
    return jsonify(picks=[pick_dict(p) for p in rows], party_version=party.version)


@bp.get("/<public_id>/progress")
@party_scope()
def progress(public_id):
    """Per-member swipe and pick progress, for the waiting room poll."""
    party = current_party()
    members = [m for m in party.members if m.status == "active"]

    swipe_counts = dict(
        db.session.query(Swipe.user_id, func.count())
        .filter(Swipe.party_id == party.id)
        .group_by(Swipe.user_id)
        .all()
    )
    picked_ids = {
        row[0]
        for row in db.session.query(FinalPick.user_id).filter_by(party_id=party.id).all()
    }

    entries = [
        {
            "user_id": m.user_id,
            "username": m.user.username,
            "display_name": m.user.profile.display_name if m.user.profile else m.user.username,
            "swiped_count": swipe_counts.get(m.user_id, 0),
            "has_picked": m.user_id in picked_ids,
        }
        for m in members
    ]
    return jsonify(
        progress=entries,
        option_count=party.option_count,
        party_version=party.version,
    )


@bp.post("/<public_id>/spin")
@party_scope(require_state=("swiping", "complete"))
def spin(public_id):
    """Pick the winner uniformly from the submitted final picks.

    Idempotent: once a winner exists, every later spin returns the same
    party unchanged, so racing clients all converge on one result.
    """
    party = current_party()
    if party.state == "complete":
        return jsonify(party=party_dict(party))

    active_ids = set(_active_member_ids(party))
    picks = [
        p
        for p in FinalPick.query.filter_by(party_id=party.id).all()
        if p.user_id in active_ids
    ]
    if len(picks) < len(active_ids):
        raise Conflict(
            "not_everyone_picked",
            "waiting on final picks",
            details={"picked": len(picks), "needed": len(active_ids)},
        )
    if not picks:
        raise Conflict("no_picks", "nobody submitted a pick")

    winner = secrets.choice(picks)
    party.winner_option_id = winner.option_id
    party.state = "complete"
    party.closed_at = utcnow()
    party.bump()
    db.session.commit()

    return jsonify(party=party_dict(party))
