from datetime import timedelta


def test_register_returns_both_tokens(register):
    session = register()
    assert session["access_token"] and session["refresh_token"]
    assert session["expires_in"] == 600
    assert session["user"]["username"] == "toli"


def test_email_and_username_are_case_insensitive(client, register):
    register(username="toli", email="Toli@Example.COM")

    clash = client.post(
        "/v1/auth/register",
        json={"email": "toli@example.com", "username": "different", "password": "longenoughpw1"},
    )
    assert clash.status_code == 409
    assert clash.get_json()["error"]["code"] == "credentials_taken"

    clash = client.post(
        "/v1/auth/register",
        json={"email": "other@example.com", "username": "TOLI", "password": "longenoughpw1"},
    )
    assert clash.status_code == 409


def test_login_does_not_reveal_whether_an_email_exists(client, register):
    register(email="known@example.com")

    wrong_password = client.post(
        "/v1/auth/login", json={"email": "known@example.com", "password": "notitatall"}
    )
    unknown_email = client.post(
        "/v1/auth/login", json={"email": "nobody@example.com", "password": "notitatall"}
    )

    assert wrong_password.status_code == unknown_email.status_code == 401
    assert (
        wrong_password.get_json()["error"]["code"]
        == unknown_email.get_json()["error"]["code"]
        == "invalid_credentials"
    )


def test_short_password_is_rejected(client):
    response = client.post(
        "/v1/auth/register", json={"email": "a@b.com", "username": "ok", "password": "short"}
    )
    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "weak_password"


def test_refresh_rotates_the_token(client, register):
    session = register()
    response = client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})

    assert response.status_code == 200
    assert response.get_json()["refresh_token"] != session["refresh_token"]


def test_concurrent_refresh_inside_grace_does_not_kill_the_family(client, register):
    """Two 401s racing into two refreshes must not sign the user out."""
    session = register()
    first = client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})
    second = client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})

    assert first.status_code == 200
    assert second.status_code == 200
    assert second.get_json()["refresh_token"] != first.get_json()["refresh_token"]


def test_reuse_outside_grace_revokes_the_whole_family(app, client, register):
    session = register()
    rotated = client.post(
        "/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}
    ).get_json()

    app.config["REFRESH_GRACE"] = timedelta(seconds=0)
    try:
        replayed = client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})
        assert replayed.status_code == 401
        assert replayed.get_json()["error"]["code"] == "refresh_reused"

        descendant = client.post("/v1/auth/refresh", json={"refresh_token": rotated["refresh_token"]})
        assert descendant.status_code == 401
    finally:
        app.config["REFRESH_GRACE"] = timedelta(seconds=10)


def test_logout_is_not_reported_as_theft(client, register, auth_header):
    session = register()
    client.post(
        "/v1/auth/logout",
        json={"refresh_token": session["refresh_token"]},
        headers=auth_header(session),
    )

    response = client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})
    assert response.status_code == 401
    assert response.get_json()["error"]["code"] == "invalid_refresh"


def test_me_requires_a_token(client, register, auth_header):
    session = register()

    assert client.get("/v1/auth/me").status_code == 401
    me = client.get("/v1/auth/me", headers=auth_header(session))
    assert me.status_code == 200
    assert me.get_json()["profile"]["friends_count"] is None


def test_errors_are_json_not_html(client):
    response = client.get("/v1/does-not-exist")
    assert response.headers["Content-Type"].startswith("application/json")
    assert response.get_json()["error"]["code"] == "not_found"
