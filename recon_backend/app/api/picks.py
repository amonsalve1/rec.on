import secrets

from flask import Blueprint, jsonify
from sqlalchemy import func, select

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


def _approval_counts(party, active_ids):
    """Liked-swipe count per option, counting only active members.

    The composite PK on swipes means each member has at most one verdict per
    option, so this is exactly the approval count. Members who left keep
    their rows but lose their vote: the electorate is whoever is still in
    the party when the spin happens.
    """
    rows = (
        db.session.query(Swipe.option_id, func.count())
        .filter(
            Swipe.party_id == party.id,
            Swipe.liked.is_(True),
            Swipe.user_id.in_(active_ids),
        )
        .group_by(Swipe.option_id)
        .all()
    )
    return dict(rows)


def _pick_counts(party, active_ids):
    return dict(
        db.session.query(FinalPick.option_id, func.count())
        .filter(FinalPick.party_id == party.id, FinalPick.user_id.in_(active_ids))
        .group_by(FinalPick.option_id)
        .all()
    )


def _choose_winner(approvals, picks):
    """Approval voting with a pick-weighted lottery tiebreak.

    1. The options with the highest approval count are the leaders.
    2. A single leader wins outright.
    3. Tied leaders go to a lottery weighted by how many final picks each
       received — the lottery only ever arbitrates genuine ties.
    4. If nobody liked anything, the picked options themselves are the
       leaders (a pick is still a preference).
    Returns the winning option_id, or None if there is no signal at all.
    """
    if approvals:
        top = max(approvals.values())
        leaders = [option_id for option_id, count in approvals.items() if count == top]
    elif picks:
        leaders = list(picks)
    else:
        return None

    if len(leaders) == 1:
        return leaders[0]

    weights = [picks.get(option_id, 0) for option_id in leaders]
    if sum(weights) == 0:
        return secrets.choice(leaders)
    return secrets.SystemRandom().choices(leaders, weights=weights, k=1)[0]


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


@bp.get("/<public_id>/results")
@party_scope()
def results(public_id):
    """Per-option approval and pick counts, plus the winner once spun.

    The concurrency answers the mechanic depends on, in one place:
    simultaneous swipes serialize through the composite-PK upsert and
    re-submitting a pick replaces the old row, so a member can never be
    counted twice; nobody can join after the lobby, so the electorate can
    only shrink; a member who leaves (or is expired with the party) drops
    out of both the approval electorate and the spin gate, so one vanished
    client cannot wedge the vote forever.
    """
    from ..models import PartyMember

    party = current_party()

    # one round trip: options left-joined to their approval and pick
    # aggregates, with the active electorate as a subquery. the naive
    # version was three queries plus a lazy members load; the profile said
    # the endpoint's time was round-trip wait, not work.
    active = select(PartyMember.user_id).where(
        PartyMember.party_id == party.id, PartyMember.status == "active"
    )
    approvals_sq = (
        select(Swipe.option_id, func.count().label("approvals"))
        .where(
            Swipe.party_id == party.id,
            Swipe.liked.is_(True),
            Swipe.user_id.in_(active),
        )
        .group_by(Swipe.option_id)
        .subquery()
    )
    picks_sq = (
        select(FinalPick.option_id, func.count().label("picks"))
        .where(FinalPick.party_id == party.id, FinalPick.user_id.in_(active))
        .group_by(FinalPick.option_id)
        .subquery()
    )
    rows = db.session.execute(
        select(
            Option,
            func.coalesce(approvals_sq.c.approvals, 0),
            func.coalesce(picks_sq.c.picks, 0),
        )
        .outerjoin(approvals_sq, approvals_sq.c.option_id == Option.id)
        .outerjoin(picks_sq, picks_sq.c.option_id == Option.id)
        .where(Option.party_id == party.id)
        .order_by(
            func.coalesce(approvals_sq.c.approvals, 0).desc(),
            Option.position.asc(),
        )
    ).all()

    return jsonify(
        results=[
            {"option": option.to_dict(), "approvals": approvals, "picks": picks}
            for option, approvals, picks in rows
        ],
        winner=party.winner_option.to_dict() if party.winner_option else None,
        party_version=party.version,
    )


@bp.post("/<public_id>/spin")
@party_scope(require_state=("swiping", "complete"))
def spin(public_id):
    """Complete the party: approval voting, pick-weighted lottery on ties.

    The gate: every active member must have submitted a final pick, except a
    single-member party, which may spin straight from its liked swipes —
    that is the solo flow, riding the same rule.

    Idempotent: once a winner exists, every later spin returns the same
    party unchanged, so racing clients all converge on one result.
    """
    party = current_party()
    if party.state == "complete":
        return jsonify(party=party_dict(party))

    active_ids = _active_member_ids(party)
    picks = _pick_counts(party, active_ids)
    picked_members = (
        db.session.query(func.count(FinalPick.user_id))
        .filter(FinalPick.party_id == party.id, FinalPick.user_id.in_(active_ids))
        .scalar()
    )

    if len(active_ids) > 1 and picked_members < len(active_ids):
        raise Conflict(
            "not_everyone_picked",
            "waiting on final picks",
            details={"picked": picked_members, "needed": len(active_ids)},
        )

    approvals = _approval_counts(party, active_ids)
    winner_option_id = _choose_winner(approvals, picks)
    if winner_option_id is None:
        raise Conflict("no_votes", "nobody liked or picked anything")

    party.winner_option_id = winner_option_id
    party.state = "complete"
    party.closed_at = utcnow()
    party.bump()
    db.session.commit()

    return jsonify(party=party_dict(party))
