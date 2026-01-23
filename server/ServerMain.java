package server;

import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class ServerMain {
    private static final int PORT = 5000;
    public static List<ClientHandler> handlers = Collections.synchronizedList(new ArrayList<>());
    private static GameLogic gameLogic = new GameLogic(); 

    public static void main(String[] args) {
        DatabaseManager.initializeDatabase(); 

        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("✅ SERVER ROYAL BLACKJACK ACTIV - Port: " + PORT);

            while (true) {
                Socket socket = serverSocket.accept();
                ClientHandler handler = new ClientHandler(socket, gameLogic);
                handlers.add(handler);
                handler.start();
                
                broadcastGameState();
                broadcastTableList();
            }
        } catch (Exception e) {
            System.err.println("Eroare Server: " + e.getMessage());
        }
    }

    public static void broadcastGameState() {
        synchronized (handlers) {
            for (ClientHandler handler : handlers) {
                handler.sendGameState();
            }
        }
    }

    public static void broadcastTableList() {
        synchronized (handlers) {
            for (ClientHandler handler : handlers) {
                handler.sendTableList();
            }
        }
    }
    
    public static void removeHandler(ClientHandler handler) {
        handlers.remove(handler);
        gameLogic.removePlayer(handler.getPlayerId()); 
        broadcastGameState(); 
    }

    public static void broadcastChat(String msg) {
        synchronized(handlers) {
            for(ClientHandler h : handlers) h.sendChatMessage(msg);
        }
    }

    // FIX: Implementarea metodei necesare pentru misiuni
    public static String getUserById(int playerId) {
        synchronized (handlers) {
            for (ClientHandler handler : handlers) {
                if (handler.getPlayerId() == playerId) {
                    return handler.username;
                }
            }
        }
        return "Unknown";
    }
}