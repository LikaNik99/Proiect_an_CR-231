from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class MoveCreate(BaseModel):
    game_id: int
    player_id: int
    move_number: int
    from_pos: str
    to_pos: str
    piece: str
    captured_piece: Optional[str] = None

class MoveOut(MoveCreate):
    id: int
    timestamp: datetime

    class Config:
        orm_mode = True
