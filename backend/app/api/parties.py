from datetime import timedelta

from flask import Blueprint, jsonify, request

from ..errors import BadRequest, Conflict, ServiceUnavailable, Unprocessable
from ..extensions import db, limiter
from ..models import Option, Party, PartyMember
from ..models.party import MIN_OPTIONS, TOPICS
from ..places import ProviderUnavailable
from ..places.resolver import resolve
from ..services.access_tokens import utcnow
from .auth import body
from .deps import current_member, current_party, current_user, party_scope, require_auth
from .serializers import party_dict

bp = Blueprint("parties", __name__)

SWIPE_WINDOW = timedelta(hours=24)
COORD_PLACES = 3  # ~110m. rounded before it is ever persisted.


def snap(value):
    if value is None:
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        raise BadRequest("invalid_location", "lat and lon must be numbers")
    return round(number, COORD_PLACES)


def read_location(data):
    location = data.get("location")
    if location is None:
        return None, None
    if not isinstance(location, dict):
        raise BadRequest("invalid_location", "location must be an object")
    lat, lon = snap(location.get("lat")), snap(location.get("lon"))
    if lat is None or lon is None:
        raise BadRequest("invalid_location", "location needs both lat and lon")
    if not (-90 <= lat <= 90) or not (-180 <= lon <= 180):
        raise BadRequest("invalid_location", "coordinates out of range")
    return lat, lon


@bp.post("")
@require_auth
@limiter.limit("10 per hour")
def create():
    data = body()
    title = (data.get("title") or "").strip()
    topic = (data.get("topic") or "").strip().lower()

    if not title or len(title) > 120:
        raise BadRequest("invalid_title", "title is required, 120 characters max")
    if topic not in TOPICS:
        raise BadRequest("invalid_topic", f"topic must be one of {', '.join(TOPICS)}")

    lat, lon = read_location(data)
    user = current_user()
    now = utcnow()

    radius_m = data.get("radius_m") or 2000
    try:
        candidates, provider = resolve(topic=topic, lat=lat, lon=lon, radius_m=radius_m)
    except ProviderUnavailable as err:
        raise ServiceUnavailable("provider_unavailable", str(err))

    if len(candidates) < MIN_OPTIONS:
        raise Unprocessable(
            "no_options_found",
            "could not find enough to vote on",
            details={"found": len(candidates), "needed": MIN_OPTIONS},
        )

    party = Party(
        title=title,
        topic=topic,
        host_user_id=user.id,
        center_lat=lat,
        center_lon=lon,
        radius_m=radius_m,
        provider=provider,
        swipe_deadline_at=now + SWIPE_WINDOW,
        member_count=1,
        option_count=len(candidates),
    )
    db.session.add(party)
    db.session.flush()
    db.session.add(PartyMember(party_id=party.id, user_id=user.id, role="host"))

    for position, candidate in enumerate(candidates):
        db.session.add(
            Option(
                party_id=party.id,
                position=position,
                name=candidate.name,
                address=candidate.address,
                lat=candidate.lat,
                lon=candidate.lon,
                tags=candidate.tags,
                image_url=candidate.image_url,
                provider=provider,
                provider_place_id=candidate.external_id,
                provider_payload=candidate.raw,
            )
        )
    db.session.commit()

    return jsonify(party=party_dict(party)), 201


@bp.get("/<public_id>")
@party_scope()
def detail(public_id):
    party = current_party()
    response = jsonify(party=party_dict(party))
    response.set_etag(f"{party.public_id}-{party.version}")
    return response.make_conditional(request)


@bp.get("/<public_id>/options")
@party_scope()
def options(public_id):
    party = current_party()
    rows = (
        Option.query.filter_by(party_id=party.id).order_by(Option.position.asc()).all()
    )
    response = jsonify(options=[o.to_dict() for o in rows], party_version=party.version)
    if party.state != "lobby":
        # options are frozen once voting starts, so the deck is fetched once
        response.headers["Cache-Control"] = "private, max-age=3600, immutable"
    response.set_etag(f"opts-{party.public_id}-{party.option_count}")
    return response.make_conditional(request)


@bp.post("/<public_id>/start")
@party_scope(require_role="host", require_state="lobby")
def start(public_id):
    party = current_party()
    if party.option_count < MIN_OPTIONS:
        raise Unprocessable(
            "not_enough_options",
            "this party has nothing to vote on",
            details={"option_count": party.option_count, "needed": MIN_OPTIONS},
        )
    party.state = "swiping"
    party.bump()
    db.session.commit()
    return jsonify(party=party_dict(party))


@bp.post("/<public_id>/leave")
@party_scope()
def leave(public_id):
    party, member = current_party(), current_member()
    if member.role == "host" and party.state == "lobby":
        raise Conflict("host_cannot_leave_lobby", "cancel the party instead")

    member.status = "left"
    member.left_at = utcnow()
    party.member_count = max(0, party.member_count - 1)
    party.bump()
    db.session.commit()
    return "", 204


@bp.delete("/<public_id>")
@party_scope(require_role="host")
def cancel(public_id):
    party = current_party()
    if party.state in ("complete", "cancelled", "expired"):
        raise Conflict("invalid_state", f"party is already {party.state}")
    party.state = "cancelled"
    party.closed_at = utcnow()
    party.bump()
    db.session.commit()
    return "", 204
