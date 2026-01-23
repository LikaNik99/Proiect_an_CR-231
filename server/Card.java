package server;

public class Card {

    private String rank;
    private String suit;

    public Card(String rank, String suit) {
        this.rank = rank;
        this.suit = suit;
    }

    public String getRank() { return rank; }
    public String getSuit() { return suit; }

    public int getValue() {
        switch (rank) {
            case "J": case "Q": case "K": return 10;
            case "A": return 11;
            default:
                try { return Integer.parseInt(rank); }
                catch (Exception e) { return 0; }
        }
    }

    @Override
public String toString() {
    return rank.toLowerCase() + "_of_" + suit.toLowerCase();
}
}
