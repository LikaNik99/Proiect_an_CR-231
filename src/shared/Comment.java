package shared;

import java.io.Serializable;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;

public class Comment implements Serializable {
    private static final long serialVersionUID = 1L;
    private int commentId;
    private int threadId;
    private int userId;
    private String username;
    private String userAvatarColor;
    private Integer parentCommentId;
    private String content;
    private Timestamp createdAt;
    private int voteScore;
    private boolean isEdited;

    public Comment(int commentId, int threadId, int userId, String username,
                   String userAvatarColor, Integer parentCommentId,
                   String content, Timestamp createdAt, int voteScore,
                   boolean isEdited) {
        this.commentId = commentId;
        this.threadId = threadId;
        this.userId = userId;
        this.username = username;
        this.userAvatarColor = userAvatarColor;
        this.parentCommentId = parentCommentId;
        this.content = content;
        this.createdAt = createdAt;
        this.voteScore = voteScore;
        this.isEdited = isEdited;
    }

    // Getters
    public int getCommentId() { return commentId; }
    public int getThreadId() { return threadId; }
    public int getUserId() { return userId; }
    public String getUsername() { return username; }
    public String getUserAvatarColor() { return userAvatarColor; }
    public Integer getParentCommentId() { return parentCommentId; }
    public String getContent() { return content; }
    public Timestamp getCreatedAt() { return createdAt; }
    public int getVoteScore() { return voteScore; }
    public boolean isEdited() { return isEdited; }

    public String getFormattedDate() {
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm dd.MM");
        return sdf.format(createdAt);
    }

    public boolean isReply() {
        return parentCommentId != null;
    }

    @Override
    public String toString() {
        return username + ": " + content.substring(0, Math.min(50, content.length())) + "...";
    }
}