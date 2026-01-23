package client;

import shared.*;
import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.io.*;
import java.net.Socket;
import java.util.*;
import java.util.List;

public class BlackjackGUI extends JPanel {
    private ObjectOutputStream out;
    private ObjectInputStream in;
    private GamePanel gamePanel;
    private JButton hitBtn, standBtn, betBtn, exitBtn;
    private JLabel statusLabel, balanceLabel;
    private JTextArea chatArea;
    private JTextField chatInput;
    private String playerUsername;
    private int balance;
    private int currentBetAmount = 0;
    private Map<String, Image> cardImages = new HashMap<>();
    private Image cardBack;
    private ClientApp parentApp;
    private String centerMessage = "PENTRU A ÎNCEPE APĂSAȚI BET";

    public BlackjackGUI(String username, ClientApp parentApp) {
        this.playerUsername = username;
        this.parentApp = parentApp;
        this.balance = Integer.parseInt(parentApp.getBalance());
        
        setLayout(new BorderLayout());
        setBackground(new Color(0, 40, 40));
        loadResources();

        // Mesajul de sus pentru CASTIGAT/PIERDUT/EGAL
        statusLabel = new JLabel(" ", SwingConstants.CENTER);
        statusLabel.setForeground(Color.CYAN);
        statusLabel.setFont(new Font("Serif", Font.BOLD, 32));
        add(statusLabel, BorderLayout.NORTH);

        JPanel leftPanel = new JPanel(new BorderLayout());
        leftPanel.setPreferredSize(new Dimension(250, 0));
        leftPanel.setBackground(new Color(0, 30, 30));
        leftPanel.setBorder(new TitledBorder(new LineBorder(Color.CYAN), "CASINO INFO", 0, 0, null, Color.CYAN));

        JPanel infoPanel = new JPanel(new GridLayout(2, 1, 5, 5));
        infoPanel.setOpaque(false);
        balanceLabel = new JLabel("BALANCE: $" + balance, SwingConstants.CENTER);
        balanceLabel.setForeground(Color.ORANGE);
        balanceLabel.setFont(new Font("Arial", Font.BOLD, 18));
        
        betBtn = new JButton("BET $100");
        betBtn.setBackground(new Color(0, 100, 100));
        betBtn.setForeground(Color.WHITE);
        betBtn.addActionListener(e -> {
            if(balance >= 100) {
                currentBetAmount = 100;
                balance -= 100;
                balanceLabel.setText("BALANCE: $" + balance);
                parentApp.setBalance(String.valueOf(balance)); 
                centerMessage = "AȘTEPTĂM JUCĂTORII...";
                sendAction("BET|100");
                repaint();
            } else {
                centerMessage = "MIJLOACE INSUFICIENTE!";
                repaint();
            }
        });

        infoPanel.add(balanceLabel);
        infoPanel.add(betBtn);
        leftPanel.add(infoPanel, BorderLayout.NORTH);

        chatArea = new JTextArea();
        chatArea.setEditable(false);
        chatArea.setBackground(new Color(0, 20, 20));
        chatArea.setForeground(Color.GREEN);
        chatArea.setLineWrap(true);
        // FIX: Scroll automat la ultimul mesaj
        chatArea.setAutoscrolls(true);
        leftPanel.add(new JScrollPane(chatArea), BorderLayout.CENTER);

        chatInput = new JTextField();
        chatInput.addActionListener(e -> { 
            if(!chatInput.getText().trim().isEmpty()){
                // FIX: Trimitere chat directă
                sendAction("CHAT|" + chatInput.getText()); 
                chatInput.setText(""); 
            }
        });
        leftPanel.add(chatInput, BorderLayout.SOUTH);
        add(leftPanel, BorderLayout.WEST);

        gamePanel = new GamePanel();
        add(gamePanel, BorderLayout.CENTER);

        // FIX: GridLayout pentru distribuție uniformă pe toată lățimea
        JPanel btns = new JPanel(new GridLayout(1, 3, 20, 10));
        btns.setBackground(new Color(0, 20, 20));
        hitBtn = createBtn("HIT");
        standBtn = createBtn("STAND");
        exitBtn = createBtn("IEȘIRE LOBBY");
        exitBtn.setBackground(new Color(150, 0, 0));

        hitBtn.addActionListener(e -> sendAction("HIT"));
        standBtn.addActionListener(e -> sendAction("STAND"));
        exitBtn.addActionListener(e -> {
            sendAction("LEAVE_GAME");
            parentApp.showLobby();
        });

        btns.add(hitBtn); btns.add(standBtn); btns.add(exitBtn);
        add(btns, BorderLayout.SOUTH);
    }

    private void loadResources() {
        try {
            String path = "client/resources/cards/";
            cardBack = new ImageIcon(path + "card_back.png").getImage();
            String[] suits = {"hearts", "diamonds", "clubs", "spades"};
            String[] ranks = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"};
            for (String s : suits) {
                for (String r : ranks) {
                    String name = r + "_of_" + s;
                    cardImages.put(name, new ImageIcon(path + name + ".png").getImage());
                }
            }
        } catch (Exception e) {}
    }

    private JButton createBtn(String t) {
        JButton b = new JButton(t);
        b.setBackground(new Color(0, 120, 120));
        b.setForeground(Color.WHITE);
        b.setBorder(new LineBorder(Color.CYAN));
        b.setPreferredSize(new Dimension(150, 40));
        return b;
    }

    public void connectToServer() {
        new Thread(() -> {
            try {
                Socket s = new Socket("localhost", 5000);
                out = new ObjectOutputStream(s.getOutputStream());
                in = new ObjectInputStream(s.getInputStream());
                out.writeObject(new Message("JOIN_GAME", playerUsername));
                out.flush();
                while (true) {
                    Object obj = in.readObject();
                    if (obj instanceof Message msg) {
                        if (msg.getType().equals("GAME_STATE")) {
                            GameState st = (GameState) msg.getData();
                            SwingUtilities.invokeLater(() -> updateUI(st));
                        } else if (msg.getType().equals("CHAT_MSG")) {
                            // FIX: Afișare chat cu scroll automat
                            chatArea.append((String)msg.getData() + "\n");
                            chatArea.setCaretPosition(chatArea.getDocument().getLength());
                        } else if (msg.getType().equals("UPDATE_BALANCE")) {
                            // FIX: Actualizare balanță de la server
                            int newBalance = Integer.parseInt((String)msg.getData());
                            balance = newBalance;
                            parentApp.setBalance(String.valueOf(balance));
                            SwingUtilities.invokeLater(() -> {
                                balanceLabel.setText("BALANCE: $" + balance);
                                parentApp.updateGlobalBalance(balance);
                            });
                        }
                    }
                }
            } catch (Exception e) {}
        }).start();
    }

    private void updateUI(GameState state) {
        gamePanel.update(state);
        String m = state.getMessage();
        
        // GESTIUNE MESAJE STATUS ȘI CENTRAL
        if (state.getCurrentPlayerId() != -1) {
            // Joc activ
            centerMessage = ""; 
            statusLabel.setText(m.toUpperCase());
        } else {
            // Runda e gata sau se așteaptă pariuri
            if(m.contains("CÂȘTIGĂTOR") || m.contains("PIERDUT") || m.contains("EGAL") || m.contains("BJ") || m.contains("BUST")) {
                statusLabel.setText(m.toUpperCase());
                centerMessage = "RUNDĂ FINALIZATĂ";
                currentBetAmount = 0; // Permitem pariu nou runda viitoare
            } else {
                statusLabel.setText(" ");
                // Păstrăm timer-ul în centru dacă există în mesajul serverului
                if(m.contains("(")) centerMessage = m; 
                else if(currentBetAmount == 0) centerMessage = "PENTRU A ÎNCEPE APĂSAȚI BET";
            }
        }

        // PLATA CASTIGURI - Balanța se actualizează de la server prin UPDATE_BALANCE
        // Doar resetăm currentBetAmount aici, serverul se ocupă de actualizarea balanței
        if (m.contains("CÂȘTIGĂTOR") || m.contains("EGAL") || m.contains("PIERDUT") || m.contains("BUST")) {
            currentBetAmount = 0;
        }

        // Activare butoane în funcție de rând
        boolean myTurn = (state.getCurrentPlayerId() == state.getMyPlayerId() && state.getCurrentPlayerId() != -1);
        hitBtn.setEnabled(myTurn);
        standBtn.setEnabled(myTurn);
        // Butonul BET e activ doar dacă nu ai pariat deja și nu se joacă runda
        betBtn.setEnabled(state.getCurrentPlayerId() == -1 && currentBetAmount == 0);
    }

    private void sendAction(String act) {
        try { 
            out.reset(); 
            out.writeObject(new Message("ACTION", act)); 
            out.flush(); 
        } catch (Exception e) {}
    }

    class GamePanel extends JPanel {
        private GameState state;
        public GamePanel() { setOpaque(false); }
        public void update(GameState s) { this.state = s; repaint(); }

        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            Graphics2D g2 = (Graphics2D) g;
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            int w = getWidth(), h = getHeight();

            // DESENARE MASA
            g2.setColor(new Color(0, 100, 0));
            g2.fillOval(w/10, h/6, (int)(w*0.8), (int)(h*0.7));
            g2.setColor(new Color(212, 175, 55));
            g2.setStroke(new BasicStroke(4));
            g2.drawOval(w/10, h/6, (int)(w*0.8), (int)(h*0.7));

            // MESAJ CENTRAL (Timer / Apăsați Bet)
            if (centerMessage != null && !centerMessage.isEmpty()) {
                g2.setFont(new Font("Arial", Font.BOLD, 26));
                g2.setColor(Color.YELLOW);
                FontMetrics fm = g2.getFontMetrics();
                g2.drawString(centerMessage, (w - fm.stringWidth(centerMessage)) / 2, h / 2);
            }

            if (state == null) return;

            // FIX: Calculează centrul mesei pentru poziționare corectă
            int tableCenterX = w / 2;
            int tableLeft = w / 10;
            int tableRight = tableLeft + (int)(w * 0.8);
            int tableWidth = tableRight - tableLeft;

            // DEALER - centrat pe masă
            if (state.getDealerCards() != null && !state.getDealerCards().isEmpty()) {
                String dScore = (state.getCurrentPlayerId() == -1) ? String.valueOf(state.getDealerScore()) : "?";
                drawHand(g2, state.getDealerCards(), tableCenterX, h/4, "DEALER: " + dScore);
            }

            // JUCĂTORI CU SCORURI - distribuiți uniform pe masă
            Map<Integer, List<String>> allCards = state.getAllPlayersCards();
            Map<Integer, Integer> scores = state.getAllPlayersScores();
            int total = allCards.size(), index = 0;
            
            for (Integer id : allCards.keySet()) {
                List<String> cards = allCards.get(id);
                if (cards == null || cards.isEmpty()) { index++; continue; }

                // FIX: Distribuie jucătorii uniform pe lățimea mesei, nu pe toată lățimea ecranului
                int sc = scores.getOrDefault(id, 0);
                // Evidențiere nume jucător (TU vs PlayerID)
                String label = (id == state.getMyPlayerId() ? "TU: " : "P"+id + ": ") + sc;
                
                // Calculează poziția X centrată pe masă
                int playerX;
                if (total == 1) {
                    playerX = tableCenterX; // Un singur jucător - centrat
                } else {
                    // Distribuie uniform pe masă
                    float ratio = (float)(index + 1) / (total + 1);
                    playerX = tableLeft + (int)(tableWidth * ratio);
                }
                
                drawHand(g2, cards, playerX, (int)(h*0.65), label);
                index++;
            }
        }

        private void drawHand(Graphics2D g2, List<String> cards, int x, int y, String label) {
            g2.setColor(Color.WHITE);
            g2.setFont(new Font("Arial", Font.BOLD, 14));
            g2.drawString(label, x, y - 10);
            if (cards == null) return;
            
            // FIX: Calculează dimensiunile cărții și offset-ul pentru a nu ieși din masă
            int cardWidth = 70;
            int cardHeight = 100;
            int cardSpacing = 25;
            int maxCards = cards.size();
            int panelWidth = getWidth();
            
            // FIX: Calculează poziția de start astfel încât cărțile să fie centrate și să nu iasă din masă
            int totalWidth = (maxCards - 1) * cardSpacing + cardWidth;
            int startX = x - totalWidth / 2; // Centrează cărțile
            
            // FIX: Verifică limitele mesei (ovalul este la w/10, h/6 cu dimensiuni w*0.8, h*0.7)
            int tableLeft = panelWidth / 10;
            int tableRight = tableLeft + (int)(panelWidth * 0.8);
            if (startX < tableLeft) startX = tableLeft;
            if (startX + totalWidth > tableRight) startX = Math.max(tableLeft, tableRight - totalWidth);
            
            for (int i = 0; i < cards.size(); i++) {
                String c = cards.get(i).toLowerCase();
                Image img = c.equals("card_back") ? cardBack : cardImages.get(c);
                if (img != null) {
                    int cardX = startX + i * cardSpacing;
                    g2.drawImage(img, cardX, y, cardWidth, cardHeight, null);
                }
            }
        }
    }
}