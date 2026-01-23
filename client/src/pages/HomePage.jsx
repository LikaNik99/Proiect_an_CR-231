import { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Navbar from "../components/Navbar";
import "../App.css";
import "../style/HomePage.css";


function HomePage() {
    const location = useLocation();
    const navigate = useNavigate();
    const username = location.state?.username || sessionStorage.getItem("username") || "Guest";
    
    const [isServerOnline, setIsServerOnline] = useState(true);

    // Verificăm dacă serverul de joc e disponibil
    useEffect(() => {
        const checkServerHealth = async () => {
            try {
                const host = window.location.hostname;
                const response = await fetch(`http://${host}:8000/lobby/waiting`, {
                    signal: AbortSignal.timeout(2000)
                });
                setIsServerOnline(response.ok);
            } catch (error) {
                setIsServerOnline(false);
            }
        };

        checkServerHealth();
        // Re-verificăm la fiecare 30 secunde
        const interval = setInterval(checkServerHealth, 30000);
        return () => clearInterval(interval);
    }, []);

    return (
        <>
            <Navbar username={username} onLogout={() => navigate("/")} />
            <main className="home-main">
                <div className="home-wrap">
                    <h1 className="home-title">Bine ai venit, {username} ♟️</h1>
                    <p className="home-subtitle">Alege o opțiune pentru a continua</p>

                    <div className="home-card">
                        <div className="home-actions">
                            <button
                                className="btn home-btn"
                                onClick={() => navigate("/profile", { state: { username } })}
                            >
                                <span className="btn-icon">👤</span>
                                <span className="btn-text">Profile</span>
                            </button>

                            <button
                                className="btn home-btn"
                                onClick={() => navigate("/game-history", { state: { username } })}
                            >
                                <span className="btn-icon">📋</span>
                                <span className="btn-text">Game History</span>
                            </button>

                            <button 
                                className="btn home-btn primary"
                                onClick={() => navigate("/create-game", { state: { username } })}
                                disabled={!isServerOnline}
                                title={!isServerOnline ? "Server indisponibil" : ""}
                            >
                                <span className="btn-icon">➕</span>
                                <span className="btn-text">Creează joc</span>
                            </button>

                            <button 
                                className="btn home-btn primary"
                                onClick={() => navigate("/game-list", { state: { username } })}
                                disabled={!isServerOnline}
                                title={!isServerOnline ? "Server indisponibil" : ""}
                            >
                                <span className="btn-icon">🔍</span>
                                <span className="btn-text">Caută joc</span>
                            </button>
                        </div>

                        {!isServerOnline && (
                            <div className="server-status-warning">
                                ⚠️ Serverul de joc nu este disponibil. Poți accesa Profile și Game History.
                            </div>
                        )}
                    </div>
                </div>
            </main>
        </>
    );
}

export default HomePage;
