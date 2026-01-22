import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

import java.net.InetSocketAddress;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class ClientServer extends WebSocketServer {

    private final Map<WebSocket, String> users = new ConcurrentHashMap<>();

    // Limite
    private static final int MAX_IMAGE_BYTES = 800_000;   // ~0.8MB
    private static final int MAX_AUDIO_BYTES = 700_000;   // ~0.7MB (WAV 15 sec @16kHz mono)
    private static final int MAX_B64_CHARS   = 1_300_000; // protecție extra

    public ClientServer(int port) {
        super(new InetSocketAddress(port));
    }

    @Override
    public void onStart() {
        System.out.println("Server pornit pe ws://localhost:" + getPort());
        DbUtil.initSchema();
    }

    @Override
    public void onOpen(WebSocket conn, ClientHandshake handshake) {
        System.out.println("Client conectat: " + conn.getRemoteSocketAddress());
        conn.send("INFO|Bun venit pe Chat Multifuncțional!");
        conn.send("INFO|Te rog să te autentifici sau să te înregistrezi.");
        conn.send("INFO|Format: AUTH|REGISTER|user|pass sau AUTH|LOGIN|user|pass");
    }

    @Override
    public void onClose(WebSocket conn, int code, String reason, boolean remote) {
        String nick = users.remove(conn);
        if (nick != null) {
            broadcast("INFO|** " + nick + " a ieșit **");
            broadcastUsers();
            System.out.println("Client deconectat: " + nick);
        } else {
            System.out.println("Client deconectat (neautentificat): " + conn.getRemoteSocketAddress());
        }
    }

    @Override
    public void onMessage(WebSocket conn, String message) {
        try {
            if (message == null) return;

            if (message.startsWith("SENDIMG|")) {
                System.out.println("Imagine primită (payload mare)...");
            } else if (message.startsWith("SENDVOICE|")) {
                System.out.println("Voice primit (payload mare)...");
            } else {
                System.out.println("Mesaj primit: " + message);
            }

            if (message.startsWith("AUTH|")) {
                handleAuth(conn, message);
                return;
            }

            String sender = users.get(conn);
            if (sender == null) {
                conn.send("ERROR|Trebuie să fii autentificat.");
                return;
            }

            // ====== IMAGINI ======
            // SENDIMG|toUserOrEmpty|fileName|mime|base64
            if (message.startsWith("SENDIMG|")) {
                handleSendImage(conn, sender, message);
                return;
            }

            // ====== VOICE ======
            // SENDVOICE|toUserOrEmpty|fileName|mime|base64
            if (message.startsWith("SENDVOICE|")) {
                handleSendVoice(conn, sender, message);
                return;
            }

            // ====== PM text ======
            if (message.startsWith("/w ")) {
                String[] parts = message.split("\\s+", 3);
                if (parts.length < 3) {
                    conn.send("ERROR|Format: /w <user> <mesaj>");
                    return;
                }

                String toUser = parts[1];
                String text = parts[2];

                WebSocket dest = getUserByName(toUser);
                if (dest == null) {
                    conn.send("ERROR|Utilizatorul nu este online.");
                    return;
                }

                String formatted = "PM|" + sender + "|" + toUser + "|" + text;
                dest.send(formatted);
                conn.send(formatted);

                DbUtil.saveMessage(sender, toUser, text);
                return;
            }

            // ====== Global text ======
            String formatted = "MSG|" + sender + "|" + message;
            broadcast(formatted);
            DbUtil.saveMessage(sender, null, message);

        } catch (Exception ex) {
            System.out.println("SERVER ERROR: " + ex);
            try { conn.send("ERROR|Eroare server: " + ex.getMessage()); } catch (Exception ignored) {}
        }
    }

    private void handleSendImage(WebSocket conn, String sender, String msg) {
        // SENDIMG|to|fileName|mime|base64
        String[] p = msg.split("\\|", 5);
        if (p.length < 5) { conn.send("ERROR|Format imagine invalid."); return; }

        String to = (p[1] == null) ? "" : p[1].trim();
        String fileName = safeName(p[2]);
        String mime = (p[3] == null) ? "" : p[3].trim();
        String b64 = (p[4] == null) ? "" : p[4].trim();

        if (b64.isEmpty()) { conn.send("ERROR|Imagine goală."); return; }
        if (b64.length() > MAX_B64_CHARS) { conn.send("ERROR|Imagine prea mare (base64)."); return; }

        byte[] bytes;
        try { bytes = Base64.getDecoder().decode(b64); }
        catch (IllegalArgumentException e) { conn.send("ERROR|Imagine invalidă (base64)."); return; }

        if (bytes.length > MAX_IMAGE_BYTES) { conn.send("ERROR|Imagine prea mare. Maxim ~0.8MB."); return; }

        long ts = System.currentTimeMillis();
        String out = "IMG|" + sender + "|" + to + "|" + fileName + "|" + mime + "|" + ts + "|" + b64;

        if (to.isBlank()) {
            broadcast(out);
            DbUtil.saveMessage(sender, null, "IMGDATA|" + fileName + "|" + mime + "|" + b64);
        } else {
            WebSocket dest = getUserByName(to);
            if (dest == null) { conn.send("ERROR|Utilizatorul nu este online."); return; }
            dest.send(out);
            conn.send(out);
            DbUtil.saveMessage(sender, to, "IMGDATA|" + fileName + "|" + mime + "|" + b64);
        }
    }

    private void handleSendVoice(WebSocket conn, String sender, String msg) {
        // SENDVOICE|to|fileName|mime|base64
        String[] p = msg.split("\\|", 5);
        if (p.length < 5) { conn.send("ERROR|Format voice invalid."); return; }

        String to = (p[1] == null) ? "" : p[1].trim();
        String fileName = safeName(p[2]);
        String mime = (p[3] == null) ? "" : p[3].trim();
        String b64 = (p[4] == null) ? "" : p[4].trim();

        if (b64.isEmpty()) { conn.send("ERROR|Voice gol."); return; }
        if (b64.length() > MAX_B64_CHARS) { conn.send("ERROR|Voice prea mare (base64)."); return; }

        byte[] bytes;
        try { bytes = Base64.getDecoder().decode(b64); }
        catch (IllegalArgumentException e) { conn.send("ERROR|Voice invalid (base64)."); return; }

        if (bytes.length > MAX_AUDIO_BYTES) { conn.send("ERROR|Voice prea mare. Limitează la ~15 sec."); return; }

        long ts = System.currentTimeMillis();
        String out = "VOICE|" + sender + "|" + to + "|" + fileName + "|" + mime + "|" + ts + "|" + b64;

        if (to.isBlank()) {
            broadcast(out);
            DbUtil.saveMessage(sender, null, "VOICEDATA|" + fileName + "|" + mime + "|" + b64);
        } else {
            WebSocket dest = getUserByName(to);
            if (dest == null) { conn.send("ERROR|Utilizatorul nu este online."); return; }
            dest.send(out);
            conn.send(out);
            DbUtil.saveMessage(sender, to, "VOICEDATA|" + fileName + "|" + mime + "|" + b64);
        }
    }

    private String safeName(String s) {
        if (s == null) return "file";
        s = s.trim();
        if (s.isEmpty()) return "file";
        return s.replace("|", "_");
    }

    private void handleAuth(WebSocket conn, String msg) {
        String[] parts = msg.split("\\|", 4);
        if (parts.length < 4) { conn.send("AUTH_FAIL|Format invalid."); return; }

        String mode = parts[1].trim();
        String username = parts[2].trim();
        String password = parts[3];

        if (username.isEmpty() || password == null || password.isEmpty()) {
            conn.send("AUTH_FAIL|Username/parolă goale.");
            return;
        }

        if (!DbUtil.ping()) {
            conn.send("AUTH_FAIL|Baza de date nu este accesibilă (verifică docker + port).");
            return;
        }

        boolean ok;
        if ("REGISTER".equalsIgnoreCase(mode)) {
            ok = DbUtil.registerUser(username, password);
            if (!ok) { conn.send("AUTH_FAIL|Username deja folosit sau eroare DB."); return; }
        } else if ("LOGIN".equalsIgnoreCase(mode)) {
            ok = DbUtil.checkLogin(username, password);
            if (!ok) { conn.send("AUTH_FAIL|Nume sau parolă greșită."); return; }
        } else {
            conn.send("AUTH_FAIL|Mod necunoscut: " + mode);
            return;
        }

        users.put(conn, username);
        conn.send("AUTH_OK|" + username);

        // ===== Istoric (ultimele 50) =====
        for (DbUtil.MessageRow r : DbUtil.fetchLastMessages(50)) {
            String ts = (r.sentAt == null) ? "" : Long.toString(r.sentAt.getTime());

            if (r.content != null && r.content.startsWith("IMGDATA|")) {
                String rest = r.content.substring("IMGDATA|".length());
                String[] pp = rest.split("\\|", 3);
                if (pp.length == 3) {
                    String file = safeName(pp[0]);
                    String mime = pp[1];
                    String b64 = pp[2];
                    String to = (r.receiver == null ? "" : r.receiver);
                    conn.send("HIMG|" + r.sender + "|" + to + "|" + file + "|" + mime + "|" + ts + "|" + b64);
                }
                continue;
            }

            if (r.content != null && r.content.startsWith("VOICEDATA|")) {
                String rest = r.content.substring("VOICEDATA|".length());
                String[] pp = rest.split("\\|", 3);
                if (pp.length == 3) {
                    String file = safeName(pp[0]);
                    String mime = pp[1];
                    String b64 = pp[2];
                    String to = (r.receiver == null ? "" : r.receiver);
                    conn.send("HVOICE|" + r.sender + "|" + to + "|" + file + "|" + mime + "|" + ts + "|" + b64);
                }
                continue;
            }

            if (r.receiver == null) conn.send("HMSG|" + r.sender + "|" + r.content + "|" + ts);
            else conn.send("HPM|" + r.sender + "|" + r.receiver + "|" + r.content + "|" + ts);
        }

        broadcast("INFO|** " + username + " a intrat în chat **");
        broadcastUsers();
    }

    private void broadcastUsers() {
        StringBuilder sb = new StringBuilder("USERS|");
        boolean first = true;
        for (String u : users.values()) {
            if (!first) sb.append(",");
            sb.append(u);
            first = false;
        }
        broadcast(sb.toString());
    }

    private WebSocket getUserByName(String name) {
        return users.entrySet()
                .stream()
                .filter(e -> e.getValue().equalsIgnoreCase(name))
                .map(Map.Entry::getKey)
                .findFirst()
                .orElse(null);
    }

    @Override
    public void onError(WebSocket conn, Exception ex) {
        System.out.println("Eroare server: " + ex);
    }

    public static void main(String[] args) throws Exception {
        int port = 8080;
        ClientServer server = new ClientServer(port);
        server.start();
        System.out.println("Server ascultă pe ws://localhost:" + port);
    }
}
