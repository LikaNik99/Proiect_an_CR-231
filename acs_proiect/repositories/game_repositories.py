from sqlalchemy.orm import Session
from models.games import Game

class GameRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_game(self, white_id: int, lobby_id: int):
        game = Game(
            white_player_id=white_id,
            black_player_id=None,
            lobby_id=lobby_id,
            status="waiting"
        )
        self.db.add(game)
        self.db.commit()
        self.db.refresh(game)
        return game

    def create_game_with_black(self, black_id: int, lobby_id: int):
        game = Game(
            white_player_id=None,
            black_player_id=black_id,
            lobby_id=lobby_id,
            status="waiting"
        )
        self.db.add(game)
        self.db.commit()
        self.db.refresh(game)
        return game

    def get_game(self, game_id: int):
        return self.db.query(Game).filter(Game.id == game_id).first()

    def get_game_by_lobby(self, lobby_id: int):
        return self.db.query(Game).filter(Game.lobby_id == lobby_id).first()

    def set_black_player(self, lobby_id: int, player_id: int):
        game = self.get_game_by_lobby(lobby_id)
        if not game:
            return None

        game.black_player_id = player_id
        game.status = "ongoing"

        self.db.commit()
        self.db.refresh(game)
        return game

    def finish_game(self, game_id: int, result: str):
        game = self.get_game(game_id)
        if not game:
            return None

        game.status = "finished"
        game.result = result
        self.db.commit()
        self.db.refresh(game)
        return game
