package client;

import shared.ActiveUser;
import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.util.List;

public class OnlineUsersPanel extends JPanel {
    private final Color DARK_BG = new Color(34, 40, 49);
    private final Color CARD_BG = new Color(57, 62, 70);
    private final Color TEXT_COLOR = new Color(238, 238, 238);
    private final Color BORDER_COLOR = new Color(76, 82, 92);
    private final Color ONLINE_COLOR = new Color(46, 204, 113);

    private final JPanel usersPanel;
    private List<ActiveUser> users;

    public OnlineUsersPanel(List<ActiveUser> users) {
        this.users = users;

        setLayout(new BorderLayout());
        setBackground(DARK_BG);

        usersPanel = new JPanel();
        usersPanel.setLayout(new BoxLayout(usersPanel, BoxLayout.Y_AXIS));
        usersPanel.setBackground(DARK_BG);
        usersPanel.setBorder(new EmptyBorder(5, 5, 5, 5)); // Reduced padding

        JScrollPane scrollPane = new JScrollPane(usersPanel);
        scrollPane.setBorder(null);
        scrollPane.getViewport().setBackground(DARK_BG);
        scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);

        add(scrollPane, BorderLayout.CENTER);

        renderUsers();
    }

    private void renderUsers() {
        usersPanel.removeAll();

        if (users.isEmpty()) {
            JLabel noUsersLabel = new JLabel(
                    "<html><div style='text-align: center; padding: 10px; color: #95a5a6; font-size: 12px;'>" +
                            "Niciun utilizator online" +
                            "</div></html>"
            );
            noUsersLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
            usersPanel.add(noUsersLabel);
        } else {
            for (ActiveUser user : users) {
                usersPanel.add(createUserCard(user));
                usersPanel.add(Box.createVerticalStrut(4)); // Reduced spacing
            }
        }

        usersPanel.revalidate();
        usersPanel.repaint();
    }

    private JPanel createUserCard(ActiveUser user) {
        JPanel card = new JPanel(new BorderLayout(5, 0)); // Reduced spacing
        card.setBackground(CARD_BG);
        card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                new EmptyBorder(6, 8, 6, 8) // Reduced padding
        ));
        card.setMaximumSize(new Dimension(220, 60)); // Smaller card

        // Left: Status dot
        JLabel statusDot = new JLabel("●");
        statusDot.setFont(new Font("Segoe UI", Font.BOLD, 10));
        statusDot.setForeground(ONLINE_COLOR);
        statusDot.setBorder(new EmptyBorder(0, 0, 0, 5));

        // Center: User info
        JPanel infoPanel = new JPanel();
        infoPanel.setLayout(new BoxLayout(infoPanel, BoxLayout.Y_AXIS));
        infoPanel.setOpaque(false);

        JLabel usernameLabel = new JLabel(user.getUsername());
        usernameLabel.setFont(new Font("Segoe UI", Font.BOLD, 12));
        usernameLabel.setForeground(TEXT_COLOR);

        // Compact status
        String statusText;
        if (user.getThreadId() != null) {
            statusText = "În thread";
        } else {
            statusText = "În meniu";
        }

        JLabel statusLabel = new JLabel(statusText);
        statusLabel.setFont(new Font("Segoe UI", Font.PLAIN, 10));
        statusLabel.setForeground(Color.GRAY);

        infoPanel.add(usernameLabel);
        infoPanel.add(Box.createVerticalStrut(1));
        infoPanel.add(statusLabel);

        // Right: Time (smaller)
        JLabel timeLabel = new JLabel(user.getFormattedLastActivity());
        timeLabel.setFont(new Font("Segoe UI", Font.PLAIN, 9));
        timeLabel.setForeground(Color.DARK_GRAY);
        timeLabel.setBorder(new EmptyBorder(0, 5, 0, 0));

        card.add(statusDot, BorderLayout.WEST);
        card.add(infoPanel, BorderLayout.CENTER);
        card.add(timeLabel, BorderLayout.EAST);

        return card;
    }

    public void updateUsers(List<ActiveUser> newUsers) {
        this.users = newUsers;
        renderUsers();
    }
}