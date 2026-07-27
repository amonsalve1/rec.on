import os
from datetime import timedelta

from dotenv import load_dotenv

load_dotenv()


class ConfigError(RuntimeError):
    pass


def _required(name):
    value = os.environ.get(name, "").strip()
    if not value:
        raise ConfigError(
            f"{name} is not set. Copy backend/.env.example to backend/.env "
            f"and fill it in, or export {name} in the environment."
        )
    return value


class Config:
    DEBUG = False
    TESTING = False

    SQLALCHEMY_DATABASE_URI = None
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {"pool_pre_ping": True}

    JWT_SECRET_KEY = None
    JWT_SECRET_KEY_PREVIOUS = None
    JWT_ALGORITHM = "HS256"
    JWT_ISSUER = "recon-api"
    JWT_AUDIENCE = "recon-ios"

    ACCESS_TOKEN_TTL = timedelta(minutes=10)
    REFRESH_TOKEN_TTL = timedelta(days=30)
    REFRESH_FAMILY_TTL = timedelta(days=90)
    REFRESH_GRACE = timedelta(seconds=10)

    SERVER_PEPPER = None

    RATELIMIT_STORAGE_URI = "memory://"
    RATELIMIT_HEADERS_ENABLED = True

    @classmethod
    def load(cls):
        cls.SQLALCHEMY_DATABASE_URI = _required("DATABASE_URL")
        cls.JWT_SECRET_KEY = _required("JWT_SECRET_KEY")
        cls.JWT_SECRET_KEY_PREVIOUS = os.environ.get("JWT_SECRET_KEY_PREVIOUS") or None
        cls.SERVER_PEPPER = _required("SERVER_PEPPER").encode()
        cls.RATELIMIT_STORAGE_URI = os.environ.get("RATELIMIT_STORAGE_URI", "memory://")
        return cls


class TestConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "TEST_DATABASE_URL", "postgresql+psycopg://recon:recon@localhost:5432/recon_test"
    )
    JWT_SECRET_KEY = "test-key-not-used-anywhere-real"
    JWT_SECRET_KEY_PREVIOUS = None
    SERVER_PEPPER = b"test-pepper"
    RATELIMIT_ENABLED = False

    @classmethod
    def load(cls):
        return cls
