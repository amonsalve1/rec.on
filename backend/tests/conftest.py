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


@pytest.fixture
def host(register, auth_header):
    session = register(username="toli")
    return auth_header(session)


@pytest.fixture
def guest(register, auth_header):
    session = register(username="mei")
    return auth_header(session)


@pytest.fixture
def party(client, host):
    response = client.post(
        "/v1/parties",
        json={"title": "Dinner", "topic": "restaurant", "location": {"lat": 42.4534891, "lon": -76.4735249}},
        headers=host,
    )
    assert response.status_code == 201, response.get_json()
    return response.get_json()["party"]


def invite_code(client, host, party):
    response = client.post(f"/v1/parties/{party['id']}/invite", headers=host)
    assert response.status_code == 201, response.get_json()
    return response.get_json()["invite"]["code"]
