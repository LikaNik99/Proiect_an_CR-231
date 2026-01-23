import { useState, useEffect, useRef } from "react";
import { useLocation, useNavigate } from "react-router-dom";

function CreateGame() {
    const location = useLocation();
    const navigate = useNavigate();
    const username = location.state?.username;

    const [lobbyId, setLobbyId] = useState(null);
    const [gameId, setGameId] = useState(null);
    const [selectedColor, setSelectedColor] = useState("white"); // white sau black
    const [isCreating, setIsCreating] = useState(false);
    const wsRef = useRef(null);

    // Cleanup la unmount - închidem WebSocket-ul
    useEffect(() => {
        return () => {
            if (wsRef.current) {
                console.log("🧹 Închid WebSocket la unmount");
                wsRef.current.close();
            }
        };
    }, []);

    const createLobby = () => {
        if (isCreating) {
            console.log("⚠️ Deja se creează un joc, ignor click");
            return;
        }

        console.log("🎮 Creare joc cu culoarea:", selectedColor);
        setIsCreating(true);
        const host = window.location.hostname;
        const player_id = localStorage.getItem(username);
        console.log("🆔 Player ID:", player_id);

        // ===========================
        //  CREAȚI LOBBY CU CULOARE
        // ===========================
        fetch(`http://${host}:8000/lobby/create?player_id=${player_id}&preferred_color=${selectedColor}`, {
            method: "POST",
        })
            .then((res) => res.json())
            .then((data) => {
                console.log("✅ Lobby creat:", data);
                setLobbyId(data.lobby_id);
                setGameId(data.game_id);

                // ===========================
                //   CONECTARE WEBSOCKET
                // ===========================
                const ws = new WebSocket(
                    `ws://${host}:8000/lobby/ws/${data.lobby_id}`
                );
                wsRef.current = ws;

                ws.onopen = () => console.log("✅ WS conectat la lobby");

                ws.onmessage = (event) => {
                    console.log("📩 Mesaj WS:", event.data);

                    if (event.data === "opponent_joined") {
                        console.log("🎉 Adversar alăturat! Redirecționez...");
                        ws.close();
                        wsRef.current = null;
                        navigate(`/play/${data.game_id}`, {
                            state: { username: username },
                        });
                    }
                };

                ws.onclose = () => {
                    console.log("❌ WS lobby închis");
                    wsRef.current = null;
                };

                ws.onerror = (err) => {
                    console.error("❌ Eroare WebSocket:", err);
                };
            })
            .catch((err) => {
                console.error("❌ Eroare la crearea lobby-ului:", err);
                setIsCreating(false);
                alert("Eroare la crearea jocului. Te rog încearcă din nou.");
            });
    };

    const cancelLobby = () => {
        console.log("🚫 Anulare lobby");
        if (wsRef.current) {
            wsRef.current.close();
            wsRef.current = null;
        }
        // Redirecționăm la home
        navigate("/home", { state: { username } });
    };

    const goDirectlyToGame = () => {
        // Opțiune: mergi direct la joc chiar dacă adversarul nu s-a alăturat încă
        if (gameId) {
            console.log("⚡ Mergi direct la joc:", gameId);
            if (wsRef.current) {
                wsRef.current.close();
                wsRef.current = null;
            }
            navigate(`/play/${gameId}`, {
                state: { username: username },
            });
        }
    };

    return (
        <div style={{ paddingTop: "120px", textAlign: "center", color: "white" }}>
            <h1>Creezi o partidă nouă ♟️</h1>

            {!lobbyId ? (
                <div style={{ marginTop: "40px" }}>
                    <h2 style={{ marginBottom: "30px" }}>Alege culoarea cu care vrei să joci:</h2>

                    <div style={{
                        display: "flex",
                        gap: "30px",
                        justifyContent: "center",
                        marginBottom: "30px"
                    }}>
                        {/* Opțiune Alb */}
                        <div
                            onClick={() => setSelectedColor("white")}
                            style={{
                                padding: "30px",
                                background: selectedColor === "white" ? "#6366f1" : "#1e293b",
                                borderRadius: "15px",
                                cursor: "pointer",
                                border: selectedColor === "white" ? "3px solid #818cf8" : "3px solid transparent",
                                transition: "all 0.3s",
                                minWidth: "200px"
                            }}
                        >
                            <div style={{ fontSize: "60px", marginBottom: "10px" }}>♔</div>
                            <div style={{ fontSize: "24px", fontWeight: "bold" }}>Alb</div>
                            <div style={{ fontSize: "14px", marginTop: "5px", opacity: 0.8 }}>
                                Mută primul
                            </div>
                        </div>

                        {/* Opțiune Negru */}
                        <div
                            onClick={() => setSelectedColor("black")}
                            style={{
                                padding: "30px",
                                background: selectedColor === "black" ? "#6366f1" : "#1e293b",
                                borderRadius: "15px",
                                cursor: "pointer",
                                border: selectedColor === "black" ? "3px solid #818cf8" : "3px solid transparent",
                                transition: "all 0.3s",
                                minWidth: "200px"
                            }}
                        >
                            <div style={{ fontSize: "60px", marginBottom: "10px" }}>♚</div>
                            <div style={{ fontSize: "24px", fontWeight: "bold" }}>Negru</div>
                            <div style={{ fontSize: "14px", marginTop: "5px", opacity: 0.8 }}>
                                Mută al doilea
                            </div>
                        </div>
                    </div>

                    <button
                        onClick={createLobby}
                        disabled={isCreating}
                        style={{
                            padding: "15px 40px",
                            fontSize: "18px",
                            fontWeight: "bold",
                            background: isCreating ? "#475569" : "#6366f1",
                            color: "white",
                            border: "none",
                            borderRadius: "10px",
                            cursor: isCreating ? "not-allowed" : "pointer",
                            transition: "all 0.3s"
                        }}
                    >
                        {isCreating ? "Se creează..." : "Creează Joc"}
                    </button>
                </div>
            ) : (
                <div style={{ marginTop: "40px" }}>
                    <h2>Lobby ID: {lobbyId}</h2>
                    <p style={{ fontSize: "18px", marginTop: "20px" }}>⏳ Așteaptă adversarul să se conecteze...</p>
                    <p style={{ marginTop: "15px", fontSize: "16px", opacity: 0.8 }}>
                        Vei juca cu: <strong>{selectedColor === "white" ? "Alb ♔" : "Negru ♚"}</strong>
                    </p>

                    <div style={{
                        marginTop: "40px",
                        display: "flex",
                        gap: "15px",
                        justifyContent: "center"
                    }}>
                        <button
                            onClick={goDirectlyToGame}
                            style={{
                                padding: "12px 25px",
                                fontSize: "16px",
                                background: "#6366f1",
                                color: "white",
                                border: "none",
                                borderRadius: "8px",
                                cursor: "pointer"
                            }}
                        >
                            🎮 Mergi la Joc Acum
                        </button>
                        <button
                            onClick={cancelLobby}
                            style={{
                                padding: "12px 25px",
                                fontSize: "16px",
                                background: "#475569",
                                color: "white",
                                border: "none",
                                borderRadius: "8px",
                                cursor: "pointer"
                            }}
                        >
                            ❌ Anulează
                        </button>
                    </div>

                    <p style={{ marginTop: "30px", fontSize: "14px", opacity: 0.6 }}>
                        Sau așteaptă ca un adversar să se alăture din lista de jocuri disponibile
                    </p>
                </div>
            )}
        </div>
    );
}

export default CreateGame;
