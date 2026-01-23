from datetime import datetime

from sqlalchemy import Column, Integer, ForeignKey, String, DateTime
from sqlalchemy.orm import relationship

from core.database import Base


class Move(Base):
    __tablename__ = "moves"
    id = Column(Integer, primary_key=True, index=True)
    game_id = Column(Integer, ForeignKey("games.id"))
    player_id = Column(Integer, ForeignKey("players.id"))
    move_number = Column(Integer)
    from_pos = Column(String, nullable=False)   # ex: "e2"
    to_pos = Column(String, nullable=False)     # ex: "e4"
    piece = Column(String, nullable=False)      # "P", "N", "B", "R", "Q", "K"
    captured_piece = Column(String, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
