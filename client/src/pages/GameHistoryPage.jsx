import { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Navbar from "../components/Navbar";
import "../style/GameHistoryPage.css";

function GameHistoryPage() {
    const location = useLocation();
    const navigate = useNavigate();
    const username = location.state?.username || sessionStorage.getItem("username") || "Guest";

    const [games, setGames] = useState([]);
    const [isServerOnline, setIsServerOnline] = useState(true);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchGameHistory = async () => {
            try {
                const host = window.location.hostname;
                const player_id = localStorage.getItem(username);

                if (!player_id) {
                    console.warn("No player_id found");
                    setLoading(false);
                    return;
                }

                const response = await fetch(`http://${host}:8000/players/${player_id}/games`, {
                    signal: AbortSignal.timeout(3000)
                });

                if (response.ok) {
                    const data = await response.json();
                    console.log("🧾 exemplu game:", data?.[0]);
                    setGames(data);
                    setIsServerOnline(true);
                    // Cache pentru offline - per jucător
                    localStorage.setItem(`cached_game_history_${player_id}`, JSON.stringify(data));

                    // Salvăm fiecare joc individual pentru replay offline
                    data.forEach(game => {
                        localStorage.setItem(`cached_game_details_${game.id}`, JSON.stringify(game));
                    });
                } else {
                    throw new Error("Server error");
                }
            } catch (error) {
                console.log("Server offline sau eroare:", error);
                setIsServerOnline(false);
                // Încarcă din cache - per jucător
                const player_id = localStorage.getItem(username);
                if (player_id) {
                    const cached = localStorage.getItem(`cached_game_history_${player_id}`);
                    if (cached) {
                        setGames(JSON.parse(cached));
                    }
                }
            } finally {
                setLoading(false);
            }
        };

        fetchGameHistory();
    }, []);

    const formatDate = (dateString) => {
        if (!dateString) return "N/A";
        const date = new Date(dateString);
        return date.toLocaleDateString("ro-RO", {
            year: "numeric",
            month: "short",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit"
        });
    };

    const normalizeWinner = (w) => {
        if (!w) return null;
        const s = String(w).toLowerCase();
        if (s === "w") return "white";
        if (s === "b") return "black";
        if (["white", "black", "draw"].includes(s)) return s;
        return null;
    };

    const getResultBadge = (game, playerId) => {
        const pid = parseInt(playerId, 10);

        // Dacă jocul nu e complet, e în desfășurare
        if (game.status !== "completed" && game.status !== "finished") {
            return { text: "În desfășurare", className: "ongoing" };
        }

        // 1) Încearcă winner (dacă există)
        const winner = normalizeWinner(game.winner);
        if (winner === "draw") return { text: "Remiză", className: "draw" };
        if (winner === "white") {
            return pid === parseInt(game.white_player_id, 10)
                ? { text: "Victorie", className: "win" }
                : { text: "Înfrângere", className: "loss" };
        }
        if (winner === "black") {
            return pid === parseInt(game.black_player_id, 10)
                ? { text: "Victorie", className: "win" }
                : { text: "Înfrângere", className: "loss" };
        }

        // 2) Fallback pe result (de obicei 1-0 / 0-1 / 1/2-1/2)
        const r = String(game.result || "").trim();
        if (r === "1/2-1/2") return { text: "Remiză", className: "draw" };
        if (r === "1-0") {
            return pid === parseInt(game.white_player_id, 10)
                ? { text: "Victorie", className: "win" }
                : { text: "Înfrângere", className: "loss" };
        }
        if (r === "0-1") {
            return pid === parseInt(game.black_player_id, 10)
                ? { text: "Victorie", className: "win" }
                : { text: "Înfrângere", className: "loss" };
        }

        // Dacă backend-ul pune "Alb câștigă"/etc, păstrăm și asta ca ultim fallback
        const low = r.toLowerCase();
        if (low.includes("remiz") || low.includes("draw")) return { text: "Remiză", className: "draw" };
        if (low.includes("alb") || low.includes("white")) {
            return pid === parseInt(game.white_player_id, 10)
                ? { text: "Victorie", className: "win" }
                : { text: "Înfrângere", className: "loss" };
        }
        if (low.includes("negru") || low.includes("black")) {
            return pid === parseInt(game.black_player_id, 10)
                ? { text: "Victorie", className: "win" }
                : { text: "Înfrângere", className: "loss" };
        }

        return { text: "În desfășurare", className: "ongoing" };
    };



    return (
        <>
            <Navbar username={username} onLogout={() => navigate("/")} />

            <main className="game-history-page">
                <div className="history-container">
                    <div className="history-header">
                        <h1>📋 Istoric Jocuri</h1>
                        {!isServerOnline && (
                            <div className="offline-badge">
                                ⚠️ Mod Offline - Datele pot fi învechite
                            </div>
                        )}
                    </div>

                    {loading ? (
                        <div className="loading-state">
                            <p>Se încarcă istoricul...</p>
                        </div>
                    ) : games.length === 0 ? (
                        <div className="empty-state">
                            <p>📭 Nu ai jucat încă niciun joc</p>
                            <button
                                className="btn"
                                onClick={() => navigate("/home", { state: { username } })}
                            >
                                Începe să joci
                            </button>
                        </div>
                    ) : (
                        <div className="games-list">
                            {games.map((game) => {
                                const playerId = localStorage.getItem(username);
                                const resultBadge = getResultBadge(game, playerId);


                                const isWhite = parseInt(playerId) === parseInt(game.white_player_id);

                                return (
                                    <div key={game.id} className="game-card">
                                        <div className="game-info">
                                            <div className="game-id">Joc #{game.id}</div>
                                            <div className="game-date">{formatDate(game.started_at)}</div>
                                        </div>

                                        <div className="game-details">
                                            <div className="player-info">
                                                <span className="player-role">
                                                    {isWhite ? "♔ Alb" : "♚ Negru"}
                                                </span>
                                                <span className="vs">vs</span>
                                                <span className="opponent">
                                                    {isWhite ? "♚ Adversar Negru" : "♔ Adversar Alb"}
                                                </span>
                                            </div>

                                            <div className={`result-badge ${resultBadge.className}`}>
                                                {resultBadge.text}
                                            </div>
                                        </div>

                                        {game.ended_at && (
                                            <div className="game-duration">
                                                Finalizat: {formatDate(game.ended_at)}
                                            </div>
                                        )}

                                        {game.status === "completed" && game.moves && (
                                            <button
                                                className="replay-button"
                                                onClick={() => navigate(`/game-replay/${game.id}`)}
                                            >
                                                🎬 Vezi Replay
                                            </button>
                                        )}
                                    </div>
                                );
                            })}
                        </div>
                    )}

                    <button
                        className="btn back-btn"
                        onClick={() => navigate("/home", { state: { username } })}
                    >
                        ← Înapoi la Meniu
                    </button>
                </div>
            </main>
        </>
    );
}

export default GameHistoryPage;
