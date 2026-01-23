package server;

import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;
import shared.*;

public class ClientHandler implements Runnable {
    private Socket socket;
    private DatabaseManager db;
    private Map<String, ClientHandler> activeClients;

    private ObjectOutputStream objectOut;
    private ObjectInputStream objectIn;

    private User user;
    private String sessionId;
    private long lastHeartbeat;
    private Integer currentThreadId;

    public ClientHandler(Socket socket, DatabaseManager db, Map<String, ClientHandler> activeClients) {
        this.socket = socket;
        this.db = db;
        this.activeClients = activeClients;
        this.lastHeartbeat = System.currentTimeMillis();

        try {
            // Setup streams - IMPORTANT: ObjectOutputStream first!
            objectOut = new ObjectOutputStream(socket.getOutputStream());
            objectOut.flush();
            objectIn = new ObjectInputStream(socket.getInputStream());

        } catch (IOException e) {
            System.err.println("❌ Eroare setup stream-uri: " + e.getMessage());
            ServerMain.getLogger().error("Eroare setup stream-uri: " + e.getMessage());
        }
    }

    @Override
    public void run() {
        ServerMain.getLogger().log("🎬 ClientHandler pornit pentru: " + socket.getInetAddress());

        try {
            // Send welcome message
            sendObject("SERVER:Bine ai venit la Forum App UTM FCIM!");

            Object request;
            while ((request = objectIn.readObject()) != null) {
                if (request instanceof String) {
                    String reqString = (String) request;
                    ServerMain.getLogger().log("📥 Primit de la " + (user != null ? user.getUsername() : "anonim") +
                            ": " + reqString.substring(0, Math.min(100, reqString.length())));

                    lastHeartbeat = System.currentTimeMillis();
                    processRequest(reqString);

                    if (!socket.isConnected()) {
                        break;
                    }
                } else {
                    ServerMain.getLogger().error("❌ Request necunoscut de tip: " + request.getClass().getName());
                }
            }

        } catch (EOFException e) {
            ServerMain.getLogger().log("📴 Client disconnected: " +
                    (user != null ? user.getUsername() : socket.getInetAddress()));
        } catch (IOException e) {
            if (!socket.isClosed()) {
                ServerMain.getLogger().error("❌ Eroare client handler: " + e.getMessage());
            }
        } catch (ClassNotFoundException e) {
            ServerMain.getLogger().error("❌ Eroare clasă necunoscută: " + e.getMessage());
        } finally {
            disconnect();
        }
    }

    private void processRequest(String request) {
        String[] parts = request.split(":", 5);
        String command = parts[0];

        try {
            switch (command) {
                case "LOGIN":
                    handleLogin(parts);
                    break;
                case "REGISTER":
                    handleRegister(parts);
                    break;
                case "LOGOUT":
                    handleLogout();
                    break;
                case "GET_THREADS":
                    handleGetThreads();
                    break;
                case "GET_THREAD":
                    handleGetThread(parts);
                    break;
                case "GET_COMMENTS":
                    handleGetComments(parts);
                    break;
                case "GET_ACTIVE_USERS":
                    handleGetActiveUsers(parts);
                    break;
                case "ADD_COMMENT":
                    handleAddComment(parts);
                    break;
                case "CREATE_THREAD":
                    handleCreateThread(parts);
                    break;
                case "UPDATE_ACTIVITY":
                    handleHeartbeat(parts);
                    break;
                case "HEARTBEAT":
                    handleHeartbeat(parts);
                    break;
                case "VOTE":
                    handleVote(parts);
                    break;
                case "EDIT_THREAD":
                    handleEditThread(parts);
                    break;
                case "DELETE_THREAD":
                    handleDeleteThread(parts);
                    break;
                case "EDIT_COMMENT":
                    handleEditComment(parts);
                    break;
                case "DELETE_COMMENT":
                    handleDeleteComment(parts);
                    break;
                // METODĂ NOUĂ ADAUGATĂ
                case "GET_THREAD_STATS":
                    handleGetThreadStats(parts);
                    break;
                default:
                    sendObject("ERROR:Comandă necunoscută: " + command);
            }
        } catch (Exception e) {
            ServerMain.getLogger().error("❌ Eroare procesare request: " + e.getMessage());
            e.printStackTrace();
            sendObject("ERROR:Eroare procesare: " + e.getMessage());
        }
    }

    // METODĂ NOUĂ ADAUGATĂ
    private void handleGetThreadStats(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length != 2) {
            sendObject("ERROR:Format invalid. Folosește: GET_THREAD_STATS:threadId");
            return;
        }

        try {
            int threadId = Integer.parseInt(parts[1]);
            // Obtine statistici pentru thread
            Map<String, Object> stats = db.getThreadStats(threadId);

            try {
                objectOut.writeObject("THREAD_STATS");
                objectOut.writeObject(stats);
                objectOut.flush();
                ServerMain.getLogger().log("📤 Trimise statistici pentru thread #" + threadId);
            } catch (IOException e) {
                ServerMain.getLogger().error("❌ Eroare trimitere stats: " + e.getMessage());
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:ID thread invalid");
        }
    }

    private void handleLogin(String[] parts) {
        if (parts.length != 3) {
            sendObject("ERROR:Format invalid. Folosește: LOGIN:username:password");
            return;
        }

        String username = parts[1];
        String password = parts[2];

        User authenticatedUser = db.authenticateUser(username, password);
        if (authenticatedUser != null) {
            this.user = authenticatedUser;
            this.sessionId = "sess_" + System.currentTimeMillis() + "_" + user.getUserId();

            // Add to active clients
            activeClients.put(sessionId, this);

            // Update activity
            db.updateUserActivity(sessionId, user.getUserId(), null,
                    socket.getInetAddress().getHostAddress());

            sendObject("SUCCESS:Autentificare reușită:" + user.getUsername());

            // Send user object and session id
            try {
                objectOut.writeObject(user);
                objectOut.writeObject("SESSION:" + sessionId);
                objectOut.flush();
            } catch (IOException e) {
                ServerMain.getLogger().error("❌ Eroare trimitere user/session: " + e.getMessage());
            }

            ServerMain.getLogger().log("✅ " + user.getUsername() + " autentificat (session: " + sessionId + ")");

        } else {
            sendObject("ERROR:Username sau parolă incorectă");
        }
    }

    private void handleRegister(String[] parts) {
        if (parts.length != 5) {
            sendObject("ERROR:Format invalid. Folosește: REGISTER:username:password:email:fullName");
            return;
        }

        String username = parts[1];
        String password = parts[2];
        String email = parts[3];
        String fullName = parts[4];

        boolean success = db.registerUser(username, password, email, fullName);
        if (success) {
            sendObject("SUCCESS:Cont creat cu succes! Acum te poți autentifica.");
        } else {
            sendObject("ERROR:Eroare la crearea contului. Username sau email deja existent.");
        }
    }

    private void handleLogout() {
        if (sessionId != null) {
            db.removeUserActivity(sessionId);
            activeClients.remove(sessionId);
            ServerMain.getLogger().log("👋 " + (user != null ? user.getUsername() : "Unknown") + " logged out");
        }
        sendObject("SUCCESS:Deconectat cu succes");
    }

    private void handleGetThreads() {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        List<ForumThread> threads = db.getAllThreads();
        try {
            objectOut.writeObject(threads);
            objectOut.flush();
            ServerMain.getLogger().log("📤 Trimis " + threads.size() + " thread-uri către " + user.getUsername());
        } catch (IOException e) {
            ServerMain.getLogger().error("❌ Eroare trimitere thread-uri: " + e.getMessage());
        }
    }

    private void handleGetThread(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length != 2) {
            sendObject("ERROR:Format invalid. Folosește: GET_THREAD:threadId");
            return;
        }

        try {
            int threadId = Integer.parseInt(parts[1]);
            ForumThread thread = db.getThreadById(threadId);

            if (thread != null) {
                this.currentThreadId = threadId;

                // Send thread
                try {
                    objectOut.writeObject(thread);
                    objectOut.flush();
                } catch (IOException e) {
                    ServerMain.getLogger().error("❌ Eroare trimitere thread: " + e.getMessage());
                }

                ServerMain.getLogger().log("📤 Trimis thread #" + threadId + " către " + user.getUsername());

                // Update user activity
                db.updateUserActivity(sessionId, user.getUserId(), threadId,
                        socket.getInetAddress().getHostAddress());

                // Notify other clients
                ServerMain.broadcastActiveUsers(threadId);

            } else {
                sendObject("ERROR:Thread-ul nu există");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:ID thread invalid");
        }
    }

    private void handleGetComments(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length != 2) {
            sendObject("ERROR:Format invalid. Folosește: GET_COMMENTS:threadId");
            return;
        }

        try {
            int threadId = Integer.parseInt(parts[1]);
            List<Comment> comments = db.getCommentsForThread(threadId);

            try {
                objectOut.writeObject("COMMENTS_UPDATE");
                objectOut.writeObject(comments);
                objectOut.flush();
                ServerMain.getLogger().log("📤 Trimis " + comments.size() + " comentarii pentru thread #" + threadId);
            } catch (IOException e) {
                ServerMain.getLogger().error("❌ Eroare trimitere comentarii: " + e.getMessage());
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:ID thread invalid");
        }
    }

    private void handleGetActiveUsers(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        Integer threadId = null;
        if (parts.length > 1 && !parts[1].equals("null")) {
            try {
                threadId = Integer.parseInt(parts[1]);
            } catch (NumberFormatException e) {
                // threadId remains null
            }
        }

        List<ActiveUser> activeUsers = db.getActiveUsers(threadId);
        try {
            objectOut.writeObject(activeUsers);
            objectOut.flush();
        } catch (IOException e) {
            ServerMain.getLogger().error("❌ Eroare trimitere utilizatori activi: " + e.getMessage());
        }
    }

    private void handleAddComment(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length < 4) {
            sendObject("ERROR:Format invalid. Folosește: ADD_COMMENT:threadId:userId:content sau ADD_COMMENT:threadId:userId:content:parentCommentId");
            return;
        }

        try {
            int threadId = Integer.parseInt(parts[1]);
            int userId = Integer.parseInt(parts[2]);
            String content = parts[3];

            Integer parentCommentId = null;
            if (parts.length >= 5 && !parts[4].equals("null")) {
                parentCommentId = Integer.parseInt(parts[4]);
            }

            // Verify user is authorized
            if (userId != user.getUserId()) {
                sendObject("ERROR:Nu ești autorizat să postezi ca alt utilizator");
                return;
            }

            boolean success = db.addComment(threadId, userId, content, parentCommentId);
            if (success) {
                sendObject("SUCCESS:Comentariu adăugat");
                ServerMain.getLogger().log("✅ " + user.getUsername() + " a adăugat comentariu la thread #" + threadId);

                // Broadcast comment update to all clients viewing this thread
                ServerMain.broadcastCommentUpdate(threadId);
                // Also broadcast thread stats update (e.g., comment count)
                ServerMain.broadcastThreadUpdate(threadId);
                // Ask all clients to refresh their threads list (counts, ordering)
                for (ClientHandler client : activeClients.values()) {
                    client.sendObject("REFRESH_THREADS");
                }

            } else {
                sendObject("ERROR:Eroare la adăugarea comentariului");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:Parametri invalizi");
        }
    }

    private void handleCreateThread(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length < 4) {
            sendObject("ERROR:Format invalid. Folosește: CREATE_THREAD:userId:title:content:tag1,tag2,...");
            return;
        }

        try {
            int userId = Integer.parseInt(parts[1]);
            String title = parts[2];
            String content = parts[3];
            String tagsStr = parts.length > 4 ? parts[4] : "";

            // Verify user
            if (userId != user.getUserId()) {
                sendObject("ERROR:Nu ești autorizat să creezi thread-uri ca alt utilizator");
                return;
            }

            // Parse tag IDs
            List<Integer> tagIds = new ArrayList<>();
            if (!tagsStr.isEmpty()) {
                String[] tagArray = tagsStr.split(",");
                for (String tag : tagArray) {
                    try {
                        tagIds.add(Integer.parseInt(tag.trim()));
                    } catch (NumberFormatException e) {
                        // Ignore invalid tags
                    }
                }
            }

            boolean success = db.createThread(userId, title, content, tagIds);
            if (success) {
                sendObject("SUCCESS:Thread creat cu succes");

                // Refresh thread list for all clients
                for (ClientHandler client : activeClients.values()) {
                    client.sendObject("REFRESH_THREADS");
                }

            } else {
                sendObject("ERROR:Eroare la crearea thread-ului");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:Parametri invalizi");
        }
    }

    private void handleHeartbeat(String[] parts) {
        if (parts.length >= 4) {
            try {
                String session = parts[1];
                int userId = Integer.parseInt(parts[2]);
                String threadIdStr = parts[3];

                Integer threadId = null;
                if (!threadIdStr.equals("null")) {
                    threadId = Integer.parseInt(threadIdStr);
                    this.currentThreadId = threadId;
                }

                db.updateUserActivity(session, userId, threadId,
                        socket.getInetAddress().getHostAddress());

                sendObject("HEARTBEAT_OK");

                // Update active users display
                if (threadId != null) {
                    ServerMain.broadcastActiveUsers(threadId);
                }

            } catch (NumberFormatException e) {
                // Ignore
            }
        }
    }

    private void handleVote(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length != 5) {
            sendObject("ERROR:Format invalid. Folosește: VOTE:userId:threadId:commentId:voteType");
            return;
        }

        try {
            int userId = Integer.parseInt(parts[1]);
            String threadIdStr = parts[2];
            String commentIdStr = parts[3];
            String voteType = parts[4];

            // Verify user
            if (userId != user.getUserId()) {
                sendObject("ERROR:Nu ești autorizat să votezi ca alt utilizator");
                return;
            }

            Integer threadId = null;
            Integer commentId = null;

            if (!threadIdStr.equals("null")) {
                threadId = Integer.parseInt(threadIdStr);
            }
            if (!commentIdStr.equals("null")) {
                commentId = Integer.parseInt(commentIdStr);
            }

            boolean success = db.addVote(userId, threadId, commentId, voteType);
            if (success) {
                sendObject("SUCCESS:Vot înregistrat");

                // Broadcast update if voting on a thread
                if (threadId != null) {
                    ServerMain.broadcastThreadUpdate(threadId);
                }

            } else {
                sendObject("ERROR:Eroare la înregistrarea votului");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:Parametri invalizi");
        }
    }

    // NOILE METODE PENTRU EDITARE/ȘTERGERE

    private void handleEditThread(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length < 5) {
            sendObject("ERROR:Format invalid. Folosește: EDIT_THREAD:threadId:userId:title:content:tags");
            return;
        }

        try {
            int threadId = Integer.parseInt(parts[1]);
            int userId = Integer.parseInt(parts[2]);
            String title = parts[3];
            String content = parts[4];
            String tagsStr = parts.length > 5 ? parts[5] : "";

            // Verify permissions
            if (userId != user.getUserId() && !user.getRole().equals("admin")) {
                sendObject("ERROR:Nu ai permisiunea să editezi acest thread");
                return;
            }

            // Parse tags
            List<Integer> tagIds = new ArrayList<>();
            if (!tagsStr.isEmpty()) {
                String[] tagArray = tagsStr.split(",");
                for (String tag : tagArray) {
                    try {
                        tagIds.add(Integer.parseInt(tag.trim()));
                    } catch (NumberFormatException e) {
                        // Ignore invalid tags
                    }
                }
            }

            boolean success = db.updateThread(threadId, title, content, tagIds);
            if (success) {
                sendObject("SUCCESS:Thread actualizat");

                // Broadcast update
                ServerMain.broadcastThreadUpdate(threadId);
                ServerMain.broadcastCommentUpdate(threadId);

            } else {
                sendObject("ERROR:Eroare la actualizarea thread-ului");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:Parametri invalizi");
        }
    }

    private void handleDeleteThread(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length != 3) {
            sendObject("ERROR:Format invalid. Folosește: DELETE_THREAD:threadId:userId");
            return;
        }

        try {
            int threadId = Integer.parseInt(parts[1]);
            int userId = Integer.parseInt(parts[2]);

            // Verify permissions
            boolean isOwner = db.isThreadOwner(threadId, userId);
            boolean isAdmin = user.getRole().equals("admin");

            if (!isOwner && !isAdmin) {
                sendObject("ERROR:Nu ai permisiunea să ștergi acest thread");
                return;
            }

            boolean success = db.deleteThread(threadId);
            if (success) {
                sendObject("SUCCESS:Thread șters");

                // Notify all clients to refresh
                for (ClientHandler client : activeClients.values()) {
                    client.sendObject("REFRESH_THREADS");
                }

            } else {
                sendObject("ERROR:Eroare la ștergerea thread-ului");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:Parametri invalizi");
        }
    }

    private void handleEditComment(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length != 4) {
            sendObject("ERROR:Format invalid. Folosește: EDIT_COMMENT:commentId:userId:content");
            return;
        }

        try {
            int commentId = Integer.parseInt(parts[1]);
            int userId = Integer.parseInt(parts[2]);
            String content = parts[3];

            // Verify permissions
            if (userId != user.getUserId() && !user.getRole().equals("admin")) {
                sendObject("ERROR:Nu ai permisiunea să editezi acest comentariu");
                return;
            }

            boolean success = db.updateComment(commentId, content);
            if (success) {
                sendObject("SUCCESS:Comentariu actualizat");
                // Get thread ID from comment and broadcast update
                int threadId = db.getThreadIdForComment(commentId);
                if (threadId > 0) {
                    ServerMain.broadcastCommentUpdate(threadId);
                }
            } else {
                sendObject("ERROR:Eroare la actualizarea comentariului");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:Parametri invalizi");
        }
    }

    private void handleDeleteComment(String[] parts) {
        if (user == null) {
            sendObject("ERROR:Necesită autentificare");
            return;
        }

        if (parts.length != 3) {
            sendObject("ERROR:Format invalid. Folosește: DELETE_COMMENT:commentId:userId");
            return;
        }

        try {
            int commentId = Integer.parseInt(parts[1]);
            int userId = Integer.parseInt(parts[2]);

            // Get thread ID before deleting (to broadcast update)
            int threadId = db.getThreadIdForComment(commentId);

            // Verify permissions
            if (userId != user.getUserId() && !user.getRole().equals("admin")) {
                sendObject("ERROR:Nu ai permisiunea să ștergi acest comentariu");
                return;
            }

            boolean success = db.deleteComment(commentId);
            if (success) {
                sendObject("SUCCESS:Comentariu șters");
                // Broadcast update pentru thread-ul respectiv
                if (threadId > 0) {
                    ServerMain.broadcastCommentUpdate(threadId);
                }
            } else {
                sendObject("ERROR:Eroare la ștergerea comentariului");
            }

        } catch (NumberFormatException e) {
            sendObject("ERROR:Parametri invalizi");
        }
    }

    public void sendThreadUpdate(ForumThread thread) {
        if (currentThreadId != null && currentThreadId == thread.getThreadId()) {
            try {
                objectOut.writeObject("THREAD_UPDATE");
                objectOut.writeObject(thread);
                objectOut.flush();
            } catch (IOException e) {
                ServerMain.getLogger().error("❌ Eroare trimitere thread update: " + e.getMessage());
            }
        }
    }

    public void sendActiveUsers(List<ActiveUser> activeUsers) {
        try {
            objectOut.writeObject("ACTIVE_USERS_UPDATE");
            objectOut.writeObject(activeUsers);
            objectOut.flush();
        } catch (IOException e) {
            ServerMain.getLogger().error("❌ Eroare trimitere active users: " + e.getMessage());
        }
    }

    // Metodă specială pentru trimiterea comentariilor
    public void sendComments(List<Comment> comments) {
        try {
            objectOut.writeObject("COMMENTS_UPDATE");
            objectOut.writeObject(comments);
            objectOut.flush();
            ServerMain.getLogger().log("📤 Trimis " + comments.size() + " comentarii către " +
                    (user != null ? user.getUsername() : "anonim"));
        } catch (IOException e) {
            ServerMain.getLogger().error("❌ Eroare trimitere comentarii: " + e.getMessage());
        }
    }

    public void sendObject(Object obj) {
        try {
            objectOut.writeObject(obj);
            objectOut.flush();
        } catch (IOException e) {
            ServerMain.getLogger().error("❌ Eroare trimitere obiect: " + e.getMessage());
            disconnect();
        }
    }

    public void disconnect() {
        ServerMain.getLogger().log("👋 Deconectare client: " +
                (user != null ? user.getUsername() : socket.getInetAddress()));

        if (sessionId != null) {
            db.removeUserActivity(sessionId);
            activeClients.remove(sessionId);

            // Notify other clients if user was in a thread
            if (currentThreadId != null) {
                ServerMain.broadcastActiveUsers(currentThreadId);
            }
        }

        try {
            if (objectOut != null) {
                objectOut.close();
            }
            if (objectIn != null) {
                objectIn.close();
            }
            if (socket != null && !socket.isClosed()) {
                socket.close();
            }
        } catch (IOException e) {
            ServerMain.getLogger().error("❌ Eroare închidere socket: " + e.getMessage());
        }
    }

    public long getLastHeartbeat() {
        return lastHeartbeat;
    }

    public User getUser() {
        return user;
    }

    public Integer getCurrentThreadId() {
        return currentThreadId;
    }
}