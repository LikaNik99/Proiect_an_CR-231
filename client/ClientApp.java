package client;

import javax.swing.*;
import java.awt.*;
import java.io.*;
import java.net.Socket;
import java.util.List;
import shared.Message;

public class ClientApp extends JFrame {
    private CardLayout cardLayout = new CardLayout();
    private JPanel mainPanel = new JPanel(cardLayout);
    private LoginPanel loginPanel;
    private LobbyPanel lobbyPanel;
    private RegisterPanel registerPanel;
    private MissionsPanel missionsPanel; 
    private FriendsPanel friendsPanel;
    private AdminPanel adminPanel; // FIX: Panel pentru admin
    private ObjectOutputStream out;
    private ObjectInputStream in;
    private String username, balance = "0", regDate = "N/A";
    private boolean isAdmin = false; // FIX: Flag pentru admin
    
    // REPARAȚIE: Adăugat pentru gestionarea ferestrei Messenger
    private MessengerWindow currentChat;

    public ClientApp(String host, int port) {
        setTitle("ROYAL BLACKJACK");
        setSize(1100, 750);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        
        // Inițializăm panourile
        loginPanel = new LoginPanel(this);
        lobbyPanel = new LobbyPanel(this);
        registerPanel = new RegisterPanel(this);
        missionsPanel = new MissionsPanel(this);
        friendsPanel = new FriendsPanel(this);
        adminPanel = new AdminPanel(this); // FIX: Panel pentru admin
        
        // Le adăugăm în ordinea corectă în CardLayout
        mainPanel.add(loginPanel, "Login");
        mainPanel.add(registerPanel, "Register");
        mainPanel.add(lobbyPanel, "Lobby");
        mainPanel.add(missionsPanel, "Missions");
        mainPanel.add(friendsPanel, "Friends");
        mainPanel.add(adminPanel, "Admin");
        
        add(mainPanel);
        connect(host, port);
        cardLayout.show(mainPanel, "Login");
    }

    private void connect(String h, int p) {
        try {
            Socket s = new Socket(h, p);
            out = new ObjectOutputStream(s.getOutputStream());
            in = new ObjectInputStream(s.getInputStream());
            new Thread(this::listen).start();
        } catch (Exception e) { 
            System.err.println("Eroare: Serverul este offline."); 
        }
    }

    // REPARAȚIE: Metoda cerută de FriendsPanel (image_3f9a45.png)
    public void openChatWith(String friend) {
        if (currentChat != null) currentChat.dispose();
        currentChat = new MessengerWindow(friend, this);
        currentChat.setVisible(true);
        sendNetworkMessage("GET_CHAT_HISTORY", friend);
    }

    public void sendNetworkMessage(String type, String data) {
        try { 
            out.reset(); 
            out.writeObject(new Message(type, data)); 
            out.flush(); 
        } catch (Exception e) {
            System.err.println("Eroare la trimitere mesaj: " + type);
        }
    }

    @SuppressWarnings("unchecked")
    private void listen() {
        try {
            while (true) {
                Object obj = in.readObject();
                if (obj instanceof Message msg) {
                    String type = msg.getType();
                    
                    if (type.equals("LOGIN_SUCCESS")) {
                        String[] p = ((String)msg.getData()).split("\\|");
                        this.username = p[1]; 
                        this.balance = p[2];
                        this.regDate = (p.length > 3) ? p[3] : "N/A";
                        // FIX: Verifică dacă utilizatorul este admin
                        this.isAdmin = username != null && username.equalsIgnoreCase("admin");
                        
                        SwingUtilities.invokeLater(() -> {
                            lobbyPanel.setUsername(username);
                            lobbyPanel.updateBalanceDisplay(balance);
                            lobbyPanel.setAdminMode(isAdmin); // FIX: Setează modul admin în lobby
                            cardLayout.show(mainPanel, "Lobby");
                        });
                    } else if (type.equals("LOGIN_FAIL")) {
                        // FIX: Afișează mesaj de eroare la login eșuat
                        String errorMsg = (String) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            if (errorMsg != null && !errorMsg.isEmpty()) {
                                JOptionPane.showMessageDialog(this, errorMsg, "Eroare Login", JOptionPane.ERROR_MESSAGE);
                            } else {
                                JOptionPane.showMessageDialog(this, "Username sau parolă incorectă!", "Eroare Login", JOptionPane.ERROR_MESSAGE);
                            }
                        });
                    } else if (type.equals("REG_RESULT")) {
                        String res = (String) msg.getData();
                        if (res.equals("SUCCESS")) {
                            JOptionPane.showMessageDialog(this, "Cont creat cu succes!");
                            showLogin();
                        } else if (res.equals("EXIST")) {
                            JOptionPane.showMessageDialog(this, "Utilizatorul există deja!");
                        } else {
                            JOptionPane.showMessageDialog(this, "Eroare la înregistrare! Verifică datele introduse.");
                        }
                    } else if (type.equals("TABLE_LIST")) {
                        lobbyPanel.updateTableList((List<String>) msg.getData());
                    } else if (type.equals("UPDATE_BALANCE")) {
                        this.balance = (String) msg.getData();
                        SwingUtilities.invokeLater(() -> lobbyPanel.updateBalanceDisplay(this.balance));
                    } else if (type.equals("REWARD_OK")) {
                        // FIX: Nu mai adăugăm 1000 aici, serverul deja a actualizat balanța prin UPDATE_BALANCE
                        // Balanța este deja actualizată în handler-ul UPDATE_BALANCE
                        JOptionPane.showMessageDialog(this, "Ai primit bonusul zilnic de $1000!");
                    } else if (type.equals("REWARD_FAIL")) {
                        JOptionPane.showMessageDialog(this, msg.getData());
                    } else if (type.equals("ADMIN_USERS_LIST")) {
                        // FIX: Handler pentru lista de utilizatori în admin panel
                        List<String> users = (List<String>) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            adminPanel.updateUsers(users);
                        });
                    } else if (type.equals("ADMIN_TABLES_LIST")) {
                        // FIX: Handler pentru lista de mese în admin panel
                        List<String> tables = (List<String>) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            adminPanel.updateTables(tables);
                        });
                    } else if (type.equals("ADMIN_ACTION_RESULT")) {
                        // FIX: Handler pentru rezultatele acțiunilor admin
                        JOptionPane.showMessageDialog(this, msg.getData());
                        // Reîmprospătează listele după acțiune
                        if (isAdmin) {
                            sendNetworkMessage("ADMIN_GET_USERS", "");
                            sendNetworkMessage("ADMIN_GET_TABLES", "");
                            sendNetworkMessage("ADMIN_GET_STATS", "");
                            sendNetworkMessage("ADMIN_GET_ONLINE_USERS", "");
                        }
                    } else if (type.equals("ADMIN_STATS")) {
                        String stats = (String) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            adminPanel.updateStats(stats);
                        });
                    } else if (type.equals("ADMIN_ONLINE_USERS")) {
                        List<String> onlineUsers = (List<String>) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            adminPanel.updateOnlineUsers(onlineUsers);
                        });
                    } else if (type.equals("ADMIN_HISTORY")) {
                        List<String> history = (List<String>) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            adminPanel.showHistoryDialog(history);
                        });
                    } else if (type.equals("MISSIONS_LIST")) {
                        List<String> missions = (List<String>) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            missionsPanel.updateMissions(missions);
                            cardLayout.show(mainPanel, "Missions");
                        });
                    } else if (type.equals("PROFILE_DATA")) {
                        String[] p = ((String)msg.getData()).split("\\|");
                        
                        // REPARAȚIE: Curățarea datei (image_db9b64.png)
                        String cleanDate = p[2];
                        if (cleanDate.length() > 16) {
                            cleanDate = cleanDate.substring(0, 16).replace("T", " ");
                        }

                        String info = "<html><body style='width:220px; font-family:Arial;'>" +
                                      "<h2>PROFIL JUCĂTOR</h2><hr>" +
                                      "<b>USER:</b> " + p[0] + "<br>" +
                                      "<b>BALANȚĂ:</b> <span style='color:green;'>$" + p[1] + "</span><br>" +
                                      "<b>MEMBRU DIN:</b> " + cleanDate + "<br>" +
                                      "<b>PRIETENI:</b> " + p[3] + "</body></html>";
                        
                        // REPARAȚIE: Buton Logout lângă OK
                        SwingUtilities.invokeLater(() -> {
                            Object[] options = {"OK", "LOGOUT"};
                            int choice = JOptionPane.showOptionDialog(this, info, "Info Profil", 
                                         JOptionPane.DEFAULT_OPTION, JOptionPane.PLAIN_MESSAGE, null, options, options[0]);
                            
                            if (choice == 1) { // Utilizatorul a apăsat LOGOUT
                                showLogin();
                                this.username = null;
                                this.balance = "0";
                            }
                        });
                    } else if (type.equals("FRIENDS_LIST")) {
                        List<String> friends = (List<String>) msg.getData();
                        SwingUtilities.invokeLater(() -> {
                            friendsPanel.updateFriends(friends);
                            cardLayout.show(mainPanel, "Friends");
                        });
                    } else if (type.equals("PRIVATE_CHAT_UPDATE")) {
                        // REPARAȚIE: Primirea mesajelor pentru Messenger
                        if (currentChat != null) {
                            currentChat.updateChat((List<String>) msg.getData());
                        }
                    } else if (type.equals("FRIEND_REQUESTS_LIST")) {
                        List<String> r = (List<String>) msg.getData();
                        if (r.isEmpty()) {
                            JOptionPane.showMessageDialog(this, "Nu ai cereri noi.");
                        } else {
                            String f = (String) JOptionPane.showInputDialog(this, "Alege cererea:", "CERERI", 
                                       JOptionPane.QUESTION_MESSAGE, null, r.toArray(), r.get(0));
                            if (f != null) sendNetworkMessage("ACCEPT_FRIEND", f);
                        }
                    }
                }
            }
        } catch (Exception e) {}
    }

    public void updateGlobalBalance(int newBal) {
        this.balance = String.valueOf(newBal);
        lobbyPanel.updateBalanceDisplay(this.balance);
        sendNetworkMessage("SAVE_BALANCE", this.balance);
    }

    public void showGame() {
        BlackjackGUI gameUI = new BlackjackGUI(this.username, this); 
        mainPanel.add(gameUI, "Game");
        cardLayout.show(mainPanel, "Game");
        gameUI.connectToServer();
    }

    public void showLobby() { 
        cardLayout.show(mainPanel, "Lobby"); 
        sendNetworkMessage("GET_TABLES", ""); 
    }
    
    public void showFriends() { 
        sendNetworkMessage("GET_FRIENDS", ""); 
    }
    
    public void showAdmin() {
        if (isAdmin) {
            sendNetworkMessage("ADMIN_GET_USERS", "");
            sendNetworkMessage("ADMIN_GET_TABLES", "");
            sendNetworkMessage("ADMIN_GET_STATS", "");
            sendNetworkMessage("ADMIN_GET_ONLINE_USERS", "");
            cardLayout.show(mainPanel, "Admin");
        }
    }
    
    public void showRegister() { 
        cardLayout.show(mainPanel, "Register"); 
    }
    
    public void showLogin() { 
        cardLayout.show(mainPanel, "Login"); 
    }
    
    public boolean isAdmin() {
        return isAdmin;
    }
    
    public String getCurrentUsername() { return username; }
    public String getBalance() { return balance; }
    public void setBalance(String b) { this.balance = b; }
    public String getRegDate() { return regDate; }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new ClientApp("localhost", 5000).setVisible(true));
    }
}