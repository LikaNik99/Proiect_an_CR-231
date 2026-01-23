from repositories.game_repository import GameRepository
from repositories.move_repository import MoveRepository
from sqlalchemy.orm import Session

class GameService:
    def __init__(self, db: Session):
        self.games = GameRepository(db)
        self.moves = MoveRepository(db)

    def start_game(self, white_id: int, black_id: int):
        return self.games.create_game(white_id, black_id)

    def add_move(self, data):
        return self.moves.add_move(
            game_id=data.game_id,
            player_id=data.player_id,
            move_number=data.move_number,
            from_pos=data.from_pos,
            to_pos=data.to_pos,
            piece=data.piece,
            captured_piece=data.captured_piece,
        )

    def get_game(self, game_id: int):
        return self.games.get_game(game_id)

    def get_moves(self, game_id: int):
        return self.moves.list_moves(game_id)

    def end_game(self, game_id: int, result: str):
        return self.games.finish_game(game_id, result)
