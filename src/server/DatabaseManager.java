package server;

import java.sql.*;
import java.util.*;
import shared.*;

public class DatabaseManager {
    private Connection connection;

    public DatabaseManager() {
        System.out.println("🔄 Initializare DatabaseManager...");

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            String url = "jdbc:mysql://localhost:3306/tweets_advanced";
            String user = "root";
            String password = "";

            connection = DriverManager.getConnection(url, user, password);
            System.out.println("✅ Conectat la baza de date tweets_advanced");

            // Verifică conexiunea
            testConnection();

        } catch (ClassNotFoundException e) {
            System.err.println("❌ Driver MySQL nu este în classpath!");
            System.err.println("Adaugă mysql-connector-java-8.1.0.jar în folderul lib/");
        } catch (SQLException e) {
            System.err.println("❌ Eroare conexiune MySQL: " + e.getMessage());
            System.err.println("Verifică dacă baza 'tweets_advanced' există!");
        }
    }

    private void testConnection() {
        try {
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT '✅ Database operational!' as status");
            if (rs.next()) {
                System.out.println(rs.getString("status"));
            }
        } catch (SQLException e) {
            System.err.println("❌ Eroare test conexiune: " + e.getMessage());
        }
    }

    // ==================== UTILIZATORI ====================

    public User authenticateUser(String username, String password) {
        String query = "SELECT user_id, username, email, full_name, bio, avatar_color, role " +
                "FROM users WHERE username = ? AND password = ? AND is_active = TRUE";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, username);
            stmt.setString(2, password);

            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                User user = new User(
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("email"),
                        rs.getString("full_name"),
                        rs.getString("bio"),
                        rs.getString("avatar_color"),
                        rs.getString("role")
                );

                // Update last login
                updateLastLogin(user.getUserId());
                System.out.println("✅ Autentificare reușită pentru: " + username);
                return user;
            }

        } catch (SQLException e) {
            System.err.println("❌ Eroare autentificare: " + e.getMessage());
        }

        System.out.println("❌ Autentificare eșuată pentru: " + username);
        return null;
    }

    private void updateLastLogin(int userId) {
        String query = "UPDATE users SET last_login = NOW() WHERE user_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, userId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("❌ Eroare update last_login: " + e.getMessage());
        }
    }

    public boolean registerUser(String username, String password, String email, String fullName) {
        String query = "INSERT INTO users (username, password, email, full_name) VALUES (?, ?, ?, ?)";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, username);
            stmt.setString(2, password);
            stmt.setString(3, email);
            stmt.setString(4, fullName != null ? fullName : username);

            int rows = stmt.executeUpdate();
            System.out.println("✅ Utilizator înregistrat: " + username);
            return rows > 0;

        } catch (SQLException e) {
            System.err.println("❌ Eroare înregistrare: " + e.getMessage());
            return false;
        }
    }

    public User getUserById(int userId) {
        String query = "SELECT user_id, username, email, full_name, bio, avatar_color, role " +
                "FROM users WHERE user_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, userId);

            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return new User(
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("email"),
                        rs.getString("full_name"),
                        rs.getString("bio"),
                        rs.getString("avatar_color"),
                        rs.getString("role")
                );
            }

        } catch (SQLException e) {
            System.err.println("❌ Eroare getUserById: " + e.getMessage());
        }

        return null;
    }

    // ==================== THREAD-URI ====================

    public List<ForumThread> getAllThreads() {
        List<ForumThread> threads = new ArrayList<>();
        String query = "SELECT t.*, u.username, u.avatar_color, " +
                "COUNT(DISTINCT c.comment_id) as comment_count " +
                "FROM threads t " +
                "JOIN users u ON t.user_id = u.user_id " +
                "LEFT JOIN comments c ON t.thread_id = c.thread_id " +
                "GROUP BY t.thread_id " +
                "ORDER BY t.is_pinned DESC, t.created_at DESC";

        try (Statement stmt = connection.createStatement()) {
            ResultSet rs = stmt.executeQuery(query);

            while (rs.next()) {
                ForumThread thread = new ForumThread(
                        rs.getInt("thread_id"),
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("avatar_color"),
                        rs.getString("title"),
                        rs.getString("content"),
                        rs.getTimestamp("created_at"),
                        rs.getInt("view_count"),
                        rs.getInt("vote_score"),
                        rs.getBoolean("is_pinned"),
                        rs.getBoolean("is_locked"),
                        rs.getInt("comment_count")
                );
                threads.add(thread);
            }

        } catch (SQLException e) {
            System.err.println("❌ Eroare getAllThreads: " + e.getMessage());
        }

        return threads;
    }

    public ForumThread getThreadById(int threadId) {
        String query = "SELECT t.*, u.username, u.avatar_color, " +
                "COUNT(DISTINCT c.comment_id) as comment_count " +
                "FROM threads t " +
                "JOIN users u ON t.user_id = u.user_id " +
                "LEFT JOIN comments c ON t.thread_id = c.thread_id " +
                "WHERE t.thread_id = ? " +
                "GROUP BY t.thread_id";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);

            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                // Increment view count
                incrementViewCount(threadId);

                return new ForumThread(
                        rs.getInt("thread_id"),
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("avatar_color"),
                        rs.getString("title"),
                        rs.getString("content"),
                        rs.getTimestamp("created_at"),
                        rs.getInt("view_count") + 1, // +1 pentru view-ul curent
                        rs.getInt("vote_score"),
                        rs.getBoolean("is_pinned"),
                        rs.getBoolean("is_locked"),
                        rs.getInt("comment_count")
                );
            }

        } catch (SQLException e) {
            System.err.println("❌ Eroare getThreadById: " + e.getMessage());
        }

        return null;
    }

    private void incrementViewCount(int threadId) {
        String query = "UPDATE threads SET view_count = view_count + 1 WHERE thread_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("❌ Eroare incrementViewCount: " + e.getMessage());
        }
    }

    public boolean createThread(int userId, String title, String content, List<Integer> tagIds) {
        String query = "INSERT INTO threads (user_id, title, content) VALUES (?, ?, ?)";

        try {
            connection.setAutoCommit(false);

            // Crează thread-ul
            PreparedStatement stmt = connection.prepareStatement(query, Statement.RETURN_GENERATED_KEYS);
            stmt.setInt(1, userId);
            stmt.setString(2, title);
            stmt.setString(3, content);

            int rows = stmt.executeUpdate();
            if (rows == 0) {
                connection.rollback();
                return false;
            }

            // Obține ID-ul thread-ului creat
            ResultSet generatedKeys = stmt.getGeneratedKeys();
            if (!generatedKeys.next()) {
                connection.rollback();
                return false;
            }

            int threadId = generatedKeys.getInt(1);

            // Adaugă tag-urile
            if (tagIds != null && !tagIds.isEmpty()) {
                String tagQuery = "INSERT INTO thread_tags (thread_id, tag_id) VALUES (?, ?)";
                PreparedStatement tagStmt = connection.prepareStatement(tagQuery);

                for (int tagId : tagIds) {
                    tagStmt.setInt(1, threadId);
                    tagStmt.setInt(2, tagId);
                    tagStmt.addBatch();
                }

                tagStmt.executeBatch();
            }

            connection.commit();
            System.out.println("✅ Thread creat: " + title + " (ID: " + threadId + ")");
            return true;

        } catch (SQLException e) {
            try {
                connection.rollback();
            } catch (SQLException ex) {
                System.err.println("❌ Eroare rollback: " + ex.getMessage());
            }
            System.err.println("❌ Eroare createThread: " + e.getMessage());
            return false;
        } finally {
            try {
                connection.setAutoCommit(true);
            } catch (SQLException e) {
                System.err.println("❌ Eroare setAutoCommit: " + e.getMessage());
            }
        }
    }

    // ==================== COMENTARII ====================

    public List<Comment> getCommentsForThread(int threadId) {
        List<Comment> comments = new ArrayList<>();
        String query = "SELECT c.*, u.username, u.avatar_color " +
                "FROM comments c " +
                "JOIN users u ON c.user_id = u.user_id " +
                "WHERE c.thread_id = ? " +
                "ORDER BY c.created_at ASC";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);

            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Integer parentId = (Integer) rs.getObject("parent_comment_id");
                Comment comment = new Comment(
                        rs.getInt("comment_id"),
                        rs.getInt("thread_id"),
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("avatar_color"),
                        parentId,
                        rs.getString("content"),
                        rs.getTimestamp("created_at"),
                        rs.getInt("vote_score"),
                        rs.getBoolean("is_edited")
                );
                comments.add(comment);
            }

            System.out.println("✅ Găsite " + comments.size() + " comentarii pentru thread #" + threadId);

        } catch (SQLException e) {
            System.err.println("❌ Eroare getCommentsForThread: " + e.getMessage());
            e.printStackTrace();
        }

        return comments;
    }

    // METODĂ NOUĂ: Grupează comentariile după parent ID
    public Map<Integer, List<Comment>> getCommentsGroupedByParent(int threadId) {
        Map<Integer, List<Comment>> groupedComments = new HashMap<>();
        List<Comment> allComments = getCommentsForThread(threadId);

        for (Comment comment : allComments) {
            int parentId = comment.getParentCommentId() != null ?
                    comment.getParentCommentId() : 0;
            groupedComments.computeIfAbsent(parentId, k -> new ArrayList<>()).add(comment);
        }

        // Sortează comentariile root (parentId = 0) descrescător
        if (groupedComments.containsKey(0)) {
            groupedComments.get(0).sort((c1, c2) ->
                    c2.getCreatedAt().compareTo(c1.getCreatedAt()));
        }

        return groupedComments;
    }

    public boolean addComment(int threadId, int userId, String content, Integer parentCommentId) {
        String query = "INSERT INTO comments (thread_id, user_id, parent_comment_id, content) VALUES (?, ?, ?, ?)";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);
            stmt.setInt(2, userId);
            if (parentCommentId != null) {
                stmt.setInt(3, parentCommentId);
            } else {
                stmt.setNull(3, Types.INTEGER);
            }
            stmt.setString(4, content);

            int rows = stmt.executeUpdate();
            System.out.println("✅ Comentariu adăugat la thread ID: " + threadId +
                    (parentCommentId != null ? " (răspuns la comment ID: " + parentCommentId + ")" : ""));
            return rows > 0;

        } catch (SQLException e) {
            System.err.println("❌ Eroare addComment: " + e.getMessage());
            return false;
        }
    }

    // ==================== TAG-URI ====================

    public List<Tag> getAllTags() {
        List<Tag> tags = new ArrayList<>();
        String query = "SELECT * FROM tags ORDER BY name";

        try (Statement stmt = connection.createStatement()) {
            ResultSet rs = stmt.executeQuery(query);

            while (rs.next()) {
                Tag tag = new Tag(
                        rs.getInt("tag_id"),
                        rs.getString("name"),
                        rs.getString("color"),
                        rs.getString("description")
                );
                tags.add(tag);
            }

        } catch (SQLException e) {
            System.err.println("❌ Eroare getAllTags: " + e.getMessage());
        }

        return tags;
    }

    public List<Tag> getTagsForThread(int threadId) {
        List<Tag> tags = new ArrayList<>();
        String query = "SELECT t.* FROM tags t " +
                "JOIN thread_tags tt ON t.tag_id = tt.tag_id " +
                "WHERE tt.thread_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);

            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Tag tag = new Tag(
                        rs.getInt("tag_id"),
                        rs.getString("name"),
                        rs.getString("color"),
                        rs.getString("description")
                );
                tags.add(tag);
            }

        } catch (SQLException e) {
            System.err.println("❌ Eroare getTagsForThread: " + e.getMessage());
        }

        return tags;
    }

    // ==================== UTILIZATORI ACTIVI ====================

    public void updateUserActivity(String sessionId, int userId, Integer threadId, String ipAddress) {
        String query = "INSERT INTO active_users (session_id, user_id, thread_id, ip_address, last_activity) " +
                "VALUES (?, ?, ?, ?, NOW()) " +
                "ON DUPLICATE KEY UPDATE thread_id = VALUES(thread_id), last_activity = NOW()";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, sessionId);
            stmt.setInt(2, userId);
            if (threadId != null) {
                stmt.setInt(3, threadId);
            } else {
                stmt.setNull(3, Types.INTEGER);
            }
            stmt.setString(4, ipAddress);

            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("❌ Eroare updateUserActivity: " + e.getMessage());
        }
    }

    public void removeUserActivity(String sessionId) {
        String query = "DELETE FROM active_users WHERE session_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, sessionId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("❌ Eroare removeUserActivity: " + e.getMessage());
        }
    }

    public List<ActiveUser> getActiveUsers(Integer threadId) {
        List<ActiveUser> activeUsers = new ArrayList<>();

        String query;
        if (threadId != null && threadId > 0) {
            query = "SELECT au.*, u.username, u.avatar_color " +
                    "FROM active_users au " +
                    "JOIN users u ON au.user_id = u.user_id " +
                    "WHERE au.thread_id = ? " +
                    "AND au.last_activity > DATE_SUB(NOW(), INTERVAL 5 MINUTE) " +
                    "ORDER BY au.last_activity DESC";
        } else {
            query = "SELECT au.*, u.username, u.avatar_color " +
                    "FROM active_users au " +
                    "JOIN users u ON au.user_id = u.user_id " +
                    "WHERE au.last_activity > DATE_SUB(NOW(), INTERVAL 5 MINUTE) " +
                    "ORDER BY au.last_activity DESC";
        }

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            if (threadId != null && threadId > 0) {
                stmt.setInt(1, threadId);
            }

            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                ActiveUser activeUser = new ActiveUser(
                        rs.getString("session_id"),
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("avatar_color"),
                        rs.getInt("thread_id"),
                        rs.getTimestamp("last_activity"),
                        rs.getString("ip_address")
                );
                activeUsers.add(activeUser);
            }

        } catch (SQLException e) {
            System.err.println("❌ Eroare getActiveUsers: " + e.getMessage());
        }

        return activeUsers;
    }

    // ==================== VOTURI ====================

    public boolean addVote(int userId, Integer threadId, Integer commentId, String voteType) {
        String query = "INSERT INTO votes (user_id, thread_id, comment_id, vote_type) VALUES (?, ?, ?, ?) " +
                "ON DUPLICATE KEY UPDATE vote_type = VALUES(vote_type)";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, userId);
            if (threadId != null) {
                stmt.setInt(2, threadId);
            } else {
                stmt.setNull(2, Types.INTEGER);
            }
            if (commentId != null) {
                stmt.setInt(3, commentId);
            } else {
                stmt.setNull(3, Types.INTEGER);
            }
            stmt.setString(4, voteType);

            int rows = stmt.executeUpdate();

            // Update vote score
            if (threadId != null) {
                updateThreadScore(threadId);
            } else if (commentId != null) {
                updateCommentScore(commentId);
            }

            return rows > 0;

        } catch (SQLException e) {
            System.err.println("❌ Eroare addVote: " + e.getMessage());
            return false;
        }
    }

    private void updateThreadScore(int threadId) {
        String query = "UPDATE threads t " +
                "SET t.vote_score = ( " +
                "  SELECT COUNT(CASE WHEN v.vote_type = 'upvote' THEN 1 END) - " +
                "         COUNT(CASE WHEN v.vote_type = 'downvote' THEN 1 END) " +
                "  FROM votes v " +
                "  WHERE v.thread_id = t.thread_id " +
                ") WHERE t.thread_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("❌ Eroare updateThreadScore: " + e.getMessage());
        }
    }

    private void updateCommentScore(int commentId) {
        String query = "UPDATE comments c " +
                "SET c.vote_score = ( " +
                "  SELECT COUNT(CASE WHEN v.vote_type = 'upvote' THEN 1 END) - " +
                "         COUNT(CASE WHEN v.vote_type = 'downvote' THEN 1 END) " +
                "  FROM votes v " +
                "  WHERE v.comment_id = c.comment_id " +
                ") WHERE c.comment_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, commentId);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("❌ Eroare updateCommentScore: " + e.getMessage());
        }
    }

    // ==================== EDITARE/ȘTERGERE ====================

    public boolean updateThread(int threadId, String title, String content, List<Integer> tagIds) {
        String query = "UPDATE threads SET title = ?, content = ?, updated_at = NOW() WHERE thread_id = ?";

        try {
            connection.setAutoCommit(false);

            // Update thread
            PreparedStatement stmt = connection.prepareStatement(query);
            stmt.setString(1, title);
            stmt.setString(2, content);
            stmt.setInt(3, threadId);

            int rows = stmt.executeUpdate();
            if (rows == 0) {
                connection.rollback();
                return false;
            }

            // Remove old tags
            String deleteTagsQuery = "DELETE FROM thread_tags WHERE thread_id = ?";
            PreparedStatement deleteStmt = connection.prepareStatement(deleteTagsQuery);
            deleteStmt.setInt(1, threadId);
            deleteStmt.executeUpdate();

            // Add new tags
            if (tagIds != null && !tagIds.isEmpty()) {
                String tagQuery = "INSERT INTO thread_tags (thread_id, tag_id) VALUES (?, ?)";
                PreparedStatement tagStmt = connection.prepareStatement(tagQuery);

                for (int tagId : tagIds) {
                    tagStmt.setInt(1, threadId);
                    tagStmt.setInt(2, tagId);
                    tagStmt.addBatch();
                }

                tagStmt.executeBatch();
            }

            connection.commit();
            System.out.println("✅ Thread actualizat: " + title + " (ID: " + threadId + ")");
            return true;

        } catch (SQLException e) {
            try {
                connection.rollback();
            } catch (SQLException ex) {
                System.err.println("❌ Eroare rollback: " + ex.getMessage());
            }
            System.err.println("❌ Eroare updateThread: " + e.getMessage());
            return false;
        } finally {
            try {
                connection.setAutoCommit(true);
            } catch (SQLException e) {
                System.err.println("❌ Eroare setAutoCommit: " + e.getMessage());
            }
        }
    }

    public boolean deleteThread(int threadId) {
        String query = "DELETE FROM threads WHERE thread_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);

            int rows = stmt.executeUpdate();
            System.out.println("✅ Thread șters: ID " + threadId);
            return rows > 0;

        } catch (SQLException e) {
            System.err.println("❌ Eroare deleteThread: " + e.getMessage());
            return false;
        }
    }

    public boolean updateComment(int commentId, String content) {
        String query = "UPDATE comments SET content = ?, is_edited = TRUE, updated_at = NOW() WHERE comment_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setString(1, content);
            stmt.setInt(2, commentId);

            int rows = stmt.executeUpdate();
            System.out.println("✅ Comentariu actualizat: ID " + commentId);
            return rows > 0;

        } catch (SQLException e) {
            System.err.println("❌ Eroare updateComment: " + e.getMessage());
            return false;
        }
    }

    public boolean deleteComment(int commentId) {
        String query = "DELETE FROM comments WHERE comment_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, commentId);

            int rows = stmt.executeUpdate();
            System.out.println("✅ Comentariu șters: ID " + commentId);
            return rows > 0;

        } catch (SQLException e) {
            System.err.println("❌ Eroare deleteComment: " + e.getMessage());
            return false;
        }
    }

    // ==================== METODE NOI ADAUGATE ====================

    // Metodă pentru a verifica dacă utilizatorul este autorul thread-ului
    public boolean isThreadOwner(int threadId, int userId) {
        String query = "SELECT COUNT(*) FROM threads WHERE thread_id = ? AND user_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);
            stmt.setInt(2, userId);

            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Eroare isThreadOwner: " + e.getMessage());
        }

        return false;
    }

    // Metodă pentru a obține thread ID-ul din care face parte un comentariu
    public int getThreadIdForComment(int commentId) {
        String query = "SELECT thread_id FROM comments WHERE comment_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, commentId);

            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("thread_id");
            }
        } catch (SQLException e) {
            System.err.println("❌ Eroare getThreadIdForComment: " + e.getMessage());
        }

        return -1;
    }

    // METODĂ NOUĂ: Căutare utilizatori
    public List<User> searchUsers(String query) {
        List<User> users = new ArrayList<>();
        String sql = "SELECT user_id, username, email, full_name, bio, avatar_color, role " +
                "FROM users WHERE username LIKE ? OR email LIKE ? OR full_name LIKE ? " +
                "LIMIT 20";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            String searchTerm = "%" + query + "%";
            stmt.setString(1, searchTerm);
            stmt.setString(2, searchTerm);
            stmt.setString(3, searchTerm);

            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                users.add(new User(
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("email"),
                        rs.getString("full_name"),
                        rs.getString("bio"),
                        rs.getString("avatar_color"),
                        rs.getString("role")
                ));
            }
        } catch (SQLException e) {
            System.err.println("❌ Eroare searchUsers: " + e.getMessage());
        }
        return users;
    }

    // METODĂ NOUĂ: Obține statistici thread
    public Map<String, Object> getThreadStats(int threadId) {
        Map<String, Object> stats = new HashMap<>();
        String query = "SELECT " +
                "COUNT(DISTINCT c.comment_id) as total_comments, " +
                "COUNT(DISTINCT v.vote_id) as total_votes, " +
                "SUM(CASE WHEN v.vote_type = 'upvote' THEN 1 ELSE 0 END) as upvotes, " +
                "SUM(CASE WHEN v.vote_type = 'downvote' THEN 1 ELSE 0 END) as downvotes, " +
                "COUNT(DISTINCT au.user_id) as current_viewers " +
                "FROM threads t " +
                "LEFT JOIN comments c ON t.thread_id = c.thread_id " +
                "LEFT JOIN votes v ON t.thread_id = v.thread_id " +
                "LEFT JOIN active_users au ON t.thread_id = au.thread_id " +
                "WHERE t.thread_id = ? " +
                "GROUP BY t.thread_id";

        try (PreparedStatement stmt = connection.prepareStatement(query)) {
            stmt.setInt(1, threadId);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                stats.put("total_comments", rs.getInt("total_comments"));
                stats.put("total_votes", rs.getInt("total_votes"));
                stats.put("upvotes", rs.getInt("upvotes"));
                stats.put("downvotes", rs.getInt("downvotes"));
                stats.put("current_viewers", rs.getInt("current_viewers"));
            }
        } catch (SQLException e) {
            System.err.println("❌ Eroare getThreadStats: " + e.getMessage());
        }

        return stats;
    }

    // ==================== INCHIDERE ====================

    public void close() {
        try {
            if (connection != null && !connection.isClosed()) {
                connection.close();
                System.out.println("🔒 Conexiune MySQL închisă");
            }
        } catch (SQLException e) {
            System.err.println("❌ Eroare închidere conexiune: " + e.getMessage());
        }
    }
}