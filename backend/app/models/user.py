import re
from datetime import datetime
from typing import Optional

import bcrypt
from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, Integer, String, func, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..extensions import db

BCRYPT_ROUNDS = 12
# bcrypt silently truncates past 72 bytes, so we reject rather than accept a
# password whose tail does nothing.
MAX_PASSWORD_BYTES = 72
MIN_PASSWORD_CHARS = 10
USERNAME_RE = re.compile(r"^[a-zA-Z0-9_.]{3,30}$")


class User(db.Model):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    username: Mapped[str] = mapped_column(String(30), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    token_epoch: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default=text("0")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    profile: Mapped["Profile"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )

    # uniqueness is case-insensitive, but we keep the casing the user typed
    __table_args__ = (
        Index("uq_users_email_lower", text("lower(email)"), unique=True),
        Index("uq_users_username_lower", text("lower(username)"), unique=True),
    )

    @staticmethod
    def normalize_email(value):
        return (value or "").strip().lower()

    def set_password(self, raw):
        self.password_hash = bcrypt.hashpw(
            raw.encode(), bcrypt.gensalt(rounds=BCRYPT_ROUNDS)
        ).decode()

    def check_password(self, raw):
        return bcrypt.checkpw(raw.encode(), self.password_hash.encode())

    def to_dict(self):
        return {"id": self.id, "username": self.username, "email": self.email}


class Profile(db.Model):
    __tablename__ = "profiles"

    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    display_name: Mapped[str] = mapped_column(String(80), nullable=False)
    location_text: Mapped[Optional[str]] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped[User] = relationship(back_populates="profile")

    def to_dict(self):
        return {
            "id": self.user_id,
            "username": self.user.username,
            "name": self.display_name,
            "email": self.user.email,
            "location": self.location_text,
            # friends are still a client-side stub. null, not a fabricated 0.
            "friends_count": None,
        }
