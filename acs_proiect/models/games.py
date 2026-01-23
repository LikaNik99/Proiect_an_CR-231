from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, String, DateTime, Text
from sqlalchemy.orm import relationship
from core.database import Base

class Game(Base):
    __tablename__ = "games"

    id = Column(Integer, primary_key=True, index=True)

    white_player_id = Column(Integer, ForeignKey("players.id"))
    black_player_id = Column(Integer, ForeignKey("players.id"), nullable=True)

    lobby_id = Column(Integer, ForeignKey("lobby.id"), nullable=True)

    status = Column(String, default="waiting")  # waiting / ongoing / finished
    result = Column(String, nullable=True)
    winner_id = Column(Integer, ForeignKey("players.id"), nullable=True)
    
    moves = Column(Text, nullable=True)  # Salvăm mutările ca string (format PGN sau JSON)

    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime, nullable=True)

    white_player = relationship("Player", foreign_keys=[white_player_id])
    black_player = relationship("Player", foreign_keys=[black_player_id])
    winner = relationship("Player", foreign_keys=[winner_id])

    lobby = relationship("Lobby", back_populates="game")
