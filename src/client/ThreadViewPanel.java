package client;

import shared.*;
import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.util.List;

public class ThreadViewPanel extends JPanel {
    private final Color DARK_BG = new Color(34, 40, 49);
    private final Color CARD_BG = new Color(57, 62, 70);
    private final Color TEXT_COLOR = new Color(238, 238, 238);
    private final Color BORDER_COLOR = new Color(76, 82, 92);
    private final Color PRIMARY_COLOR = new Color(59, 89, 152);
    private final Color SUCCESS_COLOR = new Color(46, 204, 113);
    private final Color DANGER_COLOR = new Color(231, 76, 60);

    private ForumThread thread;
    private User currentUser;
    private CommentsPanel commentsPanel;
    private OnlineUsersPanel onlineUsersPanel;

    // Callback-uri
    private ThreadActionListener actionListener;

    public interface ThreadActionListener {
        void onVoteThread(int threadId, String voteType);
        void onAddComment(String content, Integer parentCommentId);
        void onVoteComment(int commentId, String voteType);
        void onReplyToComment(Comment comment);
        void onRefresh();
    }

    public ThreadViewPanel(ForumThread thread, User currentUser,
                           List<Comment> comments, List<ActiveUser> activeUsers,
                           ThreadActionListener actionListener) {
        this.thread = thread;
        this.currentUser = currentUser;
        this.actionListener = actionListener;

        setLayout(new BorderLayout(10, 10));
        setBackground(DARK_BG);
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents(comments, activeUsers);
    }

    private void initComponents(List<Comment> comments, List<ActiveUser> activeUsers) {
        // Thread header (sus)
        add(createThreadHeaderPanel(), BorderLayout.NORTH);

        // Main content (stânga: thread + comentarii, dreapta: utilizatori online)
        JSplitPane mainSplit = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        mainSplit.setDividerLocation(0.86);
        mainSplit.setResizeWeight(0.86);
        mainSplit.setDividerSize(3);
        mainSplit.setBorder(null);

        // Partea stângă: Thread content + comentarii
        JPanel leftPanel = new JPanel(new BorderLayout(10, 10));
        leftPanel.setBackground(DARK_BG);

        // Thread content
        leftPanel.add(createThreadContentPanel(), BorderLayout.NORTH);

        // Comentarii
        commentsPanel = new CommentsPanel(
                comment -> {
                    if (actionListener != null) {
                        actionListener.onReplyToComment(comment);
                    }
                },
                commentId -> {
                    if (actionListener != null) {
                        actionListener.onVoteComment(commentId, "upvote");
                    }
                },
                commentId -> {
                    if (actionListener != null) {
                        actionListener.onVoteComment(commentId, "downvote");
                    }
                }
        );

        JScrollPane commentsScroll = new JScrollPane(commentsPanel);
        commentsScroll.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                "💬 Comentarii (" + comments.size() + ")",
                TitledBorder.LEFT,
                TitledBorder.TOP,
                new Font("Segoe UI", Font.BOLD, 14),
                TEXT_COLOR
        ));
        commentsScroll.getViewport().setBackground(DARK_BG);
        commentsScroll.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);

        leftPanel.add(commentsScroll, BorderLayout.CENTER);

        // Panel pentru adăugare comentariu
        leftPanel.add(createAddCommentPanel(), BorderLayout.SOUTH);

        // Partea dreaptă: Utilizatori online (redusă)
        onlineUsersPanel = new OnlineUsersPanel(activeUsers);
        JScrollPane usersScroll = new JScrollPane(onlineUsersPanel);
        usersScroll.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                "👥 Online (" + activeUsers.size() + ")",
                TitledBorder.LEFT,
                TitledBorder.TOP,
                new Font("Segoe UI", Font.BOLD, 14),
                TEXT_COLOR
        ));
        usersScroll.setPreferredSize(new Dimension(220, 0));

        mainSplit.setLeftComponent(leftPanel);
        mainSplit.setRightComponent(usersScroll);

        add(mainSplit, BorderLayout.CENTER);

        // Setați comentariile inițiale
        commentsPanel.setComments(comments);
    }

    private JPanel createThreadHeaderPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(CARD_BG);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                new EmptyBorder(15, 20, 15, 20)
        ));

        // Left side: Title + status
        JPanel leftPanel = new JPanel();
        leftPanel.setLayout(new BoxLayout(leftPanel, BoxLayout.Y_AXIS));
        leftPanel.setOpaque(false);

        JLabel titleLabel = new JLabel(thread.getTitle());
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 20));
        titleLabel.setForeground(TEXT_COLOR);

        JPanel statusPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 0));
        statusPanel.setOpaque(false);

        if (thread.isPinned()) {
            JLabel pinnedLabel = new JLabel("📌 Fixat");
            pinnedLabel.setForeground(new Color(241, 196, 15));
            pinnedLabel.setFont(new Font("Segoe UI", Font.PLAIN, 12));
            statusPanel.add(pinnedLabel);
        }

        if (thread.isLocked()) {
            JLabel lockedLabel = new JLabel("🔒 Închis");
            lockedLabel.setForeground(DANGER_COLOR);
            lockedLabel.setFont(new Font("Segoe UI", Font.PLAIN, 12));
            statusPanel.add(lockedLabel);
        }

        leftPanel.add(titleLabel);
        leftPanel.add(Box.createVerticalStrut(5));
        leftPanel.add(statusPanel);

        // Right side: Author info
        JPanel rightPanel = new JPanel(new BorderLayout(10, 0));
        rightPanel.setOpaque(false);

        JPanel authorInfo = new JPanel();
        authorInfo.setLayout(new BoxLayout(authorInfo, BoxLayout.Y_AXIS));
        authorInfo.setOpaque(false);

        JLabel authorLabel = new JLabel("👤 " + thread.getUsername());
        authorLabel.setFont(new Font("Segoe UI", Font.BOLD, 12));
        authorLabel.setForeground(TEXT_COLOR);

        JLabel dateLabel = new JLabel("📅 " + thread.getFormattedDate());
        dateLabel.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        dateLabel.setForeground(Color.GRAY);

        authorInfo.add(authorLabel);
        authorInfo.add(dateLabel);

        rightPanel.add(authorInfo, BorderLayout.CENTER);

        // Action buttons panel
        JPanel actionPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 5, 0));
        actionPanel.setOpaque(false);

        // Edit button (only for thread owner or admin)
        if (currentUser != null && (thread.getUserId() == currentUser.getUserId() || currentUser.getRole().equals("admin"))) {
            JButton editBtn = createSmallButton("✏️", "Editează thread");
            editBtn.addActionListener(e -> {
                // This would trigger the edit dialog in parent
                JOptionPane.showMessageDialog(this,
                        "Funcționalitatea de editare thread va fi gestionată în fereastra principală.",
                        "Informație", JOptionPane.INFORMATION_MESSAGE);
            });
            actionPanel.add(editBtn);
        }

        // Refresh button
        JButton refreshBtn = createSmallButton("🔄", "Reîmprospătează");
        refreshBtn.addActionListener(e -> {
            if (actionListener != null) {
                actionListener.onRefresh();
            }
        });

        actionPanel.add(refreshBtn);

        rightPanel.add(actionPanel, BorderLayout.EAST);

        panel.add(leftPanel, BorderLayout.WEST);
        panel.add(rightPanel, BorderLayout.EAST);

        return panel;
    }

    private JButton createSmallButton(String icon, String tooltip) {
        JButton button = new JButton(icon);
        button.setFont(new Font("Segoe UI Emoji", Font.PLAIN, 14));
        button.setBackground(CARD_BG);
        button.setForeground(TEXT_COLOR);
        button.setBorder(BorderFactory.createEmptyBorder(5, 8, 5, 8));
        button.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        button.setToolTipText(tooltip);

        button.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseEntered(java.awt.event.MouseEvent e) {
                button.setBackground(new Color(70, 75, 85));
            }

            @Override
            public void mouseExited(java.awt.event.MouseEvent e) {
                button.setBackground(CARD_BG);
            }
        });

        return button;
    }

    private JPanel createThreadContentPanel() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setBackground(CARD_BG);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                new EmptyBorder(20, 20, 20, 20)
        ));

        // Content
        JTextArea contentArea = new JTextArea(thread.getContent());
        contentArea.setEditable(false);
        contentArea.setLineWrap(true);
        contentArea.setWrapStyleWord(true);
        contentArea.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        contentArea.setForeground(TEXT_COLOR);
        contentArea.setBackground(CARD_BG);
        contentArea.setBorder(new EmptyBorder(10, 5, 10, 5));

        JScrollPane contentScroll = new JScrollPane(contentArea);
        contentScroll.setBorder(null);
        contentScroll.getViewport().setBackground(CARD_BG);
        contentScroll.setPreferredSize(new Dimension(0, 150));

        // Stats and actions panel
        JPanel bottomPanel = new JPanel(new BorderLayout());
        bottomPanel.setOpaque(false);

        // Statistics
        JPanel statsPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 15, 0));
        statsPanel.setOpaque(false);

        statsPanel.add(createStatLabel("👁️", "Vizualizări", String.valueOf(thread.getViewCount())));
        statsPanel.add(createStatLabel("💬", "Comentarii", String.valueOf(thread.getCommentCount())));
        statsPanel.add(createStatLabel("⭐", "Voturi", String.valueOf(thread.getVoteScore())));

        // Vote buttons
        JPanel votePanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 0));
        votePanel.setOpaque(false);

        JButton upvoteBtn = createActionButton("⬆️ Upvote (" + thread.getVoteScore() + ")", SUCCESS_COLOR);
        upvoteBtn.addActionListener(e -> {
            if (actionListener != null) {
                actionListener.onVoteThread(thread.getThreadId(), "upvote");
            }
        });

        JButton downvoteBtn = createActionButton("⬇️ Downvote", DANGER_COLOR);
        downvoteBtn.addActionListener(e -> {
            if (actionListener != null) {
                actionListener.onVoteThread(thread.getThreadId(), "downvote");
            }
        });

        votePanel.add(upvoteBtn);
        votePanel.add(downvoteBtn);

        bottomPanel.add(statsPanel, BorderLayout.WEST);
        bottomPanel.add(votePanel, BorderLayout.EAST);

        panel.add(contentScroll, BorderLayout.CENTER);
        panel.add(bottomPanel, BorderLayout.SOUTH);

        return panel;
    }

    private JLabel createStatLabel(String icon, String label, String value) {
        JLabel statLabel = new JLabel(
                String.format("<html><div style='text-align: center;'>" +
                                "<div style='font-size: 20px;'>%s</div>" +
                                "<div style='font-size: 11px; color: #95a5a6;'>%s</div>" +
                                "<div style='font-size: 14px; font-weight: bold;'>%s</div>" +
                                "</div></html>",
                        icon, label, value)
        );
        return statLabel;
    }

    private JButton createActionButton(String text, Color color) {
        JButton button = new JButton(text);
        button.setBackground(color);
        button.setForeground(Color.WHITE);
        button.setFont(new Font("Segoe UI", Font.BOLD, 12));
        button.setFocusPainted(false);
        button.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(color.darker(), 1),
                new EmptyBorder(8, 15, 8, 15)
        ));
        button.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));

        button.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseEntered(java.awt.event.MouseEvent e) {
                button.setBackground(color.brighter());
            }

            @Override
            public void mouseExited(java.awt.event.MouseEvent e) {
                button.setBackground(color);
            }
        });

        return button;
    }

    private JPanel createAddCommentPanel() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setBackground(CARD_BG);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                new EmptyBorder(15, 15, 15, 15)
        ));

        JLabel label = new JLabel("✍️ Adaugă comentariu:");
        label.setFont(new Font("Segoe UI", Font.BOLD, 14));
        label.setForeground(TEXT_COLOR);

        JTextArea commentArea = new JTextArea(2, 30);
        commentArea.setLineWrap(true);
        commentArea.setWrapStyleWord(true);
        commentArea.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        commentArea.setBackground(new Color(40, 44, 52));
        commentArea.setForeground(TEXT_COLOR);
        commentArea.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                new EmptyBorder(10, 10, 10, 10)
        ));

        // Add keyboard shortcut (Ctrl+Enter to post)
        commentArea.getInputMap().put(KeyStroke.getKeyStroke("control ENTER"), "postComment");
        commentArea.getActionMap().put("postComment", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                postComment(commentArea);
            }
        });

        JScrollPane textScroll = new JScrollPane(commentArea);
        textScroll.setBorder(null);
        textScroll.setPreferredSize(new Dimension(0, 80));

        JButton postButton = createActionButton("📤 Postează (Ctrl+Enter)", PRIMARY_COLOR);
        postButton.addActionListener(e -> postComment(commentArea));

        panel.add(label, BorderLayout.NORTH);
        panel.add(textScroll, BorderLayout.CENTER);
        panel.add(postButton, BorderLayout.SOUTH);

        return panel;
    }

    private void postComment(JTextArea commentArea) {
        String content = commentArea.getText().trim();
        if (!content.isEmpty() && actionListener != null) {
            actionListener.onAddComment(content, null);
            commentArea.setText("");
        }
    }

    public void updateComments(List<Comment> comments) {
        if (commentsPanel != null) {
            commentsPanel.setComments(comments);
        }
    }

    public void updateOnlineUsers(List<ActiveUser> users) {
        if (onlineUsersPanel != null) {
            onlineUsersPanel.updateUsers(users);
        }
    }

    public void updateThread(ForumThread updatedThread) {
        this.thread = updatedThread;
        // Ar putea fi necesar să reîncarci UI-ul aici
    }
}