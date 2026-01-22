import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public final class DbUtil {

    // Docker la tine expune: 0.0.0.0:5544 -> 5432 (în container)
    // Poți schimba fără cod: set CHAT_DB_PORT=5544 etc.
    private static final String DB_HOST = env("CHAT_DB_HOST", "localhost");
    private static final String DB_PORT = env("CHAT_DB_PORT", "5544");
    private static final String DB_NAME = env("CHAT_DB_NAME", "chatdb");
    private static final String DB_USER = env("CHAT_DB_USER", "chatuser");
    private static final String DB_PASS = env("CHAT_DB_PASS", "chatpass");

    private static final String URL = "jdbc:postgresql://" + DB_HOST + ":" + DB_PORT + "/" + DB_NAME;

    private DbUtil() {}

    private static String env(String key, String def) {
        String v = System.getenv(key);
        if (v == null) return def;
        v = v.trim();
        return v.isEmpty() ? def : v;
    }

    static {
        // Dacă jar-ul e în classpath, driverul se prinde automat, dar ținem și Class.forName pt log clar.
        try {
            Class.forName("org.postgresql.Driver");
            System.out.println("[DB] Driver PostgreSQL încărcat.");
        } catch (ClassNotFoundException e) {
            System.out.println("[DB] EROARE: org.postgresql.Driver nu a fost găsit! Verifică lib/postgresql-*.jar în classpath.");
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, DB_USER, DB_PASS);
    }

    public static boolean ping() {
        try (Connection c = getConnection()) {
            return true;
        } catch (SQLException e) {
            System.out.println("[DB] Conexiune eșuată: " + e.getMessage());
            return false;
        }
    }

    public static void initSchema() {
        if (!ping()) return;

        String sqlUsers = """
                CREATE TABLE IF NOT EXISTS app_user (
                    id SERIAL PRIMARY KEY,
                    username VARCHAR(50) UNIQUE NOT NULL,
                    password VARCHAR(100) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """;

        String sqlMsg = """
                CREATE TABLE IF NOT EXISTS message (
                    id SERIAL PRIMARY KEY,
                    sender_username VARCHAR(50) NOT NULL,
                    receiver_username VARCHAR(50),
                    content TEXT NOT NULL,
                    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """;

        try (Connection c = getConnection();
             Statement st = c.createStatement()) {
            st.execute(sqlUsers);
            st.execute(sqlMsg);
            System.out.println("[DB] Schema OK.");
        } catch (SQLException e) {
            System.out.println("[DB] Schema FAIL: " + e.getMessage());
        }
    }

    public static boolean registerUser(String username, String password) {
        if (!ping()) return false;

        String sql = "INSERT INTO app_user(username, password) VALUES (?, ?)";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.setString(2, password);
            ps.executeUpdate();
            return true;

        } catch (SQLException e) {
            System.out.println("[DB] Register error: " + e.getMessage());
            return false;
        }
    }

    public static boolean checkLogin(String username, String password) {
        if (!ping()) return false;

        String sql = "SELECT 1 FROM app_user WHERE username = ? AND password = ?";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (SQLException e) {
            System.out.println("[DB] Login error: " + e.getMessage());
            return false;
        }
    }

    public static void saveMessage(String sender, String receiver, String content) {
        if (!ping()) return;

        String sql = "INSERT INTO message(sender_username, receiver_username, content) VALUES (?, ?, ?)";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setString(1, sender);

            if (receiver == null || receiver.isBlank()) ps.setNull(2, Types.VARCHAR);
            else ps.setString(2, receiver);

            ps.setString(3, content);
            ps.executeUpdate();

        } catch (SQLException e) {
            System.out.println("[DB] Save message error: " + e.getMessage());
        }
    }

    public static List<MessageRow> fetchLastMessages(int limit) {
        List<MessageRow> out = new ArrayList<>();
        if (!ping()) return out;

        String sql = """
                SELECT sender_username, receiver_username, content, sent_at
                FROM message
                ORDER BY sent_at DESC
                LIMIT ?
                """;

        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setInt(1, limit);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MessageRow r = new MessageRow();
                    r.sender = rs.getString(1);
                    r.receiver = rs.getString(2);
                    r.content = rs.getString(3);
                    r.sentAt = rs.getTimestamp(4);
                    out.add(r);
                }
            }

        } catch (SQLException e) {
            System.out.println("[DB] Fetch messages error: " + e.getMessage());
        }

        // vrem cronologic (vechi -> nou)
        List<MessageRow> rev = new ArrayList<>();
        for (int i = out.size() - 1; i >= 0; i--) rev.add(out.get(i));
        return rev;
    }

    public static final class MessageRow {
        public String sender;
        public String receiver; // poate fi null
        public String content;
        public Timestamp sentAt;
    }
}
