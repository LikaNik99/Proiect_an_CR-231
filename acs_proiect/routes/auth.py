#TODO logare si inregistrare
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.database import get_db
from services.player_services import PlayerService
from models.player import Player

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

# =========================
# Înregistrare utilizator
# =========================
@router.post("/register")
def register(username: str, password: str, db: Session = Depends(get_db)):
    service = PlayerService(db)
    try:
        player = service.create_player(username, password)
        return {"message": "User registered successfully", "username": player.username}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


# =========================
# Logare utilizator
# =========================
@router.post("/login")
def login(username: str, password: str, db: Session = Depends(get_db)):
    service = PlayerService(db)
    try:
        player = service.login(username, password)
        return {
            "message": "Login successful",
            "username": player.username,
            "player_id": player.id
        }


    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
