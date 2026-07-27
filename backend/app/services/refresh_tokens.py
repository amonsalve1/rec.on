import uuid

from flask import current_app

from ..errors import Unauthorized
from ..extensions import db
from ..models.token import RefreshToken, hash_refresh_secret, new_refresh_secret
from .access_tokens import utcnow


def issue(user_id, family_id=None, user_agent=None):
    cfg = current_app.config
    now = utcnow()
    raw = new_refresh_secret()
    token = RefreshToken(
        id=uuid.uuid4(),
        user_id=user_id,
        family_id=family_id or uuid.uuid4(),
        token_hash=hash_refresh_secret(raw),
        expires_at=now + cfg["REFRESH_TOKEN_TTL"],
        family_expires_at=now + cfg["REFRESH_FAMILY_TTL"],
        user_agent=(user_agent or "")[:255] or None,
    )
    db.session.add(token)
    return raw, token


def revoke_family(family_id, reason):
    now = utcnow()
    live = RefreshToken.query.filter_by(family_id=family_id, revoked_at=None).all()
    for token in live:
        token.revoke(reason, now)
    return len(live)


def rotate(raw, user_agent=None):
    """Swap a refresh token for a fresh one in the same family.

    Presenting a token that was already rotated normally means a stolen copy
    is in play, so the whole family dies. The exception is the grace window:
    the client fires requests concurrently, so two 401s can race into two
    refreshes a few milliseconds apart. Inside that window we mint a sibling
    instead of revoking, which is why a flaky network doesn't sign people out.
    """
    now = utcnow()
    token = RefreshToken.query.filter_by(token_hash=hash_refresh_secret(raw)).one_or_none()
    if token is None:
        raise Unauthorized("invalid_refresh", "refresh token not recognised")
    if token.family_expires_at <= now:
        raise Unauthorized("refresh_expired", "please sign in again")

    if token.is_revoked:
        if token.revoked_reason != "rotation":
            # deliberately revoked (logout, password change, an earlier reuse).
            # not a theft signal, so don't report it as one.
            raise Unauthorized("invalid_refresh", "please sign in again")
        if (now - token.revoked_at) > current_app.config["REFRESH_GRACE"]:
            revoke_family(token.family_id, "reuse_detected")
            db.session.commit()
            raise Unauthorized("refresh_reused", "please sign in again")
        successor_of = None
    else:
        if token.expires_at <= now:
            raise Unauthorized("refresh_expired", "please sign in again")
        token.revoke("rotation", now)
        successor_of = token

    raw_next, next_token = issue(token.user_id, family_id=token.family_id, user_agent=user_agent)
    db.session.flush()
    if successor_of is not None:
        successor_of.replaced_by_id = next_token.id
    return token.user_id, raw_next, next_token
