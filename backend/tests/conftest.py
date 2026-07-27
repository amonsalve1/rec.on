import pytest

from app import create_app
from app.config import TestConfig
from app.extensions import db as _db


@pytest.fixture(scope="session")
def app():
    application = create_app(TestConfig)
    with application.app_context():
        _db.drop_all()
        _db.create_all()
        yield application
        _db.session.remove()
        _db.drop_all()


@pytest.fixture(autouse=True)
def clean_tables(app):
    yield
    _db.session.rollback()
    for table in reversed(_db.metadata.sorted_tables):
        _db.session.execute(table.delete())
    _db.session.commit()


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def register(client):
    """Create a user and hand back their tokens."""

    def _register(username="toli", email=None, password="correcthorsebattery"):
        response = client.post(
            "/v1/auth/register",
            json={
                "email": email or f"{username}@example.com",
                "username": username,
                "password": password,
            },
        )
        assert response.status_code == 201, response.get_json()
        return response.get_json()

    return _register


@pytest.fixture
def auth_header():
    def _header(session):
        return {"Authorization": f"Bearer {session['access_token']}"}

    return _header
