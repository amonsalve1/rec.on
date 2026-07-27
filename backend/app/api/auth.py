import bcrypt
from flask import Blueprint, current_app, jsonify, request
from sqlalchemy import func

from ..errors import BadRequest, Conflict, Unauthorized
from ..extensions import db, limiter
from ..models import Profile, RefreshToken, User
from ..models.token import hash_refresh_secret
from ..models.user import (
    BCRYPT_ROUNDS,
    MAX_PASSWORD_BYTES,
    MIN_PASSWORD_CHARS,
    USERNAME_RE,
)
from ..services import access_tokens, refresh_tokens
from ..services.access_tokens import utcnow
from .deps import current_user, require_auth

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


@bp.post("/refresh")
@limiter.limit("30 per hour")
def refresh():
    raw = (body().get("refresh_token") or "").strip()
    if not raw:
        raise BadRequest("missing_refresh", "refresh_token is required")

    user_id, raw_next, _ = refresh_tokens.rotate(raw, request.headers.get("User-Agent"))
    user = db.session.get(User, user_id)
    if user is None or user.deleted_at is not None:
        raise Unauthorized("invalid_refresh", "user no longer exists")

    access, expires_in = access_tokens.issue(user)
    db.session.commit()
    return jsonify(
        access_token=access,
        expires_in=expires_in,
        refresh_token=raw_next,
        refresh_expires_in=int(current_app.config["REFRESH_TOKEN_TTL"].total_seconds()),
    )


@bp.post("/logout")
@require_auth
def logout():
    raw = (body().get("refresh_token") or "").strip()
    if raw:
        token = RefreshToken.query.filter_by(token_hash=hash_refresh_secret(raw)).one_or_none()
        if token is not None and token.user_id == current_user().id:
            refresh_tokens.revoke_family(token.family_id, "logout")
    db.session.commit()
    return "", 204


@bp.post("/logout-all")
@require_auth
def logout_all():
    user = current_user()
    RefreshToken.query.filter_by(user_id=user.id, revoked_at=None).update(
        {"revoked_at": utcnow(), "revoked_reason": "logout_all"}, synchronize_session=False
    )
    user.token_epoch += 1
    db.session.commit()
    return "", 204


@bp.get("/me")
@require_auth
def me():
    user = current_user()
    return jsonify(user=user.to_dict(), profile=user.profile.to_dict())
