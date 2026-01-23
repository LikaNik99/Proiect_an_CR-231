from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from core.database import get_db
from models.player import Player
from models.games import Game

router = APIRouter(prefix="/players", tags=["Players"])


@router.get("/{player_id}")
def get_player_profile(player_id: int, db: Session = Depends(get_db)):
    """Obține profilul jucătorului"""
    player = db.query(Player).filter(Player.id == player_id).first()
    
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    # Calculăm statistici
    games_as_white = db.query(Game).filter(
        Game.white_player_id == player_id,
        Game.status == "completed"
    ).all()
    
    games_as_black = db.query(Game).filter(
        Game.black_player_id == player_id,
        Game.status == "completed"
    ).all()
    
    all_games = games_as_white + games_as_black
    games_played = len(all_games)
    
    games_won = 0
    games_lost = 0
    games_draw = 0
    
    for game in all_games:
        if not game.result:
            continue
            
        is_white = game.white_player_id == player_id
        
        if "Remiză" in game.result or "Draw" in game.result:
            games_draw += 1
        elif ("Alb câștigă" in game.result or "White wins" in game.result):
            if is_white:
                games_won += 1
            else:
                games_lost += 1
        elif ("Negru câștigă" in game.result or "Black wins" in game.result):
            if not is_white:
                games_won += 1
            else:
                games_lost += 1
    
    return {
        "id": player.id,
        "username": player.username,
        "created_at": player.created_at,
        "games_played": games_played,
        "games_won": games_won,
        "games_lost": games_lost,
        "games_draw": games_draw,
        "rating": 1200  # Placeholder - poți implementa sistem de rating
    }


@router.get("/{player_id}/games")
def get_player_game_history(player_id: int, db: Session = Depends(get_db)):
    """Obține istoricul jocurilor pentru un jucător"""
    player = db.query(Player).filter(Player.id == player_id).first()
    
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")
    
    # Găsim toate jocurile în care a participat
    games = db.query(Game).filter(
        (Game.white_player_id == player_id) | (Game.black_player_id == player_id)
    ).order_by(Game.started_at.desc()).all()
    
    result = []
    for game in games:
        result.append({
            "id": game.id,
            "white_player_id": game.white_player_id,
            "black_player_id": game.black_player_id,
            "status": game.status,
            "result": game.result,
            "moves": game.moves,  # Adăugăm mutările
            "started_at": game.started_at,
            "ended_at": game.ended_at
        })
    
    return result
