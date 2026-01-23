from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from core.database import Base

class Player(Base):
    __tablename__ = 'players'
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)  # stocăm hash-ul
    rating = Column(Integer, default=1200)
    created_at = Column(DateTime, default=datetime.utcnow)
