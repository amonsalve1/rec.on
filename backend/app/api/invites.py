from datetime import timedelta

from flask import Blueprint, current_app, jsonify

from ..errors import Conflict, Gone, NotFound
from ..extensions import db, limiter
from ..models import Invite, PartyMember
from ..models.invite import hash_code, new_code
from ..models.party import MAX_MEMBERS
from ..services.access_tokens import utcnow
from .auth import body
from .deps import current_party, current_user, party_scope, require_auth
from .serializers import invite_dict, party_dict

bp = Blueprint("invites", __name__)

INVITE_TTL = timedelta(hours=24)


def _pepper():
    return current_app.config["SERVER_PEPPER"]


@bp.post("/<public_id>/invite")
@party_scope(require_role="host", require_state="lobby")
def mint(public_id):
    party = current_party()
    now = utcnow()

    # one live code per party, so rotating revokes whatever was shared before
    Invite.query.filter_by(party_id=party.id, revoked_at=None).update(
        {"revoked_at": now}, synchronize_session=False
    )

    code = new_code()
    invite = Invite(
        party_id=party.id,
        code_hmac=hash_code(code, _pepper()),
        code_prefix=code[:2],
        expires_at=now + INVITE_TTL,
        max_uses=MAX_MEMBERS,
        created_by=current_user().id,
    )
    db.session.add(invite)
    db.session.commit()

    # the plaintext exists only in this response; we stored a hmac
    return jsonify(invite=invite_dict(invite, code=code)), 201


@bp.post("/join")
@require_auth
@limiter.limit("10 per minute")
def join():
    code = (body().get("invite_code") or "").strip()
    if not code:
        raise NotFound("invalid_code", "that code is not valid")

    now = utcnow()
    invite = Invite.query.filter_by(code_hmac=hash_code(code, _pepper())).one_or_none()
    if invite is None:
        raise NotFound("invalid_code", "that code is not valid")
    if invite.revoked_at is not None:
        raise Gone("code_revoked", "that code is no longer active")
    if invite.expires_at <= now:
        raise Gone("code_expired", "that code has expired")

    party = invite.party
    user = current_user()

    existing = db.session.get(PartyMember, (party.id, user.id))
    if existing is not None and existing.status == "active":
        return jsonify(party=party_dict(party)), 200

    # lobby only. a fixed denominator for the whole vote is what makes
    # "3 of 4 have voted" a true statement.
    if party.state != "lobby":
        raise Conflict("party_already_started", "this party has already started")
    if party.member_count >= MAX_MEMBERS:
        raise Conflict("party_full", f"parties cap at {MAX_MEMBERS} people")
    if invite.max_uses is not None and invite.uses >= invite.max_uses:
        raise Gone("code_exhausted", "that code has been used up")

    if existing is not None:
        existing.status = "active"
        existing.left_at = None
    else:
        db.session.add(PartyMember(party_id=party.id, user_id=user.id, role="member"))

    invite.uses += 1
    party.member_count += 1
    party.bump()
    db.session.commit()
    return jsonify(party=party_dict(party)), 200
