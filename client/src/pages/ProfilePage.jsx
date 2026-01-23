import { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Navbar from "../components/Navbar";
import "../style/ProfilePage.css";

function ProfilePage() {
    const location = useLocation();
    const navigate = useNavigate();
    const username = location.state?.username || sessionStorage.getItem("username") || "Guest";

    const [profile, setProfile] = useState({
        username: username,
        gamesPlayed: 0,
        gamesWon: 0,
        gamesLost: 0,
        gamesDraw: 0,
        rating: 1200,
        joinDate: new Date().toISOString().split('T')[0]
    });

    const [isServerOnline, setIsServerOnline] = useState(true);

    useEffect(() => {
        // Încercăm să preluăm datele de la server
        const fetchProfile = async () => {
            try {
                const host = window.location.hostname;
                const player_id = localStorage.getItem(username);

                if (!player_id) {
                    console.warn("No player_id found");
                    return;
                }

                const response = await fetch(`http://${host}:8000/players/${player_id}`, {
                    signal: AbortSignal.timeout(3000)
                });

                if (response.ok) {
                    const data = await response.json();
                    const profileData = {
                        username: data.username || username,
                        gamesPlayed: data.games_played || 0,
                        gamesWon: data.games_won || 0,
                        gamesLost: data.games_lost || 0,
                        gamesDraw: data.games_draw || 0,
                        rating: data.rating || 1200,
                        joinDate: data.created_at ? new Date(data.created_at).toISOString().split('T')[0] : profile.joinDate
                    };
                    setProfile(profileData);
                    // Cache per jucător
                    localStorage.setItem(`cached_profile_${username}`, JSON.stringify(profileData));
                    setIsServerOnline(true);
                }
            } catch (error) {
                console.log("Server offline sau eroare:", error);
                setIsServerOnline(false);
                // Folosim date locale/cache per jucător
                const player_id = localStorage.getItem(username);
                if (player_id) {
                    const cachedProfile = localStorage.getItem(`cached_profile_${player_id}`);
                    if (cachedProfile) {
                        setProfile(JSON.parse(cachedProfile));
                    }
                }
            }
        };

        fetchProfile();
    }, [username]);

    // Salvăm profilul local pentru offline
    useEffect(() => {
        localStorage.setItem("cached_profile", JSON.stringify(profile));
    }, [profile]);

    const winRate = profile.gamesPlayed > 0
        ? ((profile.gamesWon / profile.gamesPlayed) * 100).toFixed(1)
        : 0;

    return (
        <>
            <Navbar username={username} onLogout={() => navigate("/")} />

            <main className="profile-page">
                <div className="profile-container">
                    <div className="profile-header">
                        <div className="profile-avatar">
                            {username.charAt(0).toUpperCase()}
                        </div>
                        <h1>{username}</h1>
                        {!isServerOnline && (
                            <div className="offline-badge">
                                ⚠️ Mod Offline
                            </div>
                        )}
                    </div>

                    <div className="profile-stats">
                        <div className="stat-card">
                            <div className="stat-value">{profile.rating}</div>
                            <div className="stat-label">Rating</div>
                        </div>

                        <div className="stat-card">
                            <div className="stat-value">{profile.gamesPlayed}</div>
                            <div className="stat-label">Jocuri Jucate</div>
                        </div>

                        <div className="stat-card">
                            <div className="stat-value">{winRate}%</div>
                            <div className="stat-label">Rata Victorii</div>
                        </div>
                    </div>

                    <div className="profile-details">
                        <h2>Statistici Detaliate</h2>

                        <div className="detail-row">
                            <span className="detail-label">🏆 Victorii:</span>
                            <span className="detail-value">{profile.gamesWon}</span>
                        </div>

                        <div className="detail-row">
                            <span className="detail-label">❌ Înfrângeri:</span>
                            <span className="detail-value">{profile.gamesLost}</span>
                        </div>

                        <div className="detail-row">
                            <span className="detail-label">🤝 Remize:</span>
                            <span className="detail-value">{profile.gamesDraw}</span>
                        </div>

                        <div className="detail-row">
                            <span className="detail-label">📅 Membru din:</span>
                            <span className="detail-value">{profile.joinDate}</span>
                        </div>
                    </div>

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

export default ProfilePage;
