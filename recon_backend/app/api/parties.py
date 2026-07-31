from datetime import timedelta

from flask import Blueprint, jsonify, request
from sqlalchemy import func

from ..errors import BadRequest, Conflict, ServiceUnavailable, Unprocessable
from ..extensions import db, limiter
from ..models import FinalPick, Option, Party, PartyMember, Swipe
from ..models.party import MIN_OPTIONS, TOPICS
from ..places import ProviderUnavailable
from ..places.resolver import DEFAULT_LIMIT, resolve
from ..services.access_tokens import utcnow
from .auth import body
from .deps import current_member, current_party, current_user, party_scope, require_auth
from .serializers import party_dict

bp = Blueprint("parties", __name__)

SWIPE_WINDOW = timedelta(hours=24)
COORD_PLACES = 3  # ~110m. rounded before it is ever persisted.
LIST_LIMIT = 10
PREVIEW_POOL = 30


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


@bp.get("/preview")
@require_auth
@limiter.limit("30 per hour")
def preview():
    """One real nearby place, for the home screen's food card.

    Deliberately does not create anything: it reuses the resolver, so after
    the first call for a rounded coordinate the provider cache answers and
    this costs a single query. Prefers a candidate that has a photo, since
    the whole point is showing one.
    """
    lat, lon = snap(request.args.get("lat")), snap(request.args.get("lon"))
    if lat is None or lon is None:
        raise BadRequest("invalid_location", "lat and lon are required")
    if not (-90 <= lat <= 90) or not (-180 <= lon <= 180):
        raise BadRequest("invalid_location", "coordinates out of range")

    try:
        # look wider than a party's deck: the point is to find one that has a
        # photograph, and the nearest handful often have none
        candidates, provider = resolve(topic="restaurant", lat=lat, lon=lon, limit=PREVIEW_POOL)
    except ProviderUnavailable as err:
        raise ServiceUnavailable("provider_unavailable", str(err))

    if not candidates:
        return jsonify(place=None, count=0)

    pick = next((c for c in candidates if c.image_url), candidates[0])
    return jsonify(
        place={"name": pick.name, "image_url": pick.image_url, "address": pick.address},
        # the count a party would actually offer, not the size of the pool
        count=min(len(candidates), DEFAULT_LIMIT),
        provider=provider,
    )


@bp.get("")
@require_auth
def mine():
    """The caller's parties that are still live, freshest first.

    Carries a per-viewer block so the client can say "your turn" without a
    round trip per party: how many options this caller has swiped, and
    whether they have submitted their final pick.
    """
    user = current_user()
    rows = (
        Party.query.join(PartyMember, PartyMember.party_id == Party.id)
        .filter(
            PartyMember.user_id == user.id,
            PartyMember.status == "active",
            Party.state.in_(("lobby", "swiping")),
        )
        .order_by(Party.updated_at.desc())
        .limit(LIST_LIMIT)
        .all()
    )
    if not rows:
        return jsonify(parties=[])

    party_ids = [p.id for p in rows]
    swiped = dict(
        db.session.query(Swipe.party_id, func.count())
        .filter(Swipe.party_id.in_(party_ids), Swipe.user_id == user.id)
        .group_by(Swipe.party_id)
        .all()
    )
    picked = {
        row[0]
        for row in db.session.query(FinalPick.party_id)
        .filter(FinalPick.party_id.in_(party_ids), FinalPick.user_id == user.id)
        .all()
    }

    return jsonify(
        parties=[
            dict(
                party_dict(party),
                viewer={
                    "swiped_count": swiped.get(party.id, 0),
                    "has_picked": party.id in picked,
                },
            )
            for party in rows
        ]
    )


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
