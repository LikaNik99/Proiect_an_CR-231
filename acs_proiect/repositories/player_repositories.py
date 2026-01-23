from sqlalchemy.orm import Session
from models.player import Player

class PlayerRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_player(self, username: str, password_hash: str) -> Player:
        db_player = Player(
            username=username,
            password_hash=password_hash,
            rating=1200  # default rating
        )
        self.db.add(db_player)
        self.db.commit()
        self.db.refresh(db_player)
        return db_player

    def get_players(self):
        return self.db.query(Player).all()

    def get_by_username(self, username: str):
        return self.db.query(Player).filter(Player.username == username).first()
