package shared;

import java.io.Serializable;

public class Tag implements Serializable {
    private static final long serialVersionUID = 1L;
    private int tagId;
    private String name;
    private String color;
    private String description;

    public Tag(int tagId, String name, String color, String description) {
        this.tagId = tagId;
        this.name = name;
        this.color = color;
        this.description = description;
    }

    // Getters
    public int getTagId() { return tagId; }
    public String getName() { return name; }
    public String getColor() { return color; }
    public String getDescription() { return description; }

    @Override
    public String toString() {
        return name;
    }
}