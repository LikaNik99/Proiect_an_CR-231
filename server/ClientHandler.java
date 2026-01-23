package server;

import java.io.*;
import java.net.Socket;
import shared.Message;
import java.util.List;

public class ClientHandler extends Thread {
    private Socket socket;
    private ObjectOutputStream out;
    private ObjectInputStream in;
    private GameLogic game;
    private int authenticatedUserId = -1;
    public String username = ""; 

    public ClientHandler(Socket socket, GameLogic game) {
        this.socket = socket;
        this.game = game;
    }

    @Override
    public void run() {
        try {
            out = new ObjectOutputStream(socket.getOutputStream());
            in = new ObjectInputStream(socket.getInputStream());
            while (true) {
                Object obj = in.readObject();
                if (obj instanceof Message msg) handleMessage(msg);
            }
        } catch (Exception e) {
            ServerMain.removeHandler(this);
            if (authenticatedUserId != -1) game.removePlayer(authenticatedUserId);
        }
    }

    private void handleMessage(Message msg) throws IOException {
        String type = msg.getType();
        Object data = msg.getData();

        if (type.equals("LOGIN")) {
            String[] loginData = ((String)data).split("\\|");
            if (loginData.length < 2) {
                out.reset(); out.writeObject(new Message("LOGIN_FAIL", "Date incomplete! Completează username și parolă.")); out.flush();
                return;
            }
            String usernameAttempt = loginData[0].trim();
            String passwordAttempt = loginData[1].trim();
            
            if (usernameAttempt.isEmpty() || passwordAttempt.isEmpty()) {
                out.reset(); out.writeObject(new Message("LOGIN_FAIL", "Username și parolă nu pot fi goale!")); out.flush();
                return;
            }
            
            if (DatabaseManager.isBanned(usernameAttempt)) {
                out.reset(); out.writeObject(new Message("LOGIN_FAIL", "Contul tău a fost banat!")); out.flush();
                return;
            }
            
            String res = DatabaseManager.loginUser(usernameAttempt, passwordAttempt);
            if (res.startsWith("SUCCESS")) {
                this.username = res.split("\\|")[1];
                out.reset(); out.writeObject(new Message("LOGIN_SUCCESS", res)); out.flush();
                ServerMain.broadcastTableList();
            } else {
                // FIX: Mesaj de eroare mai clar
                out.reset(); out.writeObject(new Message("LOGIN_FAIL", "Username sau parolă incorectă!")); out.flush();
            }
        } else if (type.equals("REGISTER")) {
            // FIX: Handler pentru înregistrare
            String[] parts = ((String)data).split("\\|");
            if (parts.length >= 3) {
                String res = DatabaseManager.registerUser(parts[0], parts[1], parts[2]);
                out.reset(); 
                out.writeObject(new Message("REG_RESULT", res)); 
                out.flush();
            } else {
                out.reset(); 
                out.writeObject(new Message("REG_RESULT", "ERROR")); 
                out.flush();
            }
        } else if (type.equals("CREATE_TABLE")) {
            String[] p = ((String)data).split("\\|");
            DatabaseManager.createTable(p[0], p[1]);
            ServerMain.broadcastTableList(); 
        } else if (type.equals("JOIN_GAME")) {
            // FIX: Setează username pe handler dacă e gol (pentru conexiuni BlackjackGUI)
            String providedUsername = null;
            if (this.username.isEmpty() && data instanceof String) {
                providedUsername = (String) data;
                // Verifică dacă username-ul există în baza de date
                if (DatabaseManager.getUserData(providedUsername) != null) {
                    this.username = providedUsername;
                }
            } else if (!this.username.isEmpty()) {
                providedUsername = this.username;
            }
            
            // FIX: Elimină jucătorul vechi dacă utilizatorul are deja un jucător în joc
            if (providedUsername != null && this.authenticatedUserId == -1) {
                synchronized (ServerMain.handlers) {
                    for (ClientHandler h : ServerMain.handlers) {
                        if (h != this && h.username.equals(providedUsername) && h.authenticatedUserId != -1) {
                            // Utilizatorul are deja un jucător în joc, eliminăm-l
                            game.removePlayer(h.authenticatedUserId);
                            h.authenticatedUserId = -1;
                        }
                    }
                }
            }
            
            // FIX: Verifică dacă jucătorul nu este deja în joc
            if (this.authenticatedUserId == -1) {
                this.authenticatedUserId = game.addPlayer();
            }
            ServerMain.broadcastGameState(); 
            ServerMain.broadcastTableList();
        } else if (type.equals("LEAVE_GAME")) {
            // FIX: Gestionare corectă a ieșirii jucătorului
            if (this.authenticatedUserId != -1) {
                game.removePlayer(this.authenticatedUserId);
                this.authenticatedUserId = -1;
                ServerMain.broadcastGameState();
                ServerMain.broadcastTableList();
            } 
        } else if (type.equals("DAILY_REWARD")) {
            String res = DatabaseManager.claimDaily(username);
            if (res.equals("OK")) {
                String bal = DatabaseManager.getUserData(username).split("\\|")[3];
                sendBalanceUpdate(Integer.parseInt(bal)); 
                out.reset(); out.writeObject(new Message("REWARD_OK", "1000"));
            } else {
                out.reset(); out.writeObject(new Message("REWARD_FAIL", "Deja luat!"));
            }
            out.flush();
        } else if (type.equals("GET_MISSIONS")) {
            out.reset(); out.writeObject(new Message("MISSIONS_LIST", DatabaseManager.getMissions(username))); out.flush();
        } else if (type.equals("CLAIM_MISSION")) {
            int rew = DatabaseManager.claimMission(username, Integer.parseInt((String)data));
            if (rew > 0) {
                String bal = DatabaseManager.getUserData(username).split("\\|")[3];
                sendBalanceUpdate(Integer.parseInt(bal));
                handleMessage(new Message("GET_MISSIONS", "")); 
            }
        } else if (type.equals("ACTION")) {
            String act = (String) data;
            if (act.startsWith("CHAT|")) {
                // REPARAȚIE: Numele apare corect în chat
                ServerMain.broadcastChat("[" + username + "]: " + act.substring(5));
            } else if (act.startsWith("BET|")) {
                game.placeBet(authenticatedUserId, Integer.parseInt(act.split("\\|")[1]));
            } else if (act.equals("LEAVE_GAME")) {
                // FIX: Procesare LEAVE_GAME prin ACTION
                if (this.authenticatedUserId != -1) {
                    game.removePlayer(this.authenticatedUserId);
                    this.authenticatedUserId = -1;
                    ServerMain.broadcastGameState();
                    ServerMain.broadcastTableList();
                }
            } else {
                if (act.equals("HIT")) game.hit(authenticatedUserId);
                else if (act.equals("STAND")) game.stand(authenticatedUserId);
                ServerMain.broadcastGameState();
            }
        } else if (type.equals("GET_PROFILE_INFO")) {
            String d = DatabaseManager.getUserData(username);
            if (d != null) {
                String[] p = d.split("\\|");
                List<String> friends = DatabaseManager.getFriends(username);
                String info = p[0] + "|" + p[3] + "|" + p[4] + "|" + friends.size();
                out.reset(); out.writeObject(new Message("PROFILE_DATA", info)); out.flush();
            }
        } else if (type.equals("GET_FRIENDS")) {
            out.reset(); out.writeObject(new Message("FRIENDS_LIST", DatabaseManager.getFriends(username))); out.flush();
        } else if (type.equals("PRIVATE_MSG")) {
            String[] p = ((String)data).split("\\|", 2);
            DatabaseManager.savePrivateMessage(username, p[0], p[1]);
            List<String> hist = DatabaseManager.getChatHistory(username, p[0]);
            for(ClientHandler h : ServerMain.handlers) {
                if(h.username.equals(p[0]) || h.username.equals(username)) {
                    h.out.reset(); h.out.writeObject(new Message("PRIVATE_CHAT_UPDATE", hist)); h.out.flush();
                }
            }
        } else if (type.equals("GET_CHAT_HISTORY")) {
            out.reset(); out.writeObject(new Message("PRIVATE_CHAT_UPDATE", DatabaseManager.getChatHistory(username, (String)data))); out.flush();
        } else if (type.equals("SEND_FRIEND_REQUEST")) {
            DatabaseManager.addFriendRequest((String)data, username);
        } else if (type.equals("GET_FRIEND_REQUESTS")) {
            out.reset(); out.writeObject(new Message("FRIEND_REQUESTS_LIST", DatabaseManager.getFriendRequests(username))); out.flush();
        } else if (type.equals("ACCEPT_FRIEND")) {
            DatabaseManager.acceptFriend(username, (String)data);
            handleMessage(new Message("GET_FRIENDS", ""));
        } else if (type.equals("SAVE_BALANCE")) {
            DatabaseManager.saveBalance(username, Integer.parseInt((String)data));
        } else if (type.equals("GET_TABLES")) {
            sendTableList();
        } else if (type.equals("ADMIN_GET_USERS")) {
            // FIX: Handler pentru admin - obține toți utilizatorii
            if (DatabaseManager.isAdmin(username)) {
                out.reset(); 
                out.writeObject(new Message("ADMIN_USERS_LIST", DatabaseManager.getAllUsers())); 
                out.flush();
            }
        } else if (type.equals("ADMIN_GET_TABLES")) {
            // FIX: Handler pentru admin - obține toate mesele
            if (DatabaseManager.isAdmin(username)) {
                out.reset(); 
                out.writeObject(new Message("ADMIN_TABLES_LIST", DatabaseManager.getTables())); 
                out.flush();
            }
        } else if (type.equals("ADMIN_CREATE_TABLE")) {
            if (DatabaseManager.isAdmin(username)) {
                String[] parts = ((String)data).split("\\|");
                if (parts.length >= 2) {
                    DatabaseManager.createTable(parts[0], parts[1]);
                    DatabaseManager.logAdminAction("CREATE_TABLE", parts[0], "Masă creată cu min bet: " + parts[1]);
                    out.reset();
                    out.writeObject(new Message("ADMIN_ACTION_RESULT", "Masă creată cu succes!"));
                    out.flush();
                }
            }
        } else if (type.equals("ADMIN_DELETE_USER")) {
            // FIX: Handler pentru admin - șterge utilizator
            if (DatabaseManager.isAdmin(username)) {
                boolean deleted = DatabaseManager.deleteUser((String)data);
                if (deleted) {
                    DatabaseManager.logAdminAction("DELETE_USER", (String)data, "Utilizator șters");
                }
                out.reset(); 
                out.writeObject(new Message("ADMIN_ACTION_RESULT", deleted ? "Utilizator șters cu succes!" : "Eroare la ștergere!")); 
                out.flush();
            }
        } else if (type.equals("ADMIN_GET_STATS")) {
            if (DatabaseManager.isAdmin(username)) {
                String stats = DatabaseManager.getPlayerStatistics();
                out.reset();
                out.writeObject(new Message("ADMIN_STATS", stats));
                out.flush();
            }
        } else if (type.equals("ADMIN_GET_ONLINE_USERS")) {
            if (DatabaseManager.isAdmin(username)) {
                List<String> online = DatabaseManager.getOnlineUsers();
                out.reset();
                out.writeObject(new Message("ADMIN_ONLINE_USERS", online));
                out.flush();
            }
        } else if (type.equals("ADMIN_BAN_USER")) {
            if (DatabaseManager.isAdmin(username)) {
                DatabaseManager.banUser((String)data);
                out.reset(); 
                out.writeObject(new Message("ADMIN_ACTION_RESULT", "Utilizator " + data + " a fost banat!")); 
                out.flush();
            }
        } else if (type.equals("ADMIN_UPDATE_BALANCE")) {
            if (DatabaseManager.isAdmin(username)) {
                String[] parts = ((String)data).split("\\|");
                if (parts.length == 2) {
                    String targetUser = parts[0];
                    int newBalance = Integer.parseInt(parts[1]);
                    boolean success = DatabaseManager.updateUserBalance(targetUser, newBalance);
                    out.reset();
                    out.writeObject(new Message("ADMIN_ACTION_RESULT", success ? "Balanță actualizată cu succes!" : "Eroare la actualizare!"));
                    out.flush();
                    // Notify user if online
                    synchronized (ServerMain.handlers) {
                        for (ClientHandler h : ServerMain.handlers) {
                            if (h.username != null && h.username.equals(targetUser)) {
                                h.sendBalanceUpdate(newBalance);
                                break;
                            }
                        }
                    }
                }
            }
        } else if (type.equals("ADMIN_GET_HISTORY")) {
            if (DatabaseManager.isAdmin(username)) {
                int limit = data instanceof String ? Integer.parseInt((String)data) : 50;
                List<String> history = DatabaseManager.getAdminHistory(limit);
                out.reset();
                out.writeObject(new Message("ADMIN_HISTORY", history));
                out.flush();
            }
        } else if (type.equals("ADMIN_DELETE_TABLE")) {
            // FIX: Handler pentru admin - șterge masă
            if (DatabaseManager.isAdmin(username)) {
                boolean deleted = DatabaseManager.deleteTable((String)data);
                if (deleted) {
                    DatabaseManager.logAdminAction("DELETE_TABLE", (String)data, "Masă ștearsă");
                }
                out.reset(); 
                out.writeObject(new Message("ADMIN_ACTION_RESULT", deleted ? "Masă ștearsă cu succes!" : "Eroare la ștergere!")); 
                out.flush();
            }
        }
    }

    public void sendBalanceUpdate(int bal) {
        try { 
            out.reset(); 
            out.writeObject(new Message("UPDATE_BALANCE", String.valueOf(bal))); 
            out.flush(); 
        } catch (Exception e) {}
    }

    public void sendTableList() {
        try { out.reset(); out.writeObject(new Message("TABLE_LIST", DatabaseManager.getTables())); out.flush(); } catch (Exception e) {}
    }

    public void sendGameState() {
        try { if (authenticatedUserId != -1) { out.reset(); out.writeObject(new Message("GAME_STATE", game.getGameStateForPlayer(authenticatedUserId))); out.flush(); } } catch (Exception e) {}
    }

    public void sendChatMessage(String msg) {
        try { out.reset(); out.writeObject(new Message("CHAT_MSG", msg)); out.flush(); } catch (Exception e) {}
    }

    public int getPlayerId() { return authenticatedUserId; }
}