from sqlalchemy.orm import Session
from models.move import Move

class MoveRepository:
    def __init__(self, db: Session):
        self.db = db

    def add_move(
        self,
        game_id: int,
        player_id: int,
        move_number: int,
        from_pos: str,
        to_pos: str,
        piece: str,
        captured_piece: str | None = None,
    ):
        move = Move(
            game_id=game_id,
            player_id=player_id,
            move_number=move_number,
            from_pos=from_pos,
            to_pos=to_pos,
            piece=piece,
            captured_piece=captured_piece,
        )
        self.db.add(move)
        self.db.commit()
        self.db.refresh(move)
        return move

    def list_moves(self, game_id: int):
        return (
            self.db.query(Move)
            .filter(Move.game_id == game_id)
            .order_by(Move.move_number.asc())
            .all()
        )
