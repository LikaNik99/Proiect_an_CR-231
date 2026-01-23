from sqlalchemy import Column, Integer, ForeignKey, String
from sqlalchemy.orm import relationship
from core.database import Base

class Lobby(Base):
    __tablename__ = "lobby"

    id = Column(Integer, primary_key=True, index=True)
    host_id = Column(Integer, ForeignKey("players.id"))
    guest_id = Column(Integer, ForeignKey("players.id"), nullable=True)
    status = Column(String, default="waiting")

    host = relationship("Player", foreign_keys=[host_id])
    guest = relationship("Player", foreign_keys=[guest_id])

    game = relationship("Game", back_populates="lobby", uselist=False)
