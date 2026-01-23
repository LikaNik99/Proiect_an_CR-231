from fastapi import APIRouter, Depends, HTTPException, WebSocket
from sqlalchemy.orm import Session
from core.database import get_db
from repositories.lobby_repositories import LobbyRepository
from repositories.game_repositories import GameRepository

router = APIRouter(prefix="/lobby", tags=["Lobby"])

active_lobby_ws = {}

# ================================
#        CREATE LOBBY + GAME
# ================================

@router.post("/create")
def create_lobby(player_id: int, preferred_color: str = "white", db: Session = Depends(get_db)):
    lobby_repo = LobbyRepository(db)
    game_repo = GameRepository(db)

    # Validăm culoarea preferată
    if preferred_color not in ["white", "black"]:
        preferred_color = "white"  # Default la alb

    # creeăm lobby-ul
    lobby = lobby_repo.create_lobby(player_id)

    # creăm jocul asociat cu lobby-ul cu culoarea preferată
    if preferred_color == "white":
        # Creatorul este alb, black_player_id rămâne null
        game = game_repo.create_game(white_id=player_id, lobby_id=lobby.id)
    else:
        # Creatorul este negru, white_player_id rămâne null
        game = game_repo.create_game_with_black(black_id=player_id, lobby_id=lobby.id)

    return {
        "lobby_id": lobby.id,
        "game_id": game.id,
        "status": lobby.status
    }

# ================================
#        LIST WAITING LOBBIES
# ================================

@router.get("/waiting")
def waiting_list(db: Session = Depends(get_db)):
    repo = LobbyRepository(db)
    game_repo = GameRepository(db)
    
    lobbies = repo.list_waiting()
    result = []
    
    for lobby in lobbies:
        game = game_repo.get_game_by_lobby(lobby.id)
        if game:
            # Determinăm culoarea creatorului
            creator_color = None
            if game.white_player_id:
                creator_color = "white"
            elif game.black_player_id:
                creator_color = "black"
            
            result.append({
                "id": lobby.id,
                "host_id": lobby.host_id,
                "status": lobby.status,
                "creator_color": creator_color,
                "game_id": game.id
            })
        else:
            result.append({
                "id": lobby.id,
                "host_id": lobby.host_id,
                "status": lobby.status,
                "creator_color": None,
                "game_id": None
            })
    print(f'sadasda: {result}')
    return result

# ================================
#          JOIN LOBBY
# ================================

@router.post("/join/{lobby_id}")
async def join_lobby(lobby_id: int, player_id: int, preferred_color: str = None, db: Session = Depends(get_db)):
    lobby_repo = LobbyRepository(db)
    game_repo = GameRepository(db)

    # Obținem jocul pentru a vedea ce culoare este disponibilă
    game = game_repo.get_game_by_lobby(lobby_id)
    if not game:
        raise HTTPException(status_code=500, detail="Game not found for lobby")

    # VERIFICARE CRITICĂ: Jucătorul nu poate să se alăture la propriul joc
    if game.white_player_id == player_id or game.black_player_id == player_id:
        raise HTTPException(status_code=400, detail="Nu te poți alătura la propriul joc!")

    lobby = lobby_repo.join_lobby(lobby_id, player_id)
    if not lobby:
        raise HTTPException(status_code=400, detail="Cannot join lobby")

    # Determinăm culoarea creatorului
    creator_color = None
    if game.white_player_id:
        creator_color = "white"
    elif game.black_player_id:
        creator_color = "black"
    
    # IMPORTANT: Al doilea jucător TREBUIE să ia culoarea opusă
    # Ignorăm preferința dacă conflictă cu creatorul
    if creator_color == "white":
        assigned_color = "black"  # Forțăm negru
    elif creator_color == "black":
        assigned_color = "white"  # Forțăm alb
    else:
        # Nu ar trebui să ajungem aici, dar dacă da, folosīm preferința sau default
        assigned_color = preferred_color if preferred_color in ["white", "black"] else "white"

    # Completăm jocul cu culoarea alocată
    print(f"[DEBUG] Join lobby {lobby_id}:")
    print(f"  Player ID: {player_id}")
    print(f"  Preferred color: {preferred_color}")
    print(f"  Creator color: {creator_color}")
    print(f"  Assigned color: {assigned_color}")
    print(f"  Current white_player_id: {game.white_player_id}")
    print(f"  Current black_player_id: {game.black_player_id}")
    
    if assigned_color == "white":
        if game.white_player_id is not None:
            raise HTTPException(status_code=400, detail="Poziția pentru alb este deja ocupată")
        game.white_player_id = player_id
        print(f"  ✅ Setat white_player_id = {player_id}")
    elif assigned_color == "black":
        if game.black_player_id is not None:
            raise HTTPException(status_code=400, detail="Poziția pentru negru este deja ocupată")
        game.black_player_id = player_id
        print(f"  ✅ Setat black_player_id = {player_id}")
    
    game.status = "ongoing"
    db.commit()
    db.refresh(game)
    
    print(f"[DEBUG] După commit:")
    print(f"  White player ID: {game.white_player_id}")
    print(f"  Black player ID: {game.black_player_id}")

    await notify_lobby(lobby_id, "opponent_joined")

    return {"lobby_id": lobby_id, "game_id": game.id, "status": "full", "assigned_color": assigned_color}

# ================================
#       GET GAME INFO
# ================================

@router.get("/game/{game_id}")
def get_game_info(game_id: int, db: Session = Depends(get_db)):
    game_repo = GameRepository(db)
    game = game_repo.get_game(game_id)
    
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    
    # Log pentru debugging
    print(f"[DEBUG] Game {game_id} info:")
    print(f"  White player ID: {game.white_player_id} (type: {type(game.white_player_id)})")
    print(f"  Black player ID: {game.black_player_id} (type: {type(game.black_player_id)})")
    print(f"  Status: {game.status}")
    
    return {
        "id": game.id,
        "white_player_id": game.white_player_id,
        "black_player_id": game.black_player_id,
        "status": game.status,
        "result": game.result,
        "started_at": game.started_at,
        "ended_at": game.ended_at
    }

@router.get("/game/{game_id}/state")
def get_game_state(game_id: int, db: Session = Depends(get_db)):
    """Endpoint pentru a obține starea completă a jocului (mutări, FEN, etc.)"""
    game_repo = GameRepository(db)
    game = game_repo.get_game(game_id)
    
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    
    # Reconstruim FEN-ul din mutări
    import chess
    board = chess.Board()
    moves_list = []
    
    if game.moves:
        moves_list = game.moves.split()
        for move_san in moves_list:
            try:
                board.push_san(move_san)
            except Exception as e:
                print(f"[ERROR] Eroare la aplicare mutare {move_san}: {e}")
                break
    
    return {
        "id": game.id,
        "white_player_id": game.white_player_id,
        "black_player_id": game.black_player_id,
        "status": game.status,
        "result": game.result,
        "moves": moves_list,
        "fen": board.fen(),
        "turn": "white" if board.turn == chess.WHITE else "black",
        "is_checkmate": board.is_checkmate(),
        "is_stalemate": board.is_stalemate(),
        "is_check": board.is_check(),
        "started_at": game.started_at,
        "ended_at": game.ended_at
    }

# ================================
#          WEBSOCKET LOBBY
# ================================

@router.websocket("/ws/{lobby_id}")
async def lobby_ws(websocket: WebSocket, lobby_id: int):
    await websocket.accept()

    if lobby_id not in active_lobby_ws:
        active_lobby_ws[lobby_id] = []

    active_lobby_ws[lobby_id].append(websocket)

    try:
        while True:
            await websocket.receive_text()
    except:
        active_lobby_ws[lobby_id].remove(websocket)

# ================================
#       SEND WS MESSAGE
# ================================

async def notify_lobby(lobby_id: int, message: str):
    if lobby_id in active_lobby_ws:
        for ws in active_lobby_ws[lobby_id]:
            try:
                await ws.send_text(message)
            except:
                pass
