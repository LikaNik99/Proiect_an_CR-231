from pydantic import BaseModel
from datetime import datetime

# Pentru creare user (input)
class PlayerCreate(BaseModel):
    username: str
    password: str

# Pentru afișare user (output)
class PlayerRead(BaseModel):
    id: int
    username: str
    rating: int
    created_at: datetime

    class Config:
        orm_mode = True
