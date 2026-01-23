from sqlalchemy.orm import Session
from models.lobby import Lobby

class LobbyRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_lobby(self, host_id: int):
        lobby = Lobby(host_id=host_id, status="waiting")
        self.db.add(lobby)
        self.db.commit()
        self.db.refresh(lobby)
        return lobby

    def list_waiting(self):
        return self.db.query(Lobby).filter(Lobby.status == "waiting").all()

    def join_lobby(self, lobby_id: int, guest_id: int):
        lobby = self.db.query(Lobby).filter(Lobby.id == lobby_id).first()
        if not lobby:
            return None
        if lobby.guest_id:
            return None

        lobby.guest_id = guest_id
        lobby.status = "full"

        self.db.commit()
        self.db.refresh(lobby)
        return lobby
