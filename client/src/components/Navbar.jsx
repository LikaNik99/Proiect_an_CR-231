import React from "react";
import { useNavigate, useLocation } from "react-router-dom";
import "../style/Navbar.css";


function Navbar({ username, onLogout, isInGame = false, onLeaveGame = null }) {
  const navigate = useNavigate();
  const location = useLocation();

  const handleBrandClick = () => {
    // Verificăm dacă suntem într-un joc activ
    const inGamePage = location.pathname.includes("/play/");
    
    if (inGamePage && isInGame) {
      // Afișăm confirmare
      const confirmed = window.confirm(
        "⚠️ Ești sigur că vrei să ieși din joc?\n\nDacă ieși acum, partida se consideră pierdută."
      );
      
      if (confirmed) {
        // Dacă există callback pentru leave game, îl apelăm
        if (onLeaveGame) {
          onLeaveGame();
        }
        // Navigăm la home
        navigate("/home", { state: { username } });
      }
    } else {
      // Dacă nu suntem în joc, navigăm direct la home
      navigate("/home", { state: { username } });
    }
  };

  return (
    <nav>
      <h2 
        onClick={handleBrandClick}
        style={{ cursor: "pointer" }}
        title="Înapoi la meniu principal"
      >
        ♟️ Chess App
      </h2>
      <div style={{ display: "flex", alignItems: "center", gap: "20px" }}>
        <span>Bun venit, {username}</span>
        <button onClick={onLogout}>Logout</button>
      </div>
    </nav>
  );
}

export default Navbar;
