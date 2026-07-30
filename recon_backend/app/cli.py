import click

from .extensions import db
from .models import Party
from .services.access_tokens import utcnow


def register_cli(app):
    @app.cli.command("sweep-expired")
    def sweep_expired():
        """Expire parties whose swipe deadline has passed.

        Covers both lobbies that never started and votes that never finished.
        ix_parties_state_deadline exists for exactly this scan. Run from cron;
        members polling the party see the state flip on their next request.
        """
        now = utcnow()
        count = (
            Party.query.filter(
                Party.state.in_(("lobby", "swiping")),
                Party.swipe_deadline_at.isnot(None),
                Party.swipe_deadline_at <= now,
            ).update(
                {
                    "state": "expired",
                    "closed_at": now,
                    "version": Party.version + 1,
                },
                synchronize_session=False,
            )
        )
        db.session.commit()
        click.echo(f"expired {count} parties")
