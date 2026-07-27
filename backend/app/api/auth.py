import bcrypt
from flask import Blueprint, current_app, jsonify, request
from sqlalchemy import func

from ..errors import BadRequest, Conflict, Unauthorized
from ..extensions import db, limiter
from ..models import Profile, User
from ..models.user import (
    BCRYPT_ROUNDS,
    MAX_PASSWORD_BYTES,
    MIN_PASSWORD_CHARS,
    USERNAME_RE,
)
from ..services import access_tokens, refresh_tokens

bp = Blueprint("auth", __name__)

# compared against when the email is unknown, so a missing account costs the
# same wall-clock time as a wrong password. the old backend returned early,
# which let anyone probe for registered emails.
_DUMMY_HASH = bcrypt.hashpw(b"timing-equaliser", bcrypt.gensalt(rounds=BCRYPT_ROUNDS)).decode()


def body():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        raise BadRequest("invalid_body", "expected a json object")
    return data


def validate_password(raw):
    if not isinstance(raw, str) or len(raw) < MIN_PASSWORD_CHARS:
        raise BadRequest("weak_password", f"at least {MIN_PASSWORD_CHARS} characters")
    if len(raw.encode()) > MAX_PASSWORD_BYTES:
        raise BadRequest("password_too_long", f"at most {MAX_PASSWORD_BYTES} bytes")
    return raw


def token_payload(user, user_agent=None):
    access, expires_in = access_tokens.issue(user)
    raw_refresh, _ = refresh_tokens.issue(user.id, user_agent=user_agent)
    return {
        "access_token": access,
        "expires_in": expires_in,
        "refresh_token": raw_refresh,
        "refresh_expires_in": int(current_app.config["REFRESH_TOKEN_TTL"].total_seconds()),
    }


@bp.post("/register")
@limiter.limit("5 per minute")
def register():
    data = body()
    email = User.normalize_email(data.get("email"))
    username = (data.get("username") or "").strip()
    password = validate_password(data.get("password"))

    if "@" not in email or "." not in email.split("@")[-1]:
        raise BadRequest("invalid_email", "that email address is not valid")
    if not USERNAME_RE.match(username):
        raise BadRequest("invalid_username", "3-30 characters, letters, digits, _ or .")

    taken = User.query.filter(
        (func.lower(User.email) == email) | (func.lower(User.username) == username.lower())
    ).first()
    if taken is not None:
        # deliberately does not say which field, so this isn't an enumeration oracle
        raise Conflict("credentials_taken", "those details are already in use")

    user = User(email=email, username=username)
    user.set_password(password)
    db.session.add(user)
    db.session.flush()
    db.session.add(Profile(user_id=user.id, display_name=username))

    payload = token_payload(user, request.headers.get("User-Agent"))
    db.session.commit()
    return jsonify(user=user.to_dict(), **payload), 201


@bp.post("/login")
@limiter.limit("5 per minute")
def login():
    data = body()
    email = User.normalize_email(data.get("email"))
    password = data.get("password") or ""

    user = User.query.filter(func.lower(User.email) == email, User.deleted_at.is_(None)).first()
    if user is None:
        bcrypt.checkpw(password.encode()[:MAX_PASSWORD_BYTES], _DUMMY_HASH.encode())
        raise Unauthorized("invalid_credentials", "email or password is incorrect")
    if not user.check_password(password[:MAX_PASSWORD_BYTES]):
        raise Unauthorized("invalid_credentials", "email or password is incorrect")

    payload = token_payload(user, request.headers.get("User-Agent"))
    db.session.commit()
    return jsonify(user=user.to_dict(), **payload), 200
