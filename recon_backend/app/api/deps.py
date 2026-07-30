from functools import wraps

from flask import g, request

from ..errors import Conflict, Forbidden, NotFound, Unauthorized
from ..extensions import db
from ..models import Party, PartyMember, User
from ..services import access_tokens


def current_user():
    return g.get("current_user")


def require_auth(fn):
    """Authenticate from the bearer token.

    Deliberately does not check token_epoch: that would be a database read on
    every poll. Epoch is verified on refresh instead, so "log out everywhere"
    takes effect within one access-token lifetime (10 minutes).
    """

    @wraps(fn)
    def wrapper(*args, **kwargs):
        header = request.headers.get("Authorization", "")
        scheme, _, raw = header.partition(" ")
        if scheme.lower() != "bearer" or not raw.strip():
            raise Unauthorized("missing_token", "authorization header required")

        claims = access_tokens.decode(raw.strip())
        user = db.session.get(User, int(claims["sub"]))
        if user is None or user.deleted_at is not None:
            raise Unauthorized("invalid_token", "user no longer exists")

        g.current_user = user
        g.access_claims = claims
        return fn(*args, **kwargs)

    return wrapper


def current_party():
    return g.get("current_party")


def current_member():
    return g.get("current_member")


def party_scope(param="public_id", require_role=None, require_state=None):
    """Resolve a party and authorize the caller against it.

    Every party-scoped route goes through this. The old backend checked
    membership route by route and missed five of them, which let anyone
    authenticated read any party's votes and trigger its result.

    A non-member gets 404, not 403, so this can't be used to test whether a
    party exists. Once membership is established, 403 is fine — the caller
    already knows it's there.
    """

    def decorator(fn):
        @wraps(fn)
        @require_auth
        def wrapper(*args, **kwargs):
            public_id = kwargs.get(param)
            party = Party.query.filter_by(public_id=public_id).one_or_none()
            if party is None:
                raise NotFound("party_not_found", "no such party")

            member = db.session.get(PartyMember, (party.id, current_user().id))
            if member is None or member.status != "active":
                raise NotFound("party_not_found", "no such party")

            if require_role == "host" and member.role != "host":
                raise Forbidden("not_host", "only the host can do that")

            if require_state is not None:
                allowed = (require_state,) if isinstance(require_state, str) else require_state
                if party.state not in allowed:
                    raise Conflict(
                        "invalid_state",
                        f"party is {party.state}",
                        details={"state": party.state, "expected": list(allowed)},
                    )

            g.current_party = party
            g.current_member = member
            return fn(*args, **kwargs)

        return wrapper

    return decorator
