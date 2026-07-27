# Rec.On backend

Flask + Postgres. Replaces the earlier `rec.on` stub, which no longer starts
(it imports `jwt_refresh_token_required`, removed in Flask-JWT-Extended 4.0,
and calls a `generate_default_options` that was never written).

## Running it

Needs Postgres on :5432. Either `docker compose up db`, or locally:

    brew install postgresql@16 && brew services start postgresql@16
    createuser -s recon && createdb -O recon recon && createdb -O recon recon_test

Then:

    python3 -m venv venv
    ./venv/bin/pip install -r requirements.txt
    cp .env.example .env          # then fill in the secrets

Generate the two secrets with:

    python3 -c "import secrets; print(secrets.token_urlsafe(64))"

Apply migrations and start:

    FLASK_APP=wsgi:app ./venv/bin/flask db upgrade
    FLASK_APP=wsgi:app ./venv/bin/flask run --port 5000

Or the whole stack: `docker compose up --build`.

## Tests

    ./venv/bin/pytest

Uses `recon_test`, truncating between tests.

## Notes

`.env` is gitignored and must stay that way. The previous backend committed
its signing key, so anyone could mint a token for any user; treat that value
as public forever and never reuse it.

Rotating `JWT_SECRET_KEY`: put the old value in `JWT_SECRET_KEY_PREVIOUS`,
deploy, wait 10 minutes for outstanding access tokens to expire, then clear
it. No one gets signed out.
