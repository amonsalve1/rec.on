"""Seed a bench database with realistic vote volume.

Usage (env must point DATABASE_URL at a throwaway database):

    python scripts/seed_bench.py [parties] [members] [options]

Bulk-inserts users, parties, options, swipes, and picks directly through the
models (the API would take tens of thousands of requests to build the same
volume), then prints an access token and the public id of one fully-voted
"hot" party to aim the load generator at.
"""

import random
import sys

sys.path.insert(0, ".")

from app import create_app  # noqa: E402
from app.extensions import db  # noqa: E402
from app.models import FinalPick, Option, Party, PartyMember, Profile, Swipe, User  # noqa: E402
from app.services import access_tokens  # noqa: E402

PARTIES = int(sys.argv[1]) if len(sys.argv) > 1 else 200
MEMBERS = int(sys.argv[2]) if len(sys.argv) > 2 else 10
OPTIONS = int(sys.argv[3]) if len(sys.argv) > 3 else 15

rng = random.Random(1998)


def main():
    app = create_app()
    with app.app_context():
        db.drop_all()
        db.create_all()

        users = []
        for i in range(PARTIES * MEMBERS):
            user = User(email=f"bench{i}@example.com", username=f"bench{i}")
            user.password_hash = "x"  # never logged in via password
            users.append(user)
        db.session.add_all(users)
        db.session.flush()
        db.session.add_all(
            Profile(user_id=u.id, display_name=u.username) for u in users
        )

        hot_party_public_id = None
        hot_user = None

        for p in range(PARTIES):
            members = users[p * MEMBERS:(p + 1) * MEMBERS]
            party = Party(
                title=f"Bench {p}",
                topic="restaurant",
                host_user_id=members[0].id,
                state="swiping",
                member_count=MEMBERS,
                option_count=OPTIONS,
                submitted_count=MEMBERS,
            )
            db.session.add(party)
            db.session.flush()

            db.session.add_all(
                PartyMember(
                    party_id=party.id,
                    user_id=m.id,
                    role="host" if i == 0 else "member",
                )
                for i, m in enumerate(members)
            )

            options = [
                Option(
                    party_id=party.id,
                    position=i,
                    name=f"Option {i}",
                    tags=["bench"],
                    provider="seed",
                )
                for i in range(OPTIONS)
            ]
            db.session.add_all(options)
            db.session.flush()

            db.session.bulk_insert_mappings(
                Swipe,
                [
                    {
                        "party_id": party.id,
                        "option_id": option.id,
                        "user_id": member.id,
                        "liked": rng.random() < 0.4,
                    }
                    for member in members
                    for option in options
                ],
            )
            db.session.bulk_insert_mappings(
                FinalPick,
                [
                    {
                        "party_id": party.id,
                        "user_id": member.id,
                        "option_id": rng.choice(options).id,
                    }
                    for member in members
                ],
            )

            if p == PARTIES // 2:
                hot_party_public_id = party.public_id
                hot_user = members[0]

        db.session.commit()

        token, _ = access_tokens.issue(hot_user)
        print(f"swipe rows: {PARTIES * MEMBERS * OPTIONS}")
        print(f"party: {hot_party_public_id}")
        print(f"token: {token}")


if __name__ == "__main__":
    main()
