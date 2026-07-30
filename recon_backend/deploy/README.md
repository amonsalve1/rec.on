# Deploying the recon api

Target: the existing GCE box (`34.21.78.117`), Docker Compose for the app
and database, nginx on the host terminating TLS. Everything below runs **on
the box** unless noted. Replace `api.recon.example` with the real domain in
every command and in `deploy/nginx.conf`; the same domain goes into
`recon_frontend/Config/Release.xcconfig`.

## 0. One-time: DNS and firewall

- Create an **A record**: `api.recon.example -> 34.21.78.117`. Wait until
  `dig +short api.recon.example` answers with the IP.
- GCE firewall must allow tcp/80 and tcp/443. Port 5000 must NOT be open to
  the world — the compose file binds it to loopback, keep it that way.

## 1. One-time: secrets

`cp .env.example .env` and fill in real values. Non-negotiables:

- `JWT_SECRET_KEY` and `SERVER_PEPPER`: long random strings
  (`openssl rand -hex 32`), never reused from anywhere.
- **`POSTGRES_PASSWORD`: must be set in the shell env / systemd unit that
  runs compose.** The compose file falls back to `recon` if unset — fine on
  a laptop, not on a server.

## 2. One-time: nginx + certificate

```bash
sudo apt install nginx certbot python3-certbot-nginx
sudo mkdir -p /var/www/certbot

# stage 1: http only, so certbot can answer the challenge
sudo cp deploy/nginx.conf /etc/nginx/sites-available/recon
#   (comment out the 443 server block for this first run)
sudo ln -s /etc/nginx/sites-available/recon /etc/nginx/sites-enabled/recon
sudo nginx -t && sudo systemctl reload nginx

sudo certbot certonly --webroot -w /var/www/certbot -d api.recon.example

# stage 2: restore the full config with the 443 block
sudo cp deploy/nginx.conf /etc/nginx/sites-available/recon
sudo nginx -t && sudo systemctl reload nginx

# renewal is automatic; verify the timer exists and a dry run passes
systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

Add a deploy hook so renewals reload nginx:
`sudo sh -c 'echo "systemctl reload nginx" > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh && chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh'`

## 3. Every deploy

```bash
git pull
docker compose up -d --build

# migrations do NOT run on boot — apply them explicitly.
# there are pending revisions the running database has never seen
# (swipes, final picks + winner column).
docker compose run --rm api flask db upgrade

curl -fsS https://api.recon.example/v1/health
```

Rollback: `git checkout <previous tag/commit> && docker compose up -d
--build`. Migrations are additive so far; if one ever needs reverting,
`docker compose run --rm api flask db downgrade -1` before checking out.

## 4. One-time: cron for the party sweeper

Abandoned parties expire via `flask sweep-expired`
(see `app/cli.py`). Every 10 minutes is plenty:

```cron
*/10 * * * * cd /path/to/recon/recon_backend && docker compose run --rm api flask sweep-expired >> /var/log/recon-sweep.log 2>&1
```

## 5. Verify end-to-end

- `curl -fsS https://api.recon.example/v1/health` → `{"status": "ok"}`
- `curl -fsSI http://api.recon.example/v1/health` → `301` to https
- `curl -fsS http://127.0.0.1:5000/v1/health` from the box → works
  (loopback), but `curl http://34.21.78.117:5000/` from anywhere else must
  time out.
- Build the app in Release (base url points at the domain) and run one
  party end-to-end: register, create, invite, swipe, pick, spin.
