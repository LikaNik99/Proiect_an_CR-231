package shared;

import java.io.Serializable;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;

public class ActiveUser implements Serializable {
    private String sessionId;
    private int userId;
    private String username;
    private String avatarColor;
    private Integer threadId;
    private Timestamp lastActivity;
    private String ipAddress;

    public ActiveUser(String sessionId, int userId, String username,
                      String avatarColor, Integer threadId,
                      Timestamp lastActivity, String ipAddress) {
        this.sessionId = sessionId;
        this.userId = userId;
        this.username = username;
        this.avatarColor = avatarColor;
        this.threadId = threadId;
        this.lastActivity = lastActivity;
        this.ipAddress = ipAddress;
    }

    // Getters
    public String getSessionId() { return sessionId; }
    public int getUserId() { return userId; }
    public String getUsername() { return username; }
    public String getAvatarColor() { return avatarColor; }
    public Integer getThreadId() { return threadId; }
    public Timestamp getLastActivity() { return lastActivity; }
    public String getIpAddress() { return ipAddress; }

    public String getFormattedLastActivity() {
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
        return sdf.format(lastActivity);
    }

    @Override
    public String toString() {
        return username + (threadId != null ? " (în thread)" : " (în meniu)");
    }
}