package server;
import java.util.*;

public class Deck {
    private List<String> cards = new ArrayList<>();

    public Deck() {
        // Numele rangurilor trebuie să fie EXACT ca în fișierele tale .png
        String[] suits = {"hearts", "diamonds", "clubs", "spades"};
        String[] ranks = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"};
        
        for (String s : suits) {
            for (String r : ranks) {
                // Generăm numele: ex "king_of_spades"
                cards.add(r + "_of_" + s);
            }
        }
        Collections.shuffle(cards);
    }

    public String drawCard() {
        return cards.isEmpty() ? "card_back" : cards.remove(0);
    }
}