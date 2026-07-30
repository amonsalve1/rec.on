def iso(value):
    return value.isoformat().replace("+00:00", "Z") if value else None


def member_dict(member):
    user = member.user
    return {
        "user_id": user.id,
        "username": user.username,
        "display_name": user.profile.display_name if user.profile else user.username,
        "role": member.role,
        "joined_at": iso(member.joined_at),
    }


def party_dict(party, members=None):
    if members is None:
        members = [m for m in party.members if m.status == "active"]
    return {
        "id": party.public_id,
        "title": party.title,
        "topic": party.topic,
        "state": party.state,
        "version": party.version,
        "host_user_id": party.host_user_id,
        "option_count": party.option_count,
        "member_count": party.member_count,
        "submitted_count": party.submitted_count,
        "deadline_at": iso(party.swipe_deadline_at),
        "created_at": iso(party.created_at),
        "members": [member_dict(m) for m in members],
    }


def invite_dict(invite, code=None):
    """`code` is only ever present on the response that mints it.

    We store an HMAC, so the plaintext exists exactly once, in that one
    response body. It cannot be re-read later.
    """
    payload = {
        "expires_at": iso(invite.expires_at),
        "max_uses": invite.max_uses,
        "uses": invite.uses,
    }
    if code:
        payload["code"] = code
    return payload
