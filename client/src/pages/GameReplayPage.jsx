import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Chess } from "chess.js";
import { Chessboard } from "react-chessboard";
import Navbar from "../components/Navbar";
import "../style/GameReplayPage.css";

function GameReplayPage() {
    const { gameId } = useParams();
    const navigate = useNavigate();
    
    const [game] = useState(new Chess());
    const [currentPosition, setCurrentPosition] = useState(game.fen());
    const [moves, setMoves] = useState([]);
    const [currentMoveIndex, setCurrentMoveIndex] = useState(-1);
    const [gameInfo, setGameInfo] = useState(null);
    const [loading, setLoading] = useState(true);
    const [isOffline, setIsOffline] = useState(false);

    useEffect(() => {
        const fetchGameDetails = async () => {
            try {
                const host = window.location.hostname;
                const response = await fetch(`http://${host}:8000/games/${gameId}`, {
                    signal: AbortSignal.timeout(3000)
                });
                
                if (response.ok) {
                    const data = await response.json();
                    setGameInfo(data);
                    
                    // Salvăm în cache pentru offline
                    localStorage.setItem(`cached_game_details_${gameId}`, JSON.stringify(data));
                    
                    // Parseză mutările
                    if (data.moves) {
                        const movesArray = data.moves.trim().split(" ");
                        setMoves(movesArray);
                    }
                    setIsOffline(false);
                } else {
                    throw new Error("Server error");
                }
            } catch (error) {
                console.error("Eroare la încărcare joc:", error);
                
                // Încercăm să încărcăm din cache
                const cached = localStorage.getItem(`cached_game_details_${gameId}`);
                if (cached) {
                    const data = JSON.parse(cached);
                    setGameInfo(data);
                    
                    if (data.moves) {
                        const movesArray = data.moves.trim().split(" ");
                        setMoves(movesArray);
                    }
                    setIsOffline(true);
                } else {
                    alert("Jocul nu a fost găsit în cache. Trebuie să fie serverul pornit.");
                    navigate("/game-history");
                }
            } finally {
                setLoading(false);
            }
        };

        fetchGameDetails();
    }, [gameId, navigate]);

    const goToMove = (index) => {
        const tempGame = new Chess();
        
        for (let i = 0; i <= index; i++) {
            try {
                tempGame.move(moves[i]);
            } catch (e) {
                console.error("Eroare la aplicare mutare:", moves[i], e);
                break;
            }
        }
        
        setCurrentPosition(tempGame.fen());
        setCurrentMoveIndex(index);
    };

    const goToStart = () => {
        const tempGame = new Chess();
        setCurrentPosition(tempGame.fen());
        setCurrentMoveIndex(-1);
    };

    const goToEnd = () => {
        if (moves.length > 0) {
            goToMove(moves.length - 1);
        }
    };

    const nextMove = () => {
        if (currentMoveIndex < moves.length - 1) {
            goToMove(currentMoveIndex + 1);
        }
    };

    const prevMove = () => {
        if (currentMoveIndex >= 0) {
            goToMove(currentMoveIndex - 1);
        }
    };

    if (loading) {
        return (
            <div className="game-replay-page">
                <Navbar />
                <div className="loading">Se încarcă...</div>
            </div>
        );
    }

    if (!gameInfo) {
        return (
            <div className="game-replay-page">
                <Navbar />
                <div className="error">Jocul nu a fost găsit</div>
            </div>
        );
    }

    return (
        <div className="game-replay-page">
            <Navbar />
            
            <div className="replay-container">
                <div className="game-info-header">
                    <h2>🎮 Replay Joc #{gameId}</h2>
                    <p className="result">{gameInfo.result || "În curs"}</p>
                    {isOffline && (
                        <div className="offline-indicator">
                            📦 Mod Offline - Vizualizare din cache
                        </div>
                    )}
                </div>

                <div className="replay-content">
                    <div className="board-section">
                        <Chessboard 
                            position={currentPosition}
                            boardWidth={500}
                            arePiecesDraggable={false}
                        />
                        
                        <div className="controls">
                            <button onClick={goToStart} disabled={currentMoveIndex === -1}>
                                ⏮ Start
                            </button>
                            <button onClick={prevMove} disabled={currentMoveIndex === -1}>
                                ◀ Înapoi
                            </button>
                            <button onClick={nextMove} disabled={currentMoveIndex >= moves.length - 1}>
                                ▶ Înainte
                            </button>
                            <button onClick={goToEnd} disabled={currentMoveIndex === moves.length - 1}>
                                ⏭ Final
                            </button>
                        </div>

                        <div className="move-indicator">
                            Mutarea: {currentMoveIndex + 1} / {moves.length}
                        </div>
                    </div>

                    <div className="moves-list">
                        <h3>📝 Istoricul Mutărilor</h3>
                        <div className="moves-grid">
                            {moves.map((move, index) => (
                                <div 
                                    key={index}
                                    className={`move-item ${index === currentMoveIndex ? 'active' : ''}`}
                                    onClick={() => goToMove(index)}
                                >
                                    <span className="move-number">{Math.floor(index / 2) + 1}{index % 2 === 0 ? '.' : '...'}</span>
                                    <span className="move-notation">{move}</span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                <button className="back-button" onClick={() => navigate("/game-history")}>
                    ← Înapoi la istoric
                </button>
            </div>
        </div>
    );
}

export default GameReplayPage;
