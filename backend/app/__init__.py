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

    register_error_handlers(app)

    @app.get("/v1/health")
    @limiter.exempt
    def health():
        return jsonify(status="ok", api_version=1)

    return app
