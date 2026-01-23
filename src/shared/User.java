package shared;

import java.io.Serializable;

public class User implements Serializable {
    private static final long serialVersionUID = 1L;
    private int userId;
    private String username;
    private String email;
    private String fullName;
    private String bio;
    private String avatarColor;
    private String role;

    public User(int userId, String username, String email, String fullName,
                String bio, String avatarColor, String role) {
        this.userId = userId;
        this.username = username;
        this.email = email;
        this.fullName = fullName;
        this.bio = bio;
        this.avatarColor = avatarColor;
        this.role = role;
    }

    // Getters
    public int getUserId() { return userId; }
    public String getUsername() { return username; }
    public String getEmail() { return email; }
    public String getFullName() { return fullName; }
    public String getBio() { return bio; }
    public String getAvatarColor() { return avatarColor; }
    public String getRole() { return role; }

    @Override
    public String toString() {
        return username;
    }
}