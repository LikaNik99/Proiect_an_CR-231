import { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";

function GameList() {
    const [games, setGames] = useState([]);
    const [showColorModal, setShowColorModal] = useState(false);
    const [selectedLobby, setSelectedLobby] = useState(null);
    const [selectedColor, setSelectedColor] = useState(null);
    const location = useLocation();
    const navigate = useNavigate();
    const username = location.state?.username;

    useEffect(() => {
        const host = window.location.hostname;

        fetch(`http://${host}:8000/lobby/waiting`)
            .then((res) => res.json())
            .then((data) => {
                console.log("📋 Toate jocurile din server:", data);
                setGames(data);   // <-- NU mai filtrăm nimic
            })
            .catch(err => {
                console.error("❌ Eroare la încărcare jocuri:", err);
            });
    }, []);


    // ===========================
    //      DESCHIDE MODAL CULOARE
    // ===========================
    const openColorModal = (lobby) => {
        setSelectedLobby(lobby);
        // Setăm culoarea opusă celei a creatorului (AUTOMAT - nu se poate schimba)
        if (lobby.creator_color === "white") {
            setSelectedColor("black");
        } else if (lobby.creator_color === "black") {
            setSelectedColor("white");
        } else {
            setSelectedColor("white"); // Default
        }
        setShowColorModal(true);
    };

    // ===========================
    //      JOIN în lobby
    // ===========================
    const joinGame = () => {
        if (!selectedLobby || !selectedColor) return;

        const host = window.location.hostname;
        const player_id = localStorage.getItem(username);

        fetch(`http://${host}:8000/lobby/join/${selectedLobby.id}?player_id=${player_id}&preferred_color=${selectedColor}`, {
            method: "POST",
        })
            .then((res) => {
                if (!res.ok) {
                    return res.json().then(err => {
                        throw new Error(err.detail || "Eroare la alăturare");
                    });
                }
                return res.json();
            })
            .then((data) => {
                setShowColorModal(false);
                navigate(`/play/${data.game_id}`, {
                    state: { username: username },
                });
            })
            .catch((err) => {
                alert(`Eroare: ${err.message}`);
            });
    };

    return (
        <div style={{ paddingTop: "120px", textAlign: "center", color: "white" }}>
            <h1>Jocuri Disponibile</h1>
            <p>Selectează un joc din listă:</p>

            {games.length === 0 ? (
                <p style={{ marginTop: "20px" }}>Nu există jocuri disponibile...</p>
            ) : (
                games.map((g) => (
                    <div
                        key={g.id}
                        style={{
                            margin: "15px",
                            padding: "15px",
                            background: "#1b222c",
                            borderRadius: "10px",
                        }}
                    >
                        <strong>Lobby #{g.id}</strong>
                        {g.creator_color && (
                            <p style={{ fontSize: "14px", marginTop: "5px", opacity: 0.8 }}>
                                Creatorul joacă cu: {g.creator_color === "white" ? "Alb ♔" : "Negru ♚"}
                            </p>
                        )}
                        <button
                            style={{ marginTop: "10px", padding: "8px 20px" }}
                            onClick={() => openColorModal(g)}
                        >
                            Join
                        </button>
                    </div>
                ))
            )}

            {/* MODAL PENTRU CONFIRMAREA CULORII ALOCATE */}
            {showColorModal && selectedLobby && (
                <div
                    style={{
                        position: "fixed",
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        background: "rgba(0, 0, 0, 0.8)",
                        display: "flex",
                        justifyContent: "center",
                        alignItems: "center",
                        zIndex: 1000,
                    }}
                    onClick={() => setShowColorModal(false)}
                >
                    <div
                        style={{
                            background: "#1e293b",
                            padding: "40px",
                            borderRadius: "15px",
                            maxWidth: "500px",
                            width: "90%",
                            textAlign: "center"
                        }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <h2 style={{ marginBottom: "20px" }}>Alătură-te la Joc</h2>

                        {selectedLobby.creator_color && (
                            <p style={{ marginBottom: "15px", opacity: 0.8, fontSize: "14px" }}>
                                Creatorul joacă cu: <strong>{selectedLobby.creator_color === "white" ? "Alb ♔" : "Negru ♚"}</strong>
                            </p>
                        )}

                        <div style={{
                            marginTop: "30px",
                            marginBottom: "30px",
                            padding: "30px",
                            background: "#334155",
                            borderRadius: "15px",
                            border: "3px solid #6366f1"
                        }}>
                            <p style={{ marginBottom: "15px", fontSize: "16px" }}>
                                Tu vei juca cu:
                            </p>
                            <div style={{ fontSize: "60px", marginBottom: "10px" }}>
                                {selectedColor === "white" ? "♔" : "♚"}
                            </div>
                            <div style={{ fontSize: "28px", fontWeight: "bold", color: "#6366f1" }}>
                                {selectedColor === "white" ? "Alb" : "Negru"}
                            </div>
                            <p style={{ marginTop: "15px", fontSize: "12px", opacity: 0.6 }}>
                                (Culoarea este alocată automat)
                            </p>
                        </div>

                        <div style={{ display: "flex", gap: "15px", justifyContent: "center" }}>
                            <button
                                onClick={() => setShowColorModal(false)}
                                style={{
                                    padding: "12px 25px",
                                    background: "#475569",
                                    color: "white",
                                    border: "none",
                                    borderRadius: "8px",
                                    cursor: "pointer",
                                    fontSize: "16px"
                                }}
                            >
                                ❌ Anulează
                            </button>
                            <button
                                onClick={joinGame}
                                style={{
                                    padding: "12px 25px",
                                    background: "#6366f1",
                                    color: "white",
                                    border: "none",
                                    borderRadius: "8px",
                                    cursor: "pointer",
                                    fontSize: "16px",
                                    fontWeight: "bold"
                                }}
                            >
                                ✅ Confirmă & Join
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

export default GameList;
