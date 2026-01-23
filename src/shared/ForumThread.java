package shared;

import java.io.Serializable;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;

public class ForumThread implements Serializable {
    private static final long serialVersionUID = 1L;
    private int threadId;
    private int userId;
    private String username;
    private String userAvatarColor;
    private String title;
    private String content;
    private Timestamp createdAt;
    private int viewCount;
    private int voteScore;
    private boolean isPinned;
    private boolean isLocked;
    private int commentCount;

    public ForumThread(int threadId, int userId, String username, String userAvatarColor,
                       String title, String content, Timestamp createdAt,
                       int viewCount, int voteScore, boolean isPinned,
                       boolean isLocked, int commentCount) {
        this.threadId = threadId;
        this.userId = userId;
        this.username = username;
        this.userAvatarColor = userAvatarColor;
        this.title = title;
        this.content = content;
        this.createdAt = createdAt;
        this.viewCount = viewCount;
        this.voteScore = voteScore;
        this.isPinned = isPinned;
        this.isLocked = isLocked;
        this.commentCount = commentCount;
    }

    // Getters
    public int getThreadId() { return threadId; }
    public int getUserId() { return userId; }
    public String getUsername() { return username; }
    public String getUserAvatarColor() { return userAvatarColor; }
    public String getTitle() { return title; }
    public String getContent() { return content; }
    public Timestamp getCreatedAt() { return createdAt; }
    public int getViewCount() { return viewCount; }
    public int getVoteScore() { return voteScore; }
    public boolean isPinned() { return isPinned; }
    public boolean isLocked() { return isLocked; }
    public int getCommentCount() { return commentCount; }

    public String getFormattedDate() {
        SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy HH:mm");
        return sdf.format(createdAt);
    }

    @Override
    public String toString() {
        return (isPinned ? "📌 " : "") + title + " (" + commentCount + " comentarii)";
    }
}