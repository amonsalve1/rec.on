from flask import Flask, jsonify

from .config import Config
from .errors import register_error_handlers
from .extensions import db, limiter, migrate


def create_app(config=None):
    app = Flask(__name__)
    app.config.from_object((config or Config).load())

    db.init_app(app)
    migrate.init_app(app, db)
    limiter.init_app(app)

    from . import models  # noqa: F401  registers tables with alembic

    from .api.auth import bp as auth_bp
    from .api.invites import bp as invites_bp
    from .api.parties import bp as parties_bp
    from .api.swipes import bp as swipes_bp

    app.register_blueprint(auth_bp, url_prefix="/v1/auth")
    app.register_blueprint(parties_bp, url_prefix="/v1/parties")
    app.register_blueprint(invites_bp, url_prefix="/v1/parties")
    app.register_blueprint(swipes_bp, url_prefix="/v1/parties")

    register_error_handlers(app)

    @app.get("/v1/health")
    @limiter.exempt
    def health():
        return jsonify(status="ok", api_version=1)

    return app
