import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import HomePage from "./pages/HomePage";
import PlayPages from "./pages/PlayPages";
import CreateGame from "./pages/CreateGame";
import GameList from "./pages/GameList";
import ProfilePage from "./pages/ProfilePage";
import GameHistoryPage from "./pages/GameHistoryPage";
import GameReplayPage from "./pages/GameReplayPage";

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/home" element={<HomePage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/game-history" element={<GameHistoryPage />} />
        <Route path="/game-replay/:gameId" element={<GameReplayPage />} />
        <Route path="/create-game" element={<CreateGame />} />
        <Route path="/game-list" element={<GameList />} />
        <Route path="/play/:gameId" element={<PlayPages />} />
      </Routes>
    </Router>
  );
}

export default App;
