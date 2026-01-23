from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from core.database import get_db
from models.games import Game
from models.player import Player

router = APIRouter(prefix="/games", tags=["Games"])


@router.get("/{game_id}")
def get_game_details(game_id: int, db: Session = Depends(get_db)):
    """Obține detaliile unui joc pentru replay"""
    game = db.query(Game).filter(Game.id == game_id).first()
    
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    
    # Obținem numele jucătorilor
    white_player = db.query(Player).filter(Player.id == game.white_player_id).first()
    black_player = db.query(Player).filter(Player.id == game.black_player_id).first()
    
    return {
        "id": game.id,
        "white_player": white_player.username if white_player else "Unknown",
        "black_player": black_player.username if black_player else "Unknown",
        "white_player_id": game.white_player_id,
        "black_player_id": game.black_player_id,
        "status": game.status,
        "result": game.result,
        "moves": game.moves,
        "started_at": game.started_at,
        "ended_at": game.ended_at
    }
