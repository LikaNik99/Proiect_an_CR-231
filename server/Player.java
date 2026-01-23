package server;
import java.util.*;

public class Player {
    private List<String> cards = new ArrayList<>();
    private int score = 0;
    private String message = "";
    private boolean standing = false;
    private boolean gameOver = false;

    public Player(boolean isDealer) {}

    public void addCard(String card) {
        cards.add(card);
        calculateScore(); // Calculăm scorul la fiecare carte primită!
    }

    private void calculateScore() {
        score = 0;
        int aces = 0;
        for (String c : cards) {
            String rank = c.split("_")[0].toLowerCase();
            if (rank.equals("ace")) {
                aces++;
                score += 11;
            } else if (rank.equals("jack") || rank.equals("queen") || rank.equals("king") || rank.equals("10")) {
                score += 10;
            } else {
                try {
                    score += Integer.parseInt(rank);
                } catch (Exception e) {
                    score += 10;
                }
            }
        }
        while (score > 21 && aces > 0) {
            score -= 10;
            aces--;
        }
    }

    public List<String> getCards() { return cards; }
    public int getScore() { return score; }
    public void clearCards() { cards.clear(); score = 0; standing = false; gameOver = false; message = ""; }
    public void stand() { this.standing = true; }
    public boolean isStanding() { return standing; }
    public void setGameOver(boolean b) { this.gameOver = b; }
    public boolean isGameOver() { return gameOver; }
    public void setMessage(String m) { this.message = m; }
    public String getMessage() { return message; }
}