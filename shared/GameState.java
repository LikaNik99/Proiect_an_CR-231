package shared;
import java.io.Serializable;
import java.util.*;

public class GameState implements Serializable {
    private int myPlayerId;
    private List<String> myCards;
    private List<String> dealerCards;
    private int myScore;
    private int dealerScore;
    private String message;
    private int currentPlayerId;
    
    // NOU: Mapă cu toți ceilalți jucători (ID -> Cărți) pentru a-i vedea la masă
    private Map<Integer, List<String>> allPlayersCards;
    private Map<Integer, Integer> allPlayersScores;

    public GameState(int myId, List<String> myCards, List<String> dealerCards, int myScore, 
                     int dScore, String msg, int currId, Map<Integer, List<String>> allCards, Map<Integer, Integer> allScores) {
        this.myPlayerId = myId;
        this.myCards = myCards;
        this.dealerCards = dealerCards;
        this.myScore = myScore;
        this.dealerScore = dScore;
        this.message = msg;
        this.currentPlayerId = currId;
        this.allPlayersCards = allCards;
        this.allPlayersScores = allScores;
    }

    public int getMyPlayerId() { return myPlayerId; }
    public List<String> getPlayerCards() { return myCards; }
    public List<String> getDealerCards() { return dealerCards; }
    public int getPlayerScore() { return myScore; }
    public int getDealerScore() { return dealerScore; }
    public String getMessage() { return message; }
    public int getCurrentPlayerId() { return currentPlayerId; }
    public Map<Integer, List<String>> getAllPlayersCards() { return allPlayersCards; }
    public Map<Integer, Integer> getAllPlayersScores() { return allPlayersScores; }
}