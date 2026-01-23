from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, List
import threading
import time
import asyncio
import chess
from sqlalchemy.orm import Session
from core.database import get_db
from models.games import Game as GameModel

router = APIRouter(prefix="/ws", tags=["WebSocket"])

active_connections: Dict[int, List[WebSocket]] = {}
active_games = {}


class Game:
    def __init__(self, game_id: int, fen: str = None, moves: list = None, white_time: int = 600, black_time: int = 600):
        self.id = game_id
        self.board = chess.Board(fen) if fen else chess.Board()  # Starea jocului de șah
        self.white_time = white_time  # 10 minute
        self.black_time = black_time
        self.turn = "white" if self.board.turn == chess.WHITE else "black"
        self.running = True
        self.lock = threading.Lock()
        self.moves = moves if moves else []  # Lista de mutări în format SAN
        self.last_saved = time.time()

    def switch_turn(self):
        self.turn = "black" if self.turn == "white" else "white"
    
    def add_move(self, move_san: str):
        """Adaugă o mutare în listă"""
        self.moves.append(move_san)
    
    def should_save(self):
        """Verifică dacă trebuie să salvăm starea (la fiecare 5 secunde)"""
        return time.time() - self.last_saved > 5


def timer_thread(game_id: int):
    game = active_games[game_id]

    while game.running:
        time.sleep(1)
        with game.lock:
            if game.turn == "white":
                game.white_time -= 1
            else:
                game.black_time -= 1

            # Salvăm periodic starea jocului
            if game.should_save():
                save_game_state(game_id, game)
                game.last_saved = time.time()

            ws_list = active_connections.get(game_id, [])

            # trimite doar dacă mai există conexiuni
            if not ws_list:
                continue

            # O singură buclă asyncio pentru toate ws
            async def broadcast_timer():
                for ws in ws_list:
                    try:
                        await ws.send_json({
                            "type": "timer_update",
                            "white_time": game.white_time,
                            "black_time": game.black_time,
                            "turn": game.turn
                        })
                    except Exception:
                        pass

            asyncio.run(broadcast_timer())

            if game.white_time <= 0 or game.black_time <= 0:
                game.running = False
                winner_color = "black" if game.white_time <= 0 else "white"
                result = f"{'Negru' if winner_color == 'black' else 'Alb'} câștigă (timp)"
                
                # Actualizăm baza de date
                update_game_result(game_id, result, winner_color, game.moves)

                async def broadcast_game_over():
                    for ws in ws_list:
                        try:
                            await ws.send_json({
                                "type": "game_over",
                                "result": result,
                                "reason": "time"
                            })
                        except Exception:
                            pass

                asyncio.run(broadcast_game_over())
                break


async def notify_game_ready(game_id: int):
    """Notifică toți jucătorii conectați că jocul e gata să înceapă"""
    if game_id in active_connections:
        for ws in active_connections[game_id]:
            try:
                await ws.send_json({
                    "type": "game_ready",
                    "message": "Ambii jucători sunt pregătiți!"
                })
            except Exception as e:
                print(f"Eroare la trimitere game_ready: {e}")


def save_game_state(game_id: int, game: Game):
    """Salvează starea curentă a jocului în baza de date"""
    from core.database import SessionLocal
    db = SessionLocal()
    try:
        game_record = db.query(GameModel).filter(GameModel.id == game_id).first()
        if game_record:
            # Salvăm mutările și starea curentă
            game_record.moves = " ".join(game.moves) if game.moves else ""
            # Putem salva și timpul rămas (în viitor, adăugând coloane noi)
            db.commit()
    except Exception as e:
        print(f"[DB] Eroare la salvare stare: {e}")
        db.rollback()
    finally:
        db.close()

def update_game_result(game_id: int, result: str, winner_color: str = None, moves_list: list = None):
    """Actualizează statusul jocului în baza de date"""
    from core.database import SessionLocal
    from datetime import datetime
    db = SessionLocal()
    try:
        game_record = db.query(GameModel).filter(GameModel.id == game_id).first()
        if game_record:
            game_record.status = "completed"
            game_record.result = result
            game_record.ended_at = datetime.utcnow()
            
            # Setăm winner_id dacă avem câștigător
            if winner_color == "white":
                game_record.winner_id = game_record.white_player_id
            elif winner_color == "black":
                game_record.winner_id = game_record.black_player_id
            # Dacă e draw/remiză, winner_id rămâne None
            
            # Salvăm mutările ca string (format: "e4 e5 Nf3 Nc6...")
            if moves_list:
                game_record.moves = " ".join(moves_list)
            
            db.commit()
            print(f"[DB] Jocul {game_id} marcat ca finalizat: {result}")
    except Exception as e:
        print(f"[DB] Eroare la actualizare joc: {e}")
        db.rollback()
    finally:
        db.close()



@router.websocket("/game/{game_id}")
async def websocket_endpoint(websocket: WebSocket, game_id: int):
    await websocket.accept()

    if game_id not in active_connections:
        active_connections[game_id] = []
        
        # Încercăm să restaurăm starea jocului din baza de date
        from core.database import SessionLocal
        db = SessionLocal()
        try:
            game_record = db.query(GameModel).filter(GameModel.id == game_id).first()
            if game_record and game_record.moves:
                # Reconstruim jocul din mutări
                moves_list = game_record.moves.split() if game_record.moves else []
                board = chess.Board()
                for move_san in moves_list:
                    try:
                        board.push_san(move_san)
                    except:
                        print(f"[DB] Eroare la aplicare mutare: {move_san}")
                        break
                
                active_games[game_id] = Game(
                    game_id,
                    fen=board.fen(),
                    moves=moves_list,
                    white_time=600,  # În viitor, putem salva și timpii
                    black_time=600
                )
                print(f"[DB] Joc {game_id} restaurat cu {len(moves_list)} mutări")
            else:
                active_games[game_id] = Game(game_id)
                print(f"[DB] Joc nou creat pentru {game_id}")
        finally:
            db.close()

        t = threading.Thread(target=timer_thread, args=(game_id,), daemon=True)
        t.start()

    active_connections[game_id].append(websocket)
    game = active_games[game_id]
    
    print(f"[WS] Jucător conectat la game {game_id}. Total conexiuni: {len(active_connections[game_id])}")
    
    # Trimitem starea curentă jucătorului care tocmai s-a conectat (pentru sincronizare după refresh)
    try:
        await websocket.send_json({
            "type": "game_state",
            "fen": game.board.fen(),
            "moves": game.moves,
            "white_time": game.white_time,
            "black_time": game.black_time,
            "turn": game.turn
        })
        print(f"[WS] Stare trimisă la client: {game.board.fen()}")
    except Exception as e:
        print(f"[WS] Eroare la trimitere stare: {e}")

    # Dacă avem 2 jucători conectați, notificăm că jocul poate începe
    if len(active_connections[game_id]) >= 2:
        await notify_game_ready(game_id)
        print(f"[WS] Jocul {game_id} e gata să înceapă!")

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            # Resign / Abandon
            if msg_type == "resign":
                player_username = data.get("player")
                player_id = data.get("player_id")
                player_color = data.get("player_color")
                
                print(f"[SERVER] Cerere de resign de la {player_username} (ID: {player_id}, culoare: {player_color})")
                
                # VALIDARE: Verificăm că jucătorul este în acest joc
                from core.database import SessionLocal
                db = SessionLocal()
                try:
                    game_record = db.query(GameModel).filter(GameModel.id == game_id).first()
                    if not game_record:
                        print(f"[SERVER] Jocul {game_id} nu există")
                        continue
                    
                    # Verificăm că player_id este într-adevăr în joc
                    if player_id not in [game_record.white_player_id, game_record.black_player_id]:
                        print(f"[SERVER] UNAUTHORIZED: Player {player_id} nu este în acest joc!")
                        await websocket.send_json({
                            "type": "error",
                            "message": "Nu ești înscris în acest joc!"
                        })
                        continue
                    
                    # Determinăm culoarea corectă bazat pe player_id
                    actual_color = None
                    if game_record.white_player_id == player_id:
                        actual_color = "white"
                    elif game_record.black_player_id == player_id:
                        actual_color = "black"
                    
                    print(f"[SERVER] ✅ Resign validat pentru {actual_color}")
                    
                finally:
                    db.close()
                
                # Determinăm câștigătorul (adversarul)
                winner_color = "black" if actual_color == "white" else "white"
                result = f"{'Negru' if winner_color == 'black' else 'Alb'} câștigă (abandon)"
                
                # Actualizăm baza de date cu mutările până la abandon
                update_game_result(game_id, result, winner_color, game.moves)
                
                # Notificăm AMBII jucători
                for conn in active_connections[game_id]:
                    try:
                        await conn.send_json({
                            "type": "game_over",
                            "result": result,
                            "reason": "resign",
                            "resigned_player": actual_color
                        })
                    except Exception as e:
                        print(f"Eroare la trimitere resign: {e}")
                
                # Oprim jocul
                game.running = False
                continue

            # Mutare de șah
            if msg_type == "move":
                from_sq = data.get("from")
                to_sq = data.get("to")
                player = data.get("player")
                player_id = data.get("player_id")  # ID-ul jucătorului care face mutarea
                fen_before = data.get("fen")  # Starea board-ului înainte de mutare
                
                print(f"[SERVER] Mutare primită: {from_sq} -> {to_sq} de la {player} (ID: {player_id})")
                if fen_before:
                    print(f"[SERVER] FEN primit: {fen_before}")

                # VALIDARE CRITICĂ DE SECURITATE: Verificăm că jucătorul este autorizat să mute
                from core.database import SessionLocal
                db = SessionLocal()
                try:
                    game_record = db.query(GameModel).filter(GameModel.id == game_id).first()
                    if not game_record:
                        await websocket.send_json({
                            "type": "move_error",
                            "message": "Jocul nu a fost găsit"
                        })
                        continue
                    
                    # Determinăm culoarea jucătorului bazat pe player_id
                    player_color = None
                    if game_record.white_player_id == player_id:
                        player_color = "white"
                    elif game_record.black_player_id == player_id:
                        player_color = "black"
                    else:
                        print(f"[SERVER] UNAUTHORIZED: Player {player_id} nu este în acest joc!")
                        await websocket.send_json({
                            "type": "move_error",
                            "message": "Nu ești înscris în acest joc!"
                        })
                        continue
                    
                    # Verificăm dacă este rândul acestui jucător
                    current_turn = "white" if game.board.turn == chess.WHITE else "black"
                    if player_color != current_turn:
                        print(f"[SERVER] UNAUTHORIZED: Nu este rândul lui {player_color} (rândul este: {current_turn})")
                        await websocket.send_json({
                            "type": "move_error",
                            "message": "Nu este rândul tău!"
                        })
                        continue
                    
                    print(f"[SERVER] ✅ Validare: {player} ({player_color}) are voie să mute")
                    
                finally:
                    db.close()

                # Validăm mutarea pe server
                try:
                    with game.lock:
                        # Sincronizăm board-ul cu starea de la client
                        if fen_before:
                            try:
                                game.board.set_fen(fen_before)
                                print(f"[SERVER] Board sincronizat cu FEN-ul clientului")
                            except Exception as e:
                                print(f"[SERVER] Eroare la setare FEN: {e}")
                        
                        # Verificăm dacă mutarea este validă
                        move_uci = f"{from_sq}{to_sq}"
                        move = None
                        
                        # Obținem lista de mutări legale
                        legal_moves_list = list(game.board.legal_moves)
                        print(f"[SERVER] Mutări legale disponibile: {len(legal_moves_list)}")
                        
                        # Verificăm dacă mutarea este legală (fără promovare)
                        try:
                            test_move = chess.Move.from_uci(move_uci)
                            if test_move in legal_moves_list:
                                move = test_move
                                print(f"[SERVER] Mutare validă fără promovare: {move_uci}")
                        except Exception as e:
                            print(f"[SERVER] Eroare la testare mutare fără promovare: {e}")
                        
                        # Dacă nu e validă, încercăm cu promovare
                        if move is None:
                            try:
                                test_move = chess.Move.from_uci(f"{move_uci}q")
                                if test_move in legal_moves_list:
                                    move = test_move
                                    print(f"[SERVER] Mutare validă cu promovare: {move_uci}q")
                            except Exception as e:
                                print(f"[SERVER] Eroare la testare mutare cu promovare: {e}")
                        
                        # Dacă încă nu e validă, mutarea e invalidă
                        if move is None:
                            print(f"[SERVER] Mutare invalidă: {move_uci}")
                            await websocket.send_json({
                                "type": "move_error",
                                "message": "Mutare invalidă"
                            })
                            continue
                        
                        # Salvăm mutarea în format SAN ÎNAINTE de a o aplica (san() trebuie apelat înainte de push)
                        move_san = game.board.san(move)
                        game.add_move(move_san)
                        
                        # Aplicăm mutarea pe board-ul serverului
                        game.board.push(move)
                        
                        # Salvăm imediat starea în baza de date după fiecare mutare
                        save_game_state(game_id, game)
                        
                        print(f"[SERVER] Mutare aplicată: {move_san}. FEN nou: {game.board.fen()}")
                        
                        # Actualizăm turnul
                        game.switch_turn()
                        
                        # Verificăm dacă jocul s-a terminat
                        result = None
                        winner_color = None
                        reason = None
                        
                        if game.board.is_checkmate():
                            game.running = False
                            winner_color = "white" if game.turn == "black" else "black"
                            result = f"{'Alb' if winner_color == 'white' else 'Negru'} câștigă (mat)"
                            reason = "checkmate"
                            update_game_result(game_id, result, winner_color, game.moves)
                        elif game.board.is_stalemate():
                            game.running = False
                            result = "Remiză (pat)"
                            reason = "stalemate"
                            update_game_result(game_id, result, None, game.moves)
                        elif game.board.is_insufficient_material():
                            game.running = False
                            result = "Remiză (material insuficient)"
                            reason = "insufficient_material"
                            update_game_result(game_id, result, None, game.moves)
                        elif game.board.is_seventyfive_moves():
                            game.running = False
                            result = "Remiză (regula celor 75 de mutări)"
                            reason = "75_moves"
                            update_game_result(game_id, result, None, game.moves)
                        elif game.board.is_fivefold_repetition():
                            game.running = False
                            result = "Remiză (repetare poziție de 5 ori)"
                            reason = "fivefold_repetition"
                            update_game_result(game_id, result, None, game.moves)
                        elif game.board.can_claim_draw():
                            # Verificăm dacă poate fi revendicate remiză (50 mutări sau 3x repetare)
                            if game.board.can_claim_fifty_moves():
                                game.running = False
                                result = "Remiză (regula celor 50 de mutări)"
                                reason = "50_moves"
                                update_game_result(game_id, result, None, game.moves)
                            elif game.board.can_claim_threefold_repetition():
                                game.running = False
                                result = "Remiză (repetare poziție de 3 ori)"
                                reason = "threefold_repetition"
                                update_game_result(game_id, result, None, game.moves)
                        
                except Exception as e:
                    # Eroare la validare - trimitem eroare
                    print(f"[SERVER] Eroare la validare mutare: {e}")
                    import traceback
                    traceback.print_exc()
                    await websocket.send_json({
                        "type": "move_error",
                        "message": f"Eroare: {str(e)}"
                    })
                    continue

                # construim mesajul COMPLET
                message = {
                    "type": "move",
                    "from": from_sq,
                    "to": to_sq,
                    "player": player,
                    "fen": game.board.fen()  # Trimitem și starea completă pentru sincronizare
                }
                
                print(f"[SERVER] Trimit mutare tuturor jucătorilor: {len(active_connections[game_id])} conexiuni")
                # trimitem mutarea tuturor jucătorilor (inclusiv celui care a făcut mutarea pentru consistență)
                for conn in active_connections[game_id]:
                    try:
                        await conn.send_json(message)
                        print(f"[SERVER] Mesaj trimis către conexiune")
                    except Exception as e:
                        print(f"[SERVER] Eroare la trimitere mesaj: {e}")
                
                # Dacă jocul s-a terminat, trimitem mesaj separat de game_over
                if result:
                    game_over_message = {
                        "type": "game_over",
                        "result": result,
                        "reason": reason,
                        "winner": winner_color
                    }
                    for conn in active_connections[game_id]:
                        try:
                            await conn.send_json(game_over_message)
                        except Exception as e:
                            print(f"[SERVER] Eroare la trimitere game_over: {e}")


            # Chat
            elif msg_type == "chat":
                for conn in active_connections[game_id]:
                    if conn != websocket:
                        await conn.send_json(data)

    except WebSocketDisconnect:
        active_connections[game_id].remove(websocket)
        if not active_connections[game_id]:
            del active_connections[game_id]
            del active_games[game_id]
