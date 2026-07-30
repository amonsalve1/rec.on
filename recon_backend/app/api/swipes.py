from flask import Blueprint, jsonify

from ..errors import BadRequest, NotFound
from ..extensions import db
from ..models import Option, Swipe
from .auth import body
from .deps import current_party, current_user, party_scope

bp = Blueprint("swipes", __name__)


@bp.post("/<public_id>/swipes")
@party_scope(require_state="swiping")
def record(public_id):
    """Record the caller's verdict on one option.

    Re-swiping the same option overwrites the earlier verdict — the primary
    key makes a duplicate row impossible — so the client can safely retry.
    """
    data = body()
    option_id = data.get("option_id")
    liked = data.get("liked")

    if isinstance(option_id, bool) or not isinstance(option_id, int):
        raise BadRequest("invalid_option", "option_id must be an integer")
    if not isinstance(liked, bool):
        raise BadRequest("invalid_liked", "liked must be true or false")

    party = current_party()
    option = Option.query.filter_by(party_id=party.id, id=option_id).one_or_none()
    if option is None:
        raise NotFound("option_not_found", "no such option in this party")

    user = current_user()
    swipe = db.session.get(Swipe, (party.id, option_id, user.id))
    created = swipe is None
    if created:
        swipe = Swipe(party_id=party.id, option_id=option_id, user_id=user.id, liked=liked)
        db.session.add(swipe)
    else:
        swipe.liked = liked
    db.session.commit()

    return jsonify(swipe=swipe.to_dict()), (201 if created else 200)


@bp.get("/<public_id>/swipes/me")
@party_scope()
def mine(public_id):
    """The caller's own swipes, e.g. to rebuild the liked list after resume.

    Only ever the caller's rows: other members' verdicts stay private until
    the results stage.
    """
    party = current_party()
    rows = (
        Swipe.query.filter_by(party_id=party.id, user_id=current_user().id)
        .order_by(Swipe.option_id.asc())
        .all()
    )
    return jsonify(swipes=[s.to_dict() for s in rows])
