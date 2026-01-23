import React, { useState, useEffect, useRef } from "react";
import { Chess } from "chess.js";
import { Chessboard } from "react-chessboard";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import "../style/PlayPages.css";

function PlayPages() {
  const { gameId } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const username =
    location.state?.username || sessionStorage.getItem("username") || "Guest";

  // Game state
  const [game, setGame] = useState(new Chess());
  const [socket, setSocket] = useState(null);

  // Chat
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");

  // IMPORTANT: null până se determină culoarea
  const [playerColor, setPlayerColor] = useState(null); // "white" | "black" | null
  const [gameStatus, setGameStatus] = useState("loading"); // "loading" | "waiting" | "ready" | "playing"
  const [opponentConnected, setOpponentConnected] = useState(false);
  const [whiteTime, setWhiteTime] = useState(600);
  const [blackTime, setBlackTime] = useState(600);

  const boardWidth = 460;
  const colorDeterminedRef = useRef(false);
  const socketRef = useRef(null);

  // ✅ IMPORTANT: keep latest game/playerColor for WS callbacks and turn checks
  const gameRef = useRef(game);
  const playerColorRef = useRef(playerColor);

  useEffect(() => {
    gameRef.current = game;
  }, [game]);

  useEffect(() => {
    playerColorRef.current = playerColor;
  }, [playerColor]);

  useEffect(() => {
    console.log("🎮 PlayPages montat");
    console.log("GameId:", gameId);

    sessionStorage.setItem("username", username);

    // Încărcăm starea jocului la montare pentru a restaura după refresh
    const loadGameState = async () => {
      try {
        const host = window.location.hostname;
        const res = await fetch(
          `http://${host}:8000/lobby/game/${gameId}/state`
        );
        if (!res.ok) throw new Error(`HTTP error: ${res.status}`);
        const data = await res.json();

        console.log("📥 Stare joc încărcată:", data);

        if (
          data.fen &&
          data.fen !==
          "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        ) {
          const restoredGame = new Chess(data.fen);
          setGame(restoredGame);
          console.log("✅ Stare joc restaurată cu FEN:", data.fen);
        }

        if (data.status === "completed" && data.result) {
          alert(`🎮 Jocul s-a terminat: ${data.result}`);
          setTimeout(() => navigate("/home", { state: { username } }), 2000);
        }
      } catch (err) {
        console.error("❌ Eroare la încărcare stare joc:", err);
      }
    };

    loadGameState();
  }, [gameId, username, navigate]);

  useEffect(() => {
    console.log("🔄 FEN:", game.fen());
  }, [game]);

  // ======================================
  //     DETERMINARE CULOARE JUCĂTOR
  // ======================================
  useEffect(() => {
    const host = window.location.hostname;

    // ⚠️ Ai folosit localStorage.getItem(username) în mai multe locuri.
    // Dacă la login salvezi în cheia "player_id", schimbă aici în "player_id".
    // Las exact ca în codul tău, dar recomand să folosești "player_id".
    const player_id = localStorage.getItem(username);

    if (!player_id) {
      console.error("❌ Player ID nu este în localStorage");
      setPlayerColor(null);
      setGameStatus("error");
      return;
    }

    const fetchGameInfo = async () => {
      try {
        const res = await fetch(`http://${host}:8000/lobby/game/${gameId}`);
        if (!res.ok) throw new Error(`HTTP error: ${res.status}`);
        const data = await res.json();

        console.log("📋 Game info:", data);
        console.log("📋 player_id:", player_id);

        const currentPlayerId = parseInt(player_id, 10);
        const whiteId =
          data.white_player_id !== null && data.white_player_id !== undefined
            ? parseInt(data.white_player_id, 10)
            : null;
        const blackId =
          data.black_player_id !== null && data.black_player_id !== undefined
            ? parseInt(data.black_player_id, 10)
            : null;

        const gameIsComplete = whiteId !== null && blackId !== null;

        if (whiteId !== null && currentPlayerId === whiteId) {
          setPlayerColor("white");
          colorDeterminedRef.current = true;
          console.log("✅ Sunt ALB");

          if (gameIsComplete) {
            setGameStatus("ready");
            setOpponentConnected(true);
          } else {
            setGameStatus("waiting");
          }
          return;
        }

        if (blackId !== null && currentPlayerId === blackId) {
          setPlayerColor("black");
          colorDeterminedRef.current = true;
          console.log("✅ Sunt NEGRU");

          if (gameIsComplete) {
            setGameStatus("ready");
            setOpponentConnected(true);
          } else {
            setGameStatus("waiting");
          }
          return;
        }

        console.warn("⚠️ Culoarea nu e determinată încă. Aștept...");
        setPlayerColor(null);
        setGameStatus("loading");
      } catch (err) {
        console.error("❌ Eroare fetch game info:", err);
        setPlayerColor(null);
        setGameStatus("error");
      }
    };

    fetchGameInfo();

    let attempts = 0;
    const maxAttempts = 15;

    const intervalId = setInterval(() => {
      attempts++;
      if (colorDeterminedRef.current || attempts >= maxAttempts) {
        clearInterval(intervalId);
        if (!colorDeterminedRef.current) setGameStatus("error");
        return;
      }
      fetchGameInfo();
    }, 2000);

    return () => clearInterval(intervalId);
  }, [gameId]);

  // ======================================
  //             INITIALIZARE WS
  // ======================================
  useEffect(() => {
    const host = window.location.hostname;
    const ws = new WebSocket(`ws://${host}:8000/ws/game/${gameId}`);
    socketRef.current = ws;

    ws.onopen = () => {
      console.log("✅ WS conectat:", gameId);
      setSocket(ws);
    };

    ws.onclose = () => {
      console.log("❌ WS deconectat");
      setSocket(null);
      socketRef.current = null;
    };

    ws.onerror = (err) => console.error("WS error:", err);

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        console.log("📩 WS:", data);

        // game_state
        if (data.type === "game_state") {
          if (data.fen && data.fen !== gameRef.current.fen()) {
            const syncedGame = new Chess(data.fen);
            setGame(syncedGame);
            gameRef.current = syncedGame;
            console.log("✅ Stare sincronizată:", data.fen);
          }
          if (typeof data.white_time === "number") setWhiteTime(data.white_time);
          if (typeof data.black_time === "number") setBlackTime(data.black_time);
        }

        if (data.type === "game_ready") {
          console.log("✅ Jocul e gata să înceapă!");
          setGameStatus("playing");
          setOpponentConnected(true);
        }

        if (data.type === "opponent_connected") {
          console.log("✅ Adversar conectat!");
          setOpponentConnected(true);
          setGameStatus("playing");
        }

        if (data.type === "timer_update") {
          setWhiteTime(data.white_time);
          setBlackTime(data.black_time);
        }

        if (data.type === "move") {
          setGame((prev) => {
            try {
              const g = new Chess();

              if (data.fen) {
                g.load(data.fen);
                gameRef.current = g;
                return g;
              }

              g.load(prev.fen());
              const mv = g.move({
                from: data.from,
                to: data.to,
                promotion: "q",
              });
              if (!mv) return prev;

              gameRef.current = g;
              return g;
            } catch {
              return prev;
            }
          });
        }

        if (data.type === "chat") {
          setMessages((prev) => [...prev, { user: data.user, text: data.chat }]);
        }

        if (data.type === "move_error") {
          const msg = data.message || "Mutare respinsă de server!";
          console.error("move_error:", msg);
          alert(msg);
        }

        if (data.type === "game_over") {
          const result = data.result || "Joc terminat";
          const reason = data.reason;
          const winnerRaw = data.winner;

          // ✅ folosim ref (nu state capturat)
          const myColor = playerColorRef.current;

          // normalize winner/myColor in case server sends w/b
          const normalize = (c) => {
            if (!c) return c;
            const s = String(c).toLowerCase();
            if (s === "w") return "white";
            if (s === "b") return "black";
            return s;
          };

          const winner = normalize(winnerRaw);
          const me = normalize(myColor);

          let message = result;

          if (reason === "resign") {
            const resignedPlayer = normalize(data.resigned_player);
            if (resignedPlayer && resignedPlayer === me) {
              message = `❌ Ai abandonat. ${result}`;
            } else {
              message = `🏆 Adversarul a abandonat! ${result}`;
            }
          } else if (reason === "checkmate") {
            console.log("winner, me:", winner, me);
            if (winner && me && winner === me) message = `🏆 Ai câștigat! ${result}`;
            else message = `❌ Ai pierdut. ${result}`;
          } else if (reason === "time") {
            if (winner && me && winner === me) message = `🏆 Ai câștigat la timp! ${result}`;
            else message = `❌ Ai pierdut la timp. ${result}`;
          } else if (
            [
              "stalemate",
              "insufficient_material",
              "50_moves",
              "75_moves",
              "threefold_repetition",
              "fivefold_repetition",
            ].includes(reason)
          ) {
            message = `🤝 ${result}`;
          }

          alert(message);
          setTimeout(() => navigate("/home", { state: { username } }), 2000);
        }
      } catch (err) {
        console.error("WS parse error:", err);
      }
    };

    return () => {
      ws.close();
      setSocket(null);
      socketRef.current = null;
    };
  }, [gameId, navigate, username]);

  // ======================================
  //              MUTARE LOCALĂ
  // ======================================
  const handleMove = (sourceSquare, targetSquare) => {
    console.log("🎯 handleMove:", sourceSquare, "→", targetSquare);
    console.log("  playerColor:", playerColorRef.current);
    console.log("  gameStatus:", gameStatus);

    const myColor = playerColorRef.current;

    if (!myColor) {
      console.log("⏳ Culoarea nu este stabilită încă.");
      return false;
    }

    if (gameStatus !== "playing" && gameStatus !== "ready") {
      console.log("⏳ Jocul nu a început încă. Status:", gameStatus);
      return false;
    }

    try {
      const fenBeforeMove = gameRef.current.fen();
      const gameCopy = new Chess(fenBeforeMove);

      const isWhiteTurn = gameCopy.turn() === "w";
      const myTurn =
        (isWhiteTurn && myColor === "white") ||
        (!isWhiteTurn && myColor === "black");

      if (!myTurn) {
        console.log("❌ Nu este rândul tău.");
        return false;
      }

      let move = gameCopy.move({ from: sourceSquare, to: targetSquare });

      if (!move) {
        move = gameCopy.move({
          from: sourceSquare,
          to: targetSquare,
          promotion: "q",
        });
      }

      if (!move) {
        console.log("❌ Mutare invalidă");
        return false;
      }

      console.log("✅ Mutare validă, trimit la server:", move);

      // feedback instant
      setGame(gameCopy);
      gameRef.current = gameCopy;

      if (socket && socket.readyState === WebSocket.OPEN) {
        const player_id = localStorage.getItem(username);
        socket.send(
          JSON.stringify({
            type: "move",
            from: sourceSquare,
            to: targetSquare,
            player: username,
            player_id: parseInt(player_id, 10),
            fen: fenBeforeMove,
          })
        );
        return true;
      }

      console.log("❌ WS nu e deschis, revert");
      const reverted = new Chess(fenBeforeMove);
      setGame(reverted);
      gameRef.current = reverted;
      return false;
    } catch (err) {
      console.error("❌ Eroare la mutare:", err);
      return false;
    }
  };

  // ======================================
  //                  CHAT
  // ======================================
  const sendMessage = () => {
    if (!input.trim()) return;

    if (socket?.readyState === WebSocket.OPEN) {
      socket.send(
        JSON.stringify({
          type: "chat",
          user: username,
          chat: input,
        })
      );
    }

    setMessages((prev) => [...prev, { user: username, text: input }]);
    setInput("");
  };

  // ======================================
  //            ABANDON / RESIGN
  // ======================================
  const handleResign = () => {
    const player_id = localStorage.getItem(username);
    const myColor = playerColorRef.current;

    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(
        JSON.stringify({
          type: "resign",
          player: username,
          player_id: parseInt(player_id, 10),
          player_color: myColor,
        })
      );
    }

    alert("Ai abandonat jocul. Adversarul a câștigat.");
    navigate("/home", { state: { username } });
  };

  const handleLeaveGame = () => {
    handleResign();
  };

  return (
    <>
      <Navbar
        username={username}
        onLogout={() => navigate("/")}
        isInGame={gameStatus === "playing" || gameStatus === "ready"}
        onLeaveGame={handleLeaveGame}
      />

      <main className="play-page">
        <div className="board-area">
          <h1 className="title">Joc de șah în timp real ♟️</h1>
          <h2 style={{ color: "var(--muted)" }}>Game ID: {gameId}</h2>

          <p style={{ color: "var(--muted)", marginTop: "10px" }}>
            Joci cu:{" "}
            <strong>
              {playerColor === "white"
                ? "Alb ♔"
                : playerColor === "black"
                  ? "Negru ♚"
                  : "Se încarcă..."}
            </strong>
          </p>

          {gameStatus === "waiting" && (
            <div className="game-status-banner waiting">
              ⏳ Așteptăm adversarul să se alăture...
            </div>
          )}

          {gameStatus === "loading" && (
            <div className="game-status-banner loading">
              🔄 Se încarcă datele jocului...
            </div>
          )}

          {gameStatus === "error" && (
            <div className="game-status-banner error">
              ❌ Eroare la încărcarea jocului. Te rog reîncearcă.
            </div>
          )}

          {(gameStatus === "ready" || gameStatus === "playing") &&
            opponentConnected && (
              <div className="game-status-banner ready">
                ✅ Jocul poate începe!{" "}
                {game.turn() === "w" ? "Albul" : "Negrul"} la mutare.
              </div>
            )}

          <div className="game-layout">
            <div className="chess-box" style={{ width: boardWidth }}>
              {<div className="timer-box">
                <div className="timer white">♔ Alb: {Math.floor(whiteTime / 60)}:{String(whiteTime % 60).padStart(2, '0')}</div>
                <div className="timer black">♚ Negru: {Math.floor(blackTime / 60)}:{String(blackTime % 60).padStart(2, '0')}</div> </div>
              }
              <Chessboard
                position={game.fen()}
                boardWidth={boardWidth}
                boardOrientation={playerColor === "black" ? "black" : "white"}
                customBoardStyle={{
                  borderRadius: "15px",
                  boxShadow: "0 5px 18px rgba(0,0,0,0.6)",
                }}
                onPieceDrop={(sourceSquare, targetSquare) => {
                  console.log("🖱️ Piece dropped:", sourceSquare, "→", targetSquare);
                  const result = handleMove(sourceSquare, targetSquare);
                  console.log("📤 Result:", result);
                  return result;
                }}
                arePiecesDraggable={true}
              />
            </div>

            <div className="chat-box">
              <div className="chat-messages">
                {messages.length === 0 ? (
                  <p className="muted">💬 Nicio conversație încă</p>
                ) : (
                  messages.map((m, i) => (
                    <div key={i} className="chat-message">
                      <strong>{m.user}:</strong> {m.text}
                    </div>
                  ))
                )}
              </div>

              <div className="chat-input">
                <input
                  type="text"
                  placeholder="Scrie un mesaj..."
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && sendMessage()}
                />
                <button onClick={sendMessage}>Trimite</button>
              </div>
            </div>
          </div>

          <div className="game-actions">
            <button
              className="btn back-btn"
              onClick={() => {
                const confirmed = window.confirm(
                  "⚠️ Dacă părăsești jocul acum, partida se consideră pierdută. Continui?"
                );
                if (confirmed) {
                  handleResign();
                }
              }}
            >
              ← Abandonează & Ieși
            </button>
          </div>
        </div>
      </main>
    </>
  );
}

export default PlayPages;
