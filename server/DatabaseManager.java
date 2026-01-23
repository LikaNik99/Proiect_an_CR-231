package server;

import java.io.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.HashSet;

public class DatabaseManager {
    private static final String USERS_FILE = "users.txt";
    private static final String FRIENDS_FILE = "friends.txt";
    private static final String MESSAGES_FILE = "messages.txt";
    private static final String MISSIONS_FILE = "missions.txt";
    private static final String DAILY_REWARDS_FILE = "daily_rewards.txt";
    private static final String BANNED_FILE = "banned.txt";
    private static final String ADMIN_HISTORY_FILE = "admin_history.txt";

    private static final Map<String, String> activeTables = new ConcurrentHashMap<>();
    private static final Map<String, LocalDate> lastDailyReward = new HashMap<>();
    private static final Map<String, List<String>> userMissions = new ConcurrentHashMap<>();
    private static final Map<String, LocalDate> lastMissionReset = new HashMap<>();
    private static final Map<String, List<String>> friendRequests = new ConcurrentHashMap<>();
    private static final Set<String> bannedUsers = new HashSet<>();

    public static void initializeDatabase() {
        try {
            new File(USERS_FILE).createNewFile();
            new File(FRIENDS_FILE).createNewFile();
            new File(MESSAGES_FILE).createNewFile();
            new File(MISSIONS_FILE).createNewFile();
            new File(DAILY_REWARDS_FILE).createNewFile();
            new File(BANNED_FILE).createNewFile();
            new File(ADMIN_HISTORY_FILE).createNewFile();
            activeTables.clear(); 
            // FIX: Creează masa implicită dacă nu există
            if (!activeTables.containsKey("Masa VIP #1")) {
                activeTables.put("Masa VIP #1", "4|0|100");
            }
            loadMissionsFromFile();
            loadDailyRewardsFromFile();
            loadBannedUsers();
            System.out.println("✅ Baza de date inițializată.");
        } catch (IOException e) {}
    }
    
    private static void loadBannedUsers() {
        try (BufferedReader br = new BufferedReader(new FileReader(BANNED_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                if (!line.trim().isEmpty()) {
                    bannedUsers.add(line.trim());
                }
            }
        } catch (IOException e) {}
    }
    
    public static synchronized void banUser(String username) {
        bannedUsers.add(username);
        try (PrintWriter pw = new PrintWriter(new FileWriter(BANNED_FILE, true))) {
            pw.println(username);
        } catch (IOException e) {}
        logAdminAction("BAN", username, "Utilizator banat");
    }
    
    public static boolean isBanned(String username) {
        return bannedUsers.contains(username);
    }
    
    public static synchronized void logAdminAction(String action, String target, String details) {
        try (PrintWriter pw = new PrintWriter(new FileWriter(ADMIN_HISTORY_FILE, true))) {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            pw.println(timestamp + "|" + action + "|" + target + "|" + details);
        } catch (IOException e) {}
    }
    
    public static List<String> getAdminHistory(int limit) {
        List<String> history = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(ADMIN_HISTORY_FILE))) {
            String line;
            List<String> allLines = new ArrayList<>();
            while ((line = br.readLine()) != null) {
                if (!line.trim().isEmpty()) {
                    allLines.add(line);
                }
            }
            // Return last N entries
            int start = Math.max(0, allLines.size() - limit);
            for (int i = allLines.size() - 1; i >= start; i--) {
                history.add(allLines.get(i));
            }
        } catch (IOException e) {}
        return history;
    }
    
    public static synchronized boolean updateUserBalance(String username, int newBalance) {
        String data = getUserData(username);
        if (data == null) return false;
        saveBalance(username, newBalance);
        logAdminAction("MODIFY_BALANCE", username, "Balanță setată la: " + newBalance);
        return true;
    }
    
    public static List<String> getOnlineUsers() {
        // Use Set to avoid duplicates (same user can have multiple connections)
        Set<String> onlineSet = new HashSet<>();
        // Access ServerMain handlers through the package
        synchronized (ServerMain.handlers) {
            for (ClientHandler h : ServerMain.handlers) {
                if (h.username != null && !h.username.isEmpty() && !h.username.equals("admin")) {
                    onlineSet.add(h.username);
                }
            }
        }
        return new ArrayList<>(onlineSet);
    }
    
    public static String getPlayerStatistics() {
        int total = getAllUsers().size();
        int online = getOnlineUsers().size();
        int offline = total - online;
        return total + "|" + online + "|" + offline;
    }

    public static synchronized void savePrivateMessage(String from, String to, String msg) {
        try (PrintWriter out = new PrintWriter(new FileWriter(MESSAGES_FILE, true))) {
            out.println(from + "|" + to + "|" + msg + "|" + LocalDateTime.now());
        } catch (IOException e) {}
    }

    public static List<String> getChatHistory(String u1, String u2) {
        List<String> hist = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(MESSAGES_FILE))) {
            String l;
            while ((l = br.readLine()) != null) {
                // Parse format: from|to|msg|date
                // Find last | to separate date, then find previous | for to/from
                int lastPipe = l.lastIndexOf('|');
                if (lastPipe <= 0) continue;
                String beforeDate = l.substring(0, lastPipe);
                int secondLastPipe = beforeDate.lastIndexOf('|');
                if (secondLastPipe <= 0) continue;
                String fromTo = l.substring(0, secondLastPipe);
                int firstPipe = fromTo.indexOf('|');
                if (firstPipe <= 0) continue;
                
                String from = l.substring(0, firstPipe);
                String to = l.substring(firstPipe + 1, secondLastPipe);
                String msg = l.substring(secondLastPipe + 1, lastPipe);
                
                if ((from.equals(u1) && to.equals(u2)) || (from.equals(u2) && to.equals(u1))) {
                    hist.add(from + ": " + msg);
                }
            }
        } catch (IOException e) {}
        return hist;
    }

    public static synchronized String registerUser(String u, String e, String p) {
        // FIX: Validare input
        if (u == null || u.trim().isEmpty() || e == null || e.trim().isEmpty() || p == null || p.trim().isEmpty()) {
            return "ERROR";
        }
        if (getUserData(u.trim()) != null) return "EXIST";
        try (PrintWriter out = new PrintWriter(new FileWriter(USERS_FILE, true))) {
            // REPARAȚIE: Format curat yyyy-MM-dd HH:mm (Fără milisecunde)
            String formattedDate = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
            out.println(u.trim() + "|" + e.trim() + "|" + p.trim() + "|1000|" + formattedDate);
            out.flush(); // FIX: Force flush pentru a asigura scrierea
            return "SUCCESS";
        } catch (IOException ex) { 
            System.err.println("Eroare la înregistrare: " + ex.getMessage());
            return "ERROR"; 
        }
    }
    
    // FIX: Verifică dacă utilizatorul este admin
    public static boolean isAdmin(String username) {
        return username != null && username.equalsIgnoreCase("admin");
    }
    
    // FIX: Obține toți utilizatorii pentru admin panel
    public static List<String> getAllUsers() {
        List<String> users = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(USERS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                if (!line.trim().isEmpty()) {
                    users.add(line);
                }
            }
        } catch (IOException e) {}
        return users;
    }
    
    // FIX: Șterge utilizator
    public static synchronized boolean deleteUser(String username) {
        List<String> allUsers = new ArrayList<>();
        boolean found = false;
        try (BufferedReader br = new BufferedReader(new FileReader(USERS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                String[] p = line.split("\\|");
                if (p.length > 0 && !p[0].equals(username)) {
                    allUsers.add(line);
                } else if (p.length > 0 && p[0].equals(username)) {
                    found = true;
                }
            }
        } catch (IOException e) {}
        if (found) {
            try (PrintWriter pw = new PrintWriter(new FileWriter(USERS_FILE))) {
                for (String l : allUsers) pw.println(l);
            } catch (IOException e) {}
        }
        return found;
    }
    
    // FIX: Șterge masă
    public static synchronized boolean deleteTable(String tableName) {
        if (activeTables.containsKey(tableName)) {
            activeTables.remove(tableName);
            ServerMain.broadcastTableList();
            return true;
        }
        return false;
    }

    public static synchronized String loginUser(String u, String p) {
        String data = getUserData(u.trim());
        if (data != null) {
            String[] parts = data.split("\\|");
            if (parts[2].equals(p.trim())) return "SUCCESS|" + parts[0] + "|" + parts[3] + "|" + parts[4];
        }
        return "FAIL";
    }

    public static String getUserData(String username) {
        try (BufferedReader br = new BufferedReader(new FileReader(USERS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) if (line.startsWith(username + "|")) return line;
        } catch (IOException e) {}
        return null;
    }

    public static synchronized void saveBalance(String username, int newBalance) {
        List<String> allUsers = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(USERS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                String[] p = line.split("\\|");
                if (p[0].equals(username)) line = p[0] + "|" + p[1] + "|" + p[2] + "|" + newBalance + "|" + p[4];
                allUsers.add(line);
            }
        } catch (IOException e) {}
        try (PrintWriter pw = new PrintWriter(new FileWriter(USERS_FILE))) {
            for (String l : allUsers) pw.println(l);
        } catch (IOException e) {}
    }

    private static void loadDailyRewardsFromFile() {
        try (BufferedReader br = new BufferedReader(new FileReader(DAILY_REWARDS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                String[] parts = line.split("\\|");
                if (parts.length >= 2) {
                    try {
                        LocalDate date = LocalDate.parse(parts[1]);
                        lastDailyReward.put(parts[0], date);
                    } catch (Exception e) {}
                }
            }
        } catch (IOException e) {}
    }

    private static void saveDailyReward(String user, LocalDate date) {
        List<String> allLines = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(DAILY_REWARDS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                if (!line.startsWith(user + "|")) {
                    allLines.add(line);
                }
            }
        } catch (IOException e) {}
        allLines.add(user + "|" + date.toString());
        try (PrintWriter pw = new PrintWriter(new FileWriter(DAILY_REWARDS_FILE))) {
            for (String l : allLines) pw.println(l);
        } catch (IOException e) {}
    }

    public static synchronized String claimDaily(String user) {
        LocalDate today = LocalDate.now();
        // FIX: Verifică din fișier, nu doar din memorie
        LocalDate lastClaim = lastDailyReward.getOrDefault(user, null);
        if (lastClaim == null) {
            // Încearcă să încarce din fișier
            try (BufferedReader br = new BufferedReader(new FileReader(DAILY_REWARDS_FILE))) {
                String line;
                while ((line = br.readLine()) != null) {
                    if (line.startsWith(user + "|")) {
                        try {
                            lastClaim = LocalDate.parse(line.split("\\|")[1]);
                            lastDailyReward.put(user, lastClaim);
                        } catch (Exception e) {}
                        break;
                    }
                }
            } catch (IOException e) {}
        }
        if (lastClaim != null && lastClaim.equals(today)) return "ALREADY";
        String userData = getUserData(user);
        if (userData != null) {
            int currentBal = Integer.parseInt(userData.split("\\|")[3]);
            saveBalance(user, currentBal + 1000);
            lastDailyReward.put(user, today);
            saveDailyReward(user, today);
            return "OK";
        }
        return "ERROR";
    }

    public static synchronized List<String> getFriends(String user) {
        List<String> friends = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(FRIENDS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                String[] p = line.split(":");
                if (p[0].equals(user) && p.length > 1) friends.addAll(Arrays.asList(p[1].split(",")));
            }
        } catch (IOException e) {}
        return friends;
    }

    public static void addFriendRequest(String to, String from) {
        if (getUserData(to) != null && !to.equals(from)) {
            List<String> reqs = friendRequests.computeIfAbsent(to, k -> new ArrayList<>());
            if(!reqs.contains(from)) reqs.add(from);
        }
    }

    public static List<String> getFriendRequests(String user) {
        return friendRequests.getOrDefault(user, new ArrayList<>());
    }

    public static synchronized void acceptFriend(String user, String friend) {
        if (friendRequests.containsKey(user)) {
            friendRequests.get(user).remove(friend);
            addFriend(user, friend);
            addFriend(friend, user); 
        }
    }

    public static synchronized void addFriend(String user, String friend) {
        List<String> friends = getFriends(user);
        if (!friends.contains(friend)) {
            friends.add(friend);
            saveFriendsToFile(user, friends);
        }
    }

    private static void saveFriendsToFile(String user, List<String> friends) {
        List<String> lines = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(FRIENDS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) if (!line.startsWith(user + ":")) lines.add(line);
        } catch (IOException e) {}
        lines.add(user + ":" + String.join(",", friends));
        try (PrintWriter pw = new PrintWriter(new FileWriter(FRIENDS_FILE))) {
            for (String l : lines) pw.println(l);
        } catch (IOException e) {}
    }

    private static void loadMissionsFromFile() {
        try (BufferedReader br = new BufferedReader(new FileReader(MISSIONS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                int colonIdx = line.indexOf(':');
                if (colonIdx <= 0) continue;
                String user = line.substring(0, colonIdx);
                String missionsData = line.substring(colonIdx + 1);
                String[] parts = missionsData.split(";");
                List<String> missions = new ArrayList<>();
                for (String part : parts) {
                    if (!part.trim().isEmpty()) missions.add(part);
                }
                if (!missions.isEmpty()) {
                    userMissions.put(user, missions);
                }
            }
        } catch (IOException e) {}
    }

    private static void saveMissionsToFile(String user, List<String> missions) {
        List<String> allLines = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(MISSIONS_FILE))) {
            String line;
            while ((line = br.readLine()) != null) {
                if (!line.startsWith(user + ":")) {
                    allLines.add(line);
                }
            }
        } catch (IOException e) {}
        if (missions != null && !missions.isEmpty()) {
            // FIX: Salvează și data ultimului reset
            LocalDate resetDate = lastMissionReset.getOrDefault(user, LocalDate.now());
            allLines.add(user + ":" + String.join(";", missions) + "|" + resetDate.toString());
        }
        try (PrintWriter pw = new PrintWriter(new FileWriter(MISSIONS_FILE))) {
            for (String l : allLines) pw.println(l);
        } catch (IOException e) {}
    }

    public static List<String> getMissions(String user) {
        LocalDate today = LocalDate.now();
        // FIX: Verifică din fișier dacă nu e în memorie
        LocalDate lastReset = lastMissionReset.get(user);
        if (lastReset == null) {
            // Încearcă să încarce din fișier
            try (BufferedReader br = new BufferedReader(new FileReader(MISSIONS_FILE))) {
                String line;
                while ((line = br.readLine()) != null) {
                    if (line.startsWith(user + ":")) {
                        int pipeIdx = line.lastIndexOf('|');
                        if (pipeIdx > 0) {
                            try {
                                lastReset = LocalDate.parse(line.substring(pipeIdx + 1));
                                lastMissionReset.put(user, lastReset);
                            } catch (Exception e) {}
                        }
                        break;
                    }
                }
            } catch (IOException e) {}
        }
        if (!userMissions.containsKey(user) || (lastReset != null && !today.equals(lastReset))) {
            generateDailyMissions(user);
            lastMissionReset.put(user, today);
        }
        return userMissions.get(user);
    }

    private static void generateDailyMissions(String user) {
        List<String> m = new ArrayList<>();
        m.add("Pariuri plasate|0|3|OPEN");
        m.add("Mâini câștigate|0|5|OPEN");
        m.add("Scor de 21|0|3|OPEN");
        userMissions.put(user, m);
        saveMissionsToFile(user, m);
    }

    public static synchronized void updateMissionProgress(String user, int idx) {
        getMissions(user);
        List<String> missions = userMissions.get(user);
        if (missions == null || idx >= missions.size()) return;
        String[] p = missions.get(idx).split("\\|");
        if (!p[3].equals("OPEN")) return;
        int curr = Integer.parseInt(p[1]) + 1;
        int trg = Integer.parseInt(p[2]);
        missions.set(idx, p[0] + "|" + curr + "|" + trg + "|" + (curr >= trg ? "COMPLETED" : "OPEN"));
        saveMissionsToFile(user, missions);
    }

    public static synchronized int claimMission(String user, int idx) {
        getMissions(user); // Asigură-te că misiunile sunt încărcate
        List<String> m = userMissions.get(user);
        if (m == null || idx >= m.size()) return 0;
        String[] p = m.get(idx).split("\\|");
        if (p.length < 4) return 0;
        // FIX: Verifică dacă misiunea este deja CLAIMED astăzi
        if (p[3].equals("CLAIMED")) {
            // Verifică dacă data reset-ului este astăzi - dacă da, deja claim-uită
            LocalDate lastReset = lastMissionReset.getOrDefault(user, null);
            if (lastReset != null && lastReset.equals(LocalDate.now())) {
                return 0; // Deja claim-uită astăzi
            }
        }
        if (p[3].equals("COMPLETED")) {
            int rew = (idx == 0) ? 1500 : (idx == 1) ? 2500 : 5000;
            m.set(idx, p[0] + "|" + p[1] + "|" + p[2] + "|CLAIMED");
            saveMissionsToFile(user, m);
            saveBalance(user, Integer.parseInt(getUserData(user).split("\\|")[3]) + rew);
            return rew;
        }
        return 0;
    }

    public static List<String> getTables() {
        List<String> list = new ArrayList<>();
        activeTables.forEach((n, d) -> list.add(n + "|" + d));
        return list;
    }
    public static void createTable(String n, String b) { activeTables.put(n, "4|0|" + b); ServerMain.broadcastTableList(); }
    public static void updateTableOccupancy(String n, int max, int occ, int b) { 
        // FIX: Creează masa dacă nu există
        if (!activeTables.containsKey(n)) {
            activeTables.put(n, max + "|" + occ + "|" + b);
        } else {
            activeTables.put(n, max + "|" + occ + "|" + b);
        }
        ServerMain.broadcastTableList(); 
    }
}