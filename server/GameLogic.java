package server;

import shared.GameState;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import javax.swing.Timer;

public class GameLogic {
    private Deck deck;
    private final Player dealer;
    private final Map<Integer, Player> players; 
    private final Set<Integer> playersWhoBetted = new HashSet<>(); 
    private final Map<Integer, Integer> currentBets = new ConcurrentHashMap<>();
    private final AtomicInteger nextPlayerId = new AtomicInteger(1);
    private int currentPlayerIndex = -1; 
    private List<Integer> roundOrder = new ArrayList<>(); 
    private String message = "PUNEȚI PARIURILE!";
    private boolean gameOver = true;
    private int minBet = 100;
    private int maxSeats = 4;

    public GameLogic() {
        this.dealer = new Player(true);
        this.players = new ConcurrentHashMap<>(); 
    }
    
    public int addPlayer() {
        if (players.size() >= maxSeats) return -1;
        int id = nextPlayerId.getAndIncrement();
        players.put(id, new Player(false));
        updateLobby();
        return id;
    }
    
    public void removePlayer(int id) {
        players.remove(id);
        playersWhoBetted.remove(id);
        currentBets.remove(id);
        updateLobby();
        if (id == getCurrentPlayerId()) nextPlayerTurn(); 
    }

    private void updateLobby() {
        // FIX: Actualizează ocuparea mesei "Masa VIP #1" cu numărul real de jucători
        int currentPlayers = players.size();
        int maxSeats = 4;
        int minBet = 100;
        DatabaseManager.updateTableOccupancy("Masa VIP #1", maxSeats, currentPlayers, minBet);
        
        // REPARAȚIE: Forțăm actualizarea vizuală a lobby-ului
        ServerMain.broadcastTableList();
    }

    public void placeBet(int playerId, int amount) {
        if (amount >= minBet) {
            // FIX: Verifică dacă jucătorul a pariat deja pentru a preveni dublu bet
            if (playersWhoBetted.contains(playerId)) {
                return; // Jucătorul a pariat deja, nu permite dublu bet
            }
            
            playersWhoBetted.add(playerId);
            currentBets.put(playerId, amount);
            String username = ServerMain.getUserById(playerId);
            DatabaseManager.updateMissionProgress(username, 0);
            
            if (playersWhoBetted.size() >= players.size() && !players.isEmpty()) {
                startNewGame();
            } else {
                message = "AȘTEPTĂM JUCĂTORII... (" + playersWhoBetted.size() + "/" + players.size() + ")";
            }
            ServerMain.broadcastGameState();
        }
    }
    
    public void startNewGame() {
        deck = new Deck();
        dealer.clearCards();
        for (Player p : players.values()) { p.clearCards(); p.setMessage(""); }
        gameOver = false;
        roundOrder = new ArrayList<>(playersWhoBetted);
        Collections.sort(roundOrder);
        currentPlayerIndex = 0; 

        if (roundOrder.isEmpty()) { gameOver = true; return; }

        for (int i = 0; i < 2; i++) {
            for (Integer id : roundOrder) {
                Player p = players.get(id);
                if (p != null) p.addCard(deck.drawCard());
            }
            dealer.addCard(deck.drawCard());
        }

        checkInitialBlackjack();
        
        Player firstP = players.get(roundOrder.get(currentPlayerIndex));
        if (firstP != null && firstP.getScore() >= 21) nextPlayerTurn();
        else message = "RÂNDUL LUI P" + getCurrentPlayerId();
        ServerMain.broadcastGameState();
    }

    private void checkInitialBlackjack() {
        for (Integer id : roundOrder) {
            Player p = players.get(id);
            if (p != null && p.getScore() == 21) {
                p.setMessage("BLACKJACK!");
                DatabaseManager.updateMissionProgress(ServerMain.getUserById(id), 2);
            }
        }
    }

    public void hit(int playerId) {
        Player p = players.get(playerId);
        if (gameOver || p == null || playerId != getCurrentPlayerId()) return;
        p.addCard(deck.drawCard());
        if (p.getScore() >= 21) {
            if(p.getScore() == 21) DatabaseManager.updateMissionProgress(ServerMain.getUserById(playerId), 2);
            nextPlayerTurn();
        } else ServerMain.broadcastGameState();
    }

    public void stand(int playerId) { if (playerId == getCurrentPlayerId() && !gameOver) nextPlayerTurn(); }

    private void nextPlayerTurn() {
        currentPlayerIndex++;
        if (currentPlayerIndex >= roundOrder.size()) dealerTurn();
        else {
            message = "RÂNDUL LUI P" + getCurrentPlayerId();
            Player nextP = players.get(roundOrder.get(currentPlayerIndex));
            if (nextP != null && nextP.getScore() >= 21) nextPlayerTurn();
            else ServerMain.broadcastGameState();
        }
    }

    private void dealerTurn() {
        while (dealer.getScore() < 17) dealer.addCard(deck.drawCard());
        gameOver = true;
        resolveResults();
        
        // REPARAȚIE: Resetăm pariurile pentru a preveni playerii dubli
        playersWhoBetted.clear(); 
        
        ServerMain.broadcastGameState();
        Timer t = new Timer(5000, e -> { 
            message = "PUNEȚI PARIURILE!"; 
            currentBets.clear();
            ServerMain.broadcastGameState();
        });
        t.setRepeats(false); t.start();
    }

    private void resolveResults() {
        int ds = dealer.getScore();
        for (Integer id : roundOrder) {
            Player p = players.get(id);
            if (p == null) continue;
            String user = ServerMain.getUserById(id);
            int ps = p.getScore();
            int bet = currentBets.getOrDefault(id, 0);

            if (p.getMessage().startsWith("BLACKJACK") || (ps <= 21 && (ds > 21 || ps > ds))) {
                p.setMessage("CÂȘTIGĂTOR");
                // REPARAȚIE: Profit dublu x2 trimis forțat la UI
                updateUserBalanceFinal(user, bet * 2);
                DatabaseManager.updateMissionProgress(user, 1);
            } else if (ds == ps) {
                p.setMessage("EGAL");
                updateUserBalanceFinal(user, bet); // Returnare pariu
            } else {
                p.setMessage(ps > 21 ? "BUST" : "PIERDUT");
            }
        }
    }

    private void updateUserBalanceFinal(String user, int amount) {
        String data = DatabaseManager.getUserData(user);
        if (data != null) {
            int current = Integer.parseInt(data.split("\\|")[3]);
            DatabaseManager.saveBalance(user, current + amount);
            for(ClientHandler h : ServerMain.handlers) {
                if(h.username.equals(user)) h.sendBalanceUpdate(current + amount);
            }
        }
    }

    public int getCurrentPlayerId() {
        if (roundOrder == null || roundOrder.isEmpty() || currentPlayerIndex < 0 || currentPlayerIndex >= roundOrder.size()) return -1;
        return roundOrder.get(currentPlayerIndex);
    }

    public GameState getGameStateForPlayer(int playerId) {
        Player p = players.get(playerId);
        List<String> dCards = new ArrayList<>(dealer.getCards());
        if (!gameOver && dCards.size() > 1) dCards.set(0, "card_back");
        Map<Integer, List<String>> allC = new HashMap<>();
        Map<Integer, Integer> allS = new HashMap<>();
        for (Map.Entry<Integer, Player> entry : players.entrySet()) {
            allC.put(entry.getKey(), entry.getValue().getCards());
            allS.put(entry.getKey(), entry.getValue().getScore());
        }
        // REPARAȚIE: Constructorul corect pentru GameState (image_6277c6)
        return new GameState(playerId, p != null ? p.getCards() : new ArrayList<>(), dCards, 
                            p != null ? p.getScore() : 0, gameOver ? dealer.getScore() : -1,
                            p != null && !p.getMessage().isEmpty() ? p.getMessage() : message, 
                            getCurrentPlayerId(), allC, allS);
    }
}