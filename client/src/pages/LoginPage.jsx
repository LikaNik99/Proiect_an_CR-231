import React, { useState } from "react";
import axios from "axios";
import { useNavigate, Link } from "react-router-dom";
import "../App.css";
import "../style/LoginPage.css";

function LoginPage() {
    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [message, setMessage] = useState("");
    const navigate = useNavigate();
    const API_URL = "http://127.0.0.1:8000/auth";

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const res = await axios.post(`${API_URL}/login`, null, {
                params: { username, password },
            });

            console.log("LOGIN RES:", res.data);

            // ia id-ul corect (depinde cum il trimite serverul)
            const pid = res.data.player_id ?? res.data.id;

            if (!pid) {
                throw new Error("Server nu a trimis player_id / id");
            }

            // IMPORTANT: localStorage pentru consistență în toată aplicația
            localStorage.setItem(username, String(pid));

            setMessage(res.data.message || "Autentificat!");
            setTimeout(() => navigate("/home", { state: { username } }), 300);
        } catch (err) {
            const msg =
                err?.response?.data?.detail ||
                err?.response?.data?.message ||
                err?.message ||
                "Eroare de conexiune!";
            setMessage(msg);
        }
    };

    return (
        <div className="page">
            <div className="container">
                <h1>Autentificare</h1>

                <form onSubmit={handleSubmit}>
                    <input
                        type="text"
                        placeholder="Utilizator"
                        value={username}
                        onChange={(e) => setUsername(e.target.value)}
                        required
                    />
                    <input
                        type="password"
                        placeholder="Parolă"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                    />
                    <button type="submit">Login</button>
                </form>

                <p className="message">{message}</p>

                <p>
                    Nu ai cont? <Link to="/register">Înregistrează-te aici</Link>
                </p>
            </div>
        </div>
    );
}

export default LoginPage;
