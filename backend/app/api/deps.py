from functools import wraps

from flask import g, request

from ..errors import Unauthorized
from ..extensions import db
from ..models import User
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
