package client;

import shared.Comment;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.util.List;
import java.util.*;
import java.util.function.Consumer;
import java.util.function.IntConsumer;

/**
 * A self-contained comments view designed to be robust and predictable.
 * It renders a threaded list of comments with indentation for replies
 * and exposes callbacks for reply and voting actions.
 */
public class CommentsPanel extends JPanel {
    private final Color DARK_BG = new Color(34, 40, 49);
    private final Color CARD_BG = new Color(57, 62, 70);
    private final Color TEXT_COLOR = new Color(238, 238, 238);
    private final Color BORDER_COLOR = new Color(76, 82, 92);
    private final Color SECONDARY_COLOR = new Color(66, 133, 244);
    private final Color SUCCESS_COLOR = new Color(46, 204, 113);
    private final Color DANGER_COLOR = new Color(231, 76, 60);
    private final Color REPLY_BG = new Color(50, 55, 63);

    private final JPanel listPanel;
    private final JScrollPane scrollPane;

    private List<Comment> currentComments = Collections.emptyList();

    private final Consumer<Comment> onReply;
    private final IntConsumer onUpvote;
    private final IntConsumer onDownvote;

    public CommentsPanel(Consumer<Comment> onReply,
                         IntConsumer onUpvote,
                         IntConsumer onDownvote) {
        super(new BorderLayout());
        this.onReply = onReply;
        this.onUpvote = onUpvote;
        this.onDownvote = onDownvote;

        setBackground(DARK_BG);

        listPanel = new JPanel();
        listPanel.setLayout(new BoxLayout(listPanel, BoxLayout.Y_AXIS));
        listPanel.setBackground(DARK_BG);
        listPanel.setBorder(new EmptyBorder(10, 0, 10, 0));

        scrollPane = new JScrollPane(listPanel);
        scrollPane.setBorder(BorderFactory.createLineBorder(BORDER_COLOR, 1));
        scrollPane.getViewport().setBackground(DARK_BG);
        scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
        scrollPane.getVerticalScrollBar().setUnitIncrement(16);

        add(scrollPane, BorderLayout.CENTER);

        renderEmptyState();
    }

    public void clear() {
        setComments(Collections.emptyList());
    }

    public void setComments(List<Comment> comments) {
        if (comments == null) comments = Collections.emptyList();
        this.currentComments = comments;
        rebuild();
    }

    private void rebuild() {
        JScrollBar vBar = scrollPane.getVerticalScrollBar();
        int prev = vBar != null ? vBar.getValue() : 0;

        listPanel.removeAll();

        if (currentComments.isEmpty()) {
            renderEmptyState();
        } else {
            Map<Integer, List<Comment>> children = new HashMap<>();
            List<Comment> roots = new ArrayList<>();

            for (Comment c : currentComments) {
                if (c.getParentCommentId() == null) {
                    roots.add(c);
                } else {
                    children.computeIfAbsent(c.getParentCommentId(), k -> new ArrayList<>()).add(c);
                }
            }

            roots.sort((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()));

            for (Comment root : roots) {
                renderCommentRecursive(root, children, 0);
            }
        }

        listPanel.revalidate();
        listPanel.repaint();

        SwingUtilities.invokeLater(() -> {
            if (vBar != null) {
                int max = vBar.getMaximum() - vBar.getVisibleAmount();
                vBar.setValue(Math.min(prev, Math.max(0, max)));
            }
        });
    }

    private void renderEmptyState() {
        listPanel.removeAll();
        JLabel noCommentsLabel = new JLabel(
                "<html><div style='text-align: center; padding: 40px;'>" +
                        "<h3 style='color: #95a5a6;'>💭 Nu există comentarii încă</h3>" +
                        "<p style='color: #7f8c8d;'>Fii primul care comentează!</p>" +
                        "</div></html>",
                SwingConstants.CENTER
        );
        noCommentsLabel.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        noCommentsLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        listPanel.add(noCommentsLabel);
    }

    private void renderCommentRecursive(Comment comment, Map<Integer, List<Comment>> children, int level) {
        JPanel card = createCommentCard(comment, level);
        card.setAlignmentX(Component.LEFT_ALIGNMENT);
        listPanel.add(card);
        listPanel.add(Box.createVerticalStrut(10));

        List<Comment> replies = children.get(comment.getCommentId());
        if (replies != null && !replies.isEmpty()) {
            replies.sort(Comparator.comparing(Comment::getCreatedAt));
            for (Comment reply : replies) {
                renderCommentRecursive(reply, children, level + 1);
            }
        }
    }

    private JPanel createCommentCard(Comment c, int level) {
        JPanel card = new JPanel(new BorderLayout(5, 5));
        card.setBackground(CARD_BG);
        card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                new EmptyBorder(15, 15 + (level * 24), 15, 15)
        ));

        // Header (user + date)
        JPanel header = new JPanel(new BorderLayout());
        header.setOpaque(false);

        JPanel left = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 0));
        left.setOpaque(false);

        // Avatar with user color
        JLabel avatar = new JLabel("👤");
        avatar.setFont(new Font("Segoe UI Emoji", Font.PLAIN, 16));

        JLabel username = new JLabel(c.getUsername());
        username.setFont(new Font("Segoe UI", Font.BOLD, 12));
        username.setForeground(TEXT_COLOR);

        left.add(avatar);
        left.add(username);

        JPanel right = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        right.setOpaque(false);

        if (c.isEdited()) {
            JLabel edited = new JLabel("(editat)");
            edited.setFont(new Font("Segoe UI", Font.ITALIC, 10));
            edited.setForeground(Color.GRAY);
            right.add(edited);
        }

        JLabel date = new JLabel("🕐 " + c.getFormattedDate());
        date.setFont(new Font("Segoe UI", Font.PLAIN, 10));
        date.setForeground(Color.GRAY);
        right.add(date);

        header.add(left, BorderLayout.WEST);
        header.add(right, BorderLayout.EAST);

        // Content
        JTextArea content = new JTextArea(c.getContent());
        content.setEditable(false);
        content.setLineWrap(true);
        content.setWrapStyleWord(true);
        content.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        content.setForeground(TEXT_COLOR);
        content.setBackground(CARD_BG);
        content.setBorder(new EmptyBorder(8, 5, 8, 5));

        // Actions panel with buttons
        JPanel actions = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 0));
        actions.setOpaque(false);

        JButton replyBtn = smallButton("↪️ Răspunde", SECONDARY_COLOR);
        replyBtn.addActionListener(e -> {
            if (onReply != null) {
                onReply.accept(c);
                // Show feedback
                replyBtn.setText("↪️ Răspunzi...");
                javax.swing.Timer timer = new javax.swing.Timer(2000, ev -> {
                    replyBtn.setText("↪️ Răspunde");
                    ((javax.swing.Timer)ev.getSource()).stop();
                });
                timer.setRepeats(false);
                timer.start();
            }
        });

        JButton upBtn = smallButton("⬆️ (" + c.getVoteScore() + ")", SUCCESS_COLOR);
        upBtn.addActionListener(e -> {
            if (onUpvote != null) {
                onUpvote.accept(c.getCommentId());
                // Visual feedback
                upBtn.setBackground(new Color(SUCCESS_COLOR.getRed(), SUCCESS_COLOR.getGreen(), SUCCESS_COLOR.getBlue(), 100));
                javax.swing.Timer timer = new javax.swing.Timer(500, ev -> {
                    upBtn.setBackground(new Color(SUCCESS_COLOR.getRed(), SUCCESS_COLOR.getGreen(), SUCCESS_COLOR.getBlue(), 60));
                    ((javax.swing.Timer)ev.getSource()).stop();
                });
                timer.setRepeats(false);
                timer.start();
            }
        });

        JButton downBtn = smallButton("⬇️", DANGER_COLOR);
        downBtn.addActionListener(e -> {
            if (onDownvote != null) {
                onDownvote.accept(c.getCommentId());
                // Visual feedback
                downBtn.setBackground(new Color(DANGER_COLOR.getRed(), DANGER_COLOR.getGreen(), DANGER_COLOR.getBlue(), 100));
                javax.swing.Timer timer = new javax.swing.Timer(500, ev -> {
                    downBtn.setBackground(new Color(DANGER_COLOR.getRed(), DANGER_COLOR.getGreen(), DANGER_COLOR.getBlue(), 60));
                    ((javax.swing.Timer)ev.getSource()).stop();
                });
                timer.setRepeats(false);
                timer.start();
            }
        });

        actions.add(replyBtn);
        actions.add(upBtn);
        actions.add(downBtn);

        card.add(header, BorderLayout.NORTH);
        card.add(content, BorderLayout.CENTER);
        card.add(actions, BorderLayout.SOUTH);

        return card;
    }

    private JButton smallButton(String text, Color baseColor) {
        JButton btn = new JButton(text);
        btn.setFocusPainted(false);
        btn.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        btn.setBackground(new Color(baseColor.getRed(), baseColor.getGreen(), baseColor.getBlue(), 60));
        btn.setForeground(TEXT_COLOR);
        btn.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                new EmptyBorder(4, 8, 4, 8)
        ));
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));

        // Hover effect
        btn.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseEntered(java.awt.event.MouseEvent e) {
                btn.setBackground(new Color(baseColor.getRed(), baseColor.getGreen(), baseColor.getBlue(), 80));
            }

            @Override
            public void mouseExited(java.awt.event.MouseEvent e) {
                btn.setBackground(new Color(baseColor.getRed(), baseColor.getGreen(), baseColor.getBlue(), 60));
            }
        });

        return btn;
    }
}