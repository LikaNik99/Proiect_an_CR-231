package server;

import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;
import java.text.SimpleDateFormat;
import shared.*;

public class ServerMain {
    private static final int PORT = 12345;
    private static DatabaseManager db;
    private static Map<String, ClientHandler> activeClients = new ConcurrentHashMap<>();
    private static ExecutorService threadPool = Executors.newCachedThreadPool();
    private static Logger logger;

    public static void main(String[] args) {
        // Initialize logger
        logger = new Logger();
        logger.log("===========================================");
        logger.log("      FORUM APP SERVER - UTM FCIM");
        logger.log("      Autor: Buga Pavel - CR-231");
        logger.log("      Port: " + PORT);
        logger.log("      Data: " + new SimpleDateFormat("dd.MM.yyyy HH:mm:ss").format(new Date()));
        logger.log("===========================================\n");

        logger.log("🚀 Initializare server...");
        db = new DatabaseManager();

        // Test database connection
        testDatabase();

        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            logger.log("✅ Server pornit pe portul " + PORT);
            logger.log("📍 Accesează: localhost:" + PORT);
            logger.log("⏳ Aștept conexiuni...\n");

            // Start cleanup thread for inactive users
            startCleanupThread();
            // Start log rotation thread
            startLogRotationThread();

            while (true) {
                Socket clientSocket = serverSocket.accept();
                String clientIP = clientSocket.getInetAddress().getHostAddress();
                logger.log("🔗 Client conectat: " + clientIP);

                // CORECTAT: Doar 3 argumente, logger este global
                ClientHandler clientHandler = new ClientHandler(clientSocket, db, activeClients);
                threadPool.execute(clientHandler);
            }

        } catch (IOException e) {
            logger.error("❌ Eroare server: " + e.getMessage());
            e.printStackTrace();
        } finally {
            shutdown();
        }
    }

    private static void testDatabase() {
        logger.log("🧪 Test baza de date...");
        try {
            // Test user authentication
            User testUser = db.authenticateUser("student", "student123");
            if (testUser != null) {
                logger.log("✅ Test autentificare: PASSED (student)");
            }

            // Test thread loading
            List<ForumThread> threads = db.getAllThreads();
            logger.log("✅ Test thread-uri: " + threads.size() + " thread-uri găsite");

            // Test tags
            List<Tag> tags = db.getAllTags();
            logger.log("✅ Test tag-uri: " + tags.size() + " tag-uri găsite");

        } catch (Exception e) {
            logger.error("❌ Test baza de date FAILED: " + e.getMessage());
        }
    }

    private static void startCleanupThread() {
        Timer timer = new Timer(true);
        timer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                try {
                    // Remove clients that haven't sent heartbeat in 2 minutes
                    long cutoff = System.currentTimeMillis() - 120000;
                    Iterator<Map.Entry<String, ClientHandler>> it = activeClients.entrySet().iterator();
                    while (it.hasNext()) {
                        Map.Entry<String, ClientHandler> entry = it.next();
                        if (entry.getValue().getLastHeartbeat() < cutoff) {
                            logger.log("🧹 Curățare client inactiv: " + entry.getKey());
                            entry.getValue().disconnect();
                            it.remove();
                        }
                    }
                } catch (Exception e) {
                    logger.error("❌ Eroare cleanup thread: " + e.getMessage());
                }
            }
        }, 60000, 60000); // Run every minute
    }

    private static void startLogRotationThread() {
        Timer timer = new Timer(true);
        timer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                logger.rotateIfNeeded();
            }
        }, 3600000, 3600000); // Check every hour
    }

    // METODE NOI ADAUGATE
    public static void broadcastToAllClients(String message) {
        for (ClientHandler client : activeClients.values()) {
            client.sendObject(message);
        }
    }

    public static void broadcastToThreadClients(int threadId, String message) {
        for (ClientHandler client : activeClients.values()) {
            if (client.getCurrentThreadId() != null &&
                    client.getCurrentThreadId() == threadId) {
                client.sendObject(message);
            }
        }
    }

    public static void broadcastThreadUpdate(int threadId) {
        ForumThread thread = db.getThreadById(threadId);
        if (thread != null) {
            for (ClientHandler client : activeClients.values()) {
                if (client.getCurrentThreadId() != null && client.getCurrentThreadId() == threadId) {
                    client.sendThreadUpdate(thread);
                }
            }
        }
    }

    public static void broadcastActiveUsers(Integer threadId) {
        List<ActiveUser> activeUsers = db.getActiveUsers(threadId);
        for (ClientHandler client : activeClients.values()) {
            if (threadId == null || (client.getCurrentThreadId() != null && client.getCurrentThreadId().equals(threadId))) {
                client.sendActiveUsers(activeUsers);
            }
        }
    }

    public static void broadcastCommentUpdate(int threadId) {
        logger.log("📢 Broadcasting comment update for thread #" + threadId);
        List<Comment> comments = db.getCommentsForThread(threadId);

        for (ClientHandler client : activeClients.values()) {
            if (client.getCurrentThreadId() != null && client.getCurrentThreadId() == threadId) {
                logger.log("📤 Sending " + comments.size() + " comments to " +
                        (client.getUser() != null ? client.getUser().getUsername() : "unknown"));
                client.sendComments(comments);
            }
        }
    }

    private static void shutdown() {
        logger.log("\n🔴 Închidere server...");

        // Log active clients
        logger.log("👥 Clienți activi: " + activeClients.size());

        // Disconnect all clients
        for (ClientHandler client : activeClients.values()) {
            client.disconnect();
        }
        activeClients.clear();

        // Shutdown thread pool
        threadPool.shutdown();
        try {
            if (!threadPool.awaitTermination(5, TimeUnit.SECONDS)) {
                threadPool.shutdownNow();
            }
        } catch (InterruptedException e) {
            threadPool.shutdownNow();
        }

        // Close database
        if (db != null) {
            db.close();
        }

        // Close logger
        if (logger != null) {
            logger.close();
        }

        logger.log("✅ Server închis corect");
    }

    public static Logger getLogger() {
        return logger;
    }
}