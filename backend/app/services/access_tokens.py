import uuid
from datetime import datetime, timezone

import jwt
from flask import current_app

from ..errors import Unauthorized


def utcnow():
    return datetime.now(timezone.utc)


def issue(user):
    cfg = current_app.config
    now = utcnow()
    ttl = cfg["ACCESS_TOKEN_TTL"]
    claims = {
        "iss": cfg["JWT_ISSUER"],
        "aud": cfg["JWT_AUDIENCE"],
        "sub": str(user.id),
        "jti": str(uuid.uuid4()),
        "iat": now,
        "nbf": now,
        "exp": now + ttl,
        "typ": "access",
        "epoch": user.token_epoch,
    }
    token = jwt.encode(claims, cfg["JWT_SECRET_KEY"], algorithm=cfg["JWT_ALGORITHM"])
    return token, int(ttl.total_seconds())


def decode(token):
    """Verify against the current key, then the previous one if we're mid-rotation.

    Accepting the previous key for one access-token lifetime is what makes
    rotating JWT_SECRET_KEY zero-downtime.
    """
    cfg = current_app.config
    keys = [cfg["JWT_SECRET_KEY"]]
    if cfg.get("JWT_SECRET_KEY_PREVIOUS"):
        keys.append(cfg["JWT_SECRET_KEY_PREVIOUS"])

    last_error = None
    for key in keys:
        try:
            claims = jwt.decode(
                token,
                key,
                algorithms=[cfg["JWT_ALGORITHM"]],
                issuer=cfg["JWT_ISSUER"],
                audience=cfg["JWT_AUDIENCE"],
            )
        except jwt.ExpiredSignatureError:
            raise Unauthorized("token_expired", "access token has expired")
        except jwt.InvalidTokenError as err:
            last_error = err
            continue

        if claims.get("typ") != "access":
            raise Unauthorized("invalid_token", "wrong token type")
        return claims

    raise Unauthorized("invalid_token", str(last_error) if last_error else "invalid token")
