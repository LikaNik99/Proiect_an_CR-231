import uuid
from datetime import datetime
from typing import List, Optional, TYPE_CHECKING

from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.functions import func

from config.database import Base

if TYPE_CHECKING:
    from app.classes import Class
    from app.users.models import User


class School(Base):
    __tablename__ = "schools"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True
    )
    name: Mapped[str] = mapped_column(nullable=False, index=True)
    location: Mapped[str] = mapped_column(nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(nullable=True)
    email: Mapped[Optional[str]] = mapped_column(nullable=True, index=True, unique=True)
    established_year: Mapped[Optional[int]] = mapped_column(nullable=True)
    website: Mapped[Optional[str]] = mapped_column(nullable=True)
    logo_url: Mapped[Optional[str]] = mapped_column(nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True)

    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=func.now(), onupdate=func.now()
    )
    classes = relationship("Class", back_populates="school", cascade="all, delete-orphan")
    users = relationship("User", back_populates="school")
