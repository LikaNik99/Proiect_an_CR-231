from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class GameCreate(BaseModel):
    white_id: int
    black_id: int

class GameOut(BaseModel):
    id: int
    white_player_id: int
    black_player_id: int
    status: str
    result: Optional[str]
    started_at: datetime
    ended_at: Optional[datetime]

    class Config:
        orm_mode = True
