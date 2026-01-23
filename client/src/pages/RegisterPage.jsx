import React, { useState } from "react";
import axios from "axios";
import { useNavigate, Link } from "react-router-dom";
import "../App.css";
import "../style/RegisterPage.css";


function RegisterPage() {
    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [message, setMessage] = useState("");
    const navigate = useNavigate();
    const API_URL = "http://127.0.0.1:8000/auth";

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            // 1. Register
            const resRegister = await axios.post(`${API_URL}/register`, null, {
                params: { username, password },
            });
            setMessage(resRegister.data.message || "Înregistrat cu succes!");

            // 2. Auto-login după register
            const resLogin = await axios.post(`${API_URL}/login`, null, {
                params: { username, password },
            });

            const pid = resLogin.data.player_id ?? resLogin.data.id;

            if (pid) {
                localStorage.setItem(username, String(pid));
                sessionStorage.setItem("username", username);
            }

            setTimeout(() => navigate("/home", { state: { username } }), 800);
        } catch (err) {
            if (err.response) setMessage(err.response.data.detail);
            else setMessage("Eroare de conexiune!");
        }
    };

    return (
        <div className="page">
            <div className="container">
                <h1>Înregistrare</h1>
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
                    <button type="submit">Creează cont</button>
                </form>
                <p className="message">{message}</p>
                <p>
                    Ai deja cont? <Link to="/">Autentifică-te aici</Link>
                </p>
            </div>
        </div>
    );
}

export default RegisterPage;
