package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;
import shared.*;

public class ProfileDialog extends JDialog {
    private final Color DARK_BG = new Color(34, 40, 49);
    private final Color CARD_BG = new Color(57, 62, 70);
    private final Color TEXT_COLOR = new Color(238, 238, 238);
    private final Color BORDER_COLOR = new Color(76, 82, 92);
    private final Color ACCENT_COLOR = new Color(88, 101, 242);

    private User user;

    public ProfileDialog(JFrame parent, User user) {
        super(parent, "Profil Utilizator", true);
        this.user = user;
        initUI();
        setSize(500, 400);
        setLocationRelativeTo(parent);
        setResizable(false);
    }

    private void initUI() {
        getContentPane().setLayout(new BorderLayout(10, 10));
        getContentPane().setBackground(DARK_BG);

        JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
        mainPanel.setBackground(DARK_BG);
        mainPanel.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        // Header
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setBackground(CARD_BG);
        headerPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(15, 20, 15, 20)
        ));

        JLabel headerLabel = new JLabel("👤 Profilul meu");
        headerLabel.setFont(new Font("Segoe UI", Font.BOLD, 18));
        headerLabel.setForeground(TEXT_COLOR);

        headerPanel.add(headerLabel, BorderLayout.WEST);

        // Profile info panel
        JPanel infoPanel = new JPanel(new GridBagLayout());
        infoPanel.setBackground(CARD_BG);
        infoPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(20, 20, 20, 20)
        ));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(10, 10, 10, 10);
        gbc.gridwidth = 2;

        // Avatar
        gbc.gridx = 0; gbc.gridy = 0;
        JPanel avatarPanel = new JPanel();
        avatarPanel.setBackground(new Color(Integer.parseInt(user.getAvatarColor().substring(1), 16)));
        avatarPanel.setPreferredSize(new Dimension(80, 80));
        avatarPanel.setBorder(BorderFactory.createLineBorder(TEXT_COLOR, 2));

        JLabel avatarLabel = new JLabel(user.getUsername().substring(0, 1).toUpperCase());
        avatarLabel.setFont(new Font("Segoe UI", Font.BOLD, 32));
        avatarLabel.setForeground(Color.WHITE);
        avatarPanel.add(avatarLabel);

        infoPanel.add(avatarPanel, gbc);

        // User info
        gbc.gridy++;
        addInfoField(infoPanel, gbc, "👤 Username:", user.getUsername());

        gbc.gridy++;
        addInfoField(infoPanel, gbc, "📧 Email:", user.getEmail());

        gbc.gridy++;
        addInfoField(infoPanel, gbc, "👨‍💼 Nume:", user.getFullName());

        gbc.gridy++;
        addInfoField(infoPanel, gbc, "🏷️ Rol:", user.getRole());

        gbc.gridy++;
        gbc.fill = GridBagConstraints.BOTH;
        gbc.weighty = 1.0;
        JLabel bioLabel = new JLabel("📝 Bio:");
        bioLabel.setFont(new Font("Segoe UI", Font.BOLD, 14));
        bioLabel.setForeground(TEXT_COLOR);
        infoPanel.add(bioLabel, gbc);

        gbc.gridy++;
        JTextArea bioArea = new JTextArea(user.getBio() != null ? user.getBio() : "Nu există bio.");
        bioArea.setEditable(false);
        bioArea.setLineWrap(true);
        bioArea.setWrapStyleWord(true);
        bioArea.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        bioArea.setBackground(new Color(40, 44, 52));
        bioArea.setForeground(TEXT_COLOR);
        bioArea.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        JScrollPane bioScroll = new JScrollPane(bioArea);
        bioScroll.setBorder(null);
        infoPanel.add(bioScroll, gbc);

        // Stats panel
        gbc.gridy++;
        gbc.weighty = 0;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        JPanel statsPanel = new JPanel(new GridLayout(1, 3, 10, 0));
        statsPanel.setOpaque(false);

        statsPanel.add(createStatCard("📊 Thread-uri", "12"));
        statsPanel.add(createStatCard("💬 Comentarii", "45"));
        statsPanel.add(createStatCard("⭐ Reputație", "156"));

        infoPanel.add(statsPanel, gbc);

        // Close button
        gbc.gridy++;
        gbc.fill = GridBagConstraints.NONE;
        gbc.anchor = GridBagConstraints.CENTER;
        JButton closeButton = createButton("Închide", ACCENT_COLOR);
        closeButton.addActionListener(e -> dispose());

        infoPanel.add(closeButton, gbc);

        mainPanel.add(headerPanel, BorderLayout.NORTH);
        mainPanel.add(infoPanel, BorderLayout.CENTER);

        getContentPane().add(mainPanel, BorderLayout.CENTER);

        // ESC to close
        getRootPane().registerKeyboardAction(
                e -> dispose(),
                KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0),
                JComponent.WHEN_IN_FOCUSED_WINDOW
        );
    }

    private void addInfoField(JPanel panel, GridBagConstraints gbc, String label, String value) {
        gbc.gridx = 0; gbc.gridwidth = 1;
        JLabel infoLabel = new JLabel(label);
        infoLabel.setFont(new Font("Segoe UI", Font.BOLD, 13));
        infoLabel.setForeground(TEXT_COLOR);
        panel.add(infoLabel, gbc);

        gbc.gridx = 1;
        JLabel valueLabel = new JLabel(value != null ? value : "N/A");
        valueLabel.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        valueLabel.setForeground(Color.GRAY);
        panel.add(valueLabel, gbc);

        gbc.gridy++;
        gbc.gridx = 0;
        gbc.gridwidth = 2;
    }

    private JPanel createStatCard(String label, String value) {
        JPanel card = new JPanel(new BorderLayout());
        card.setBackground(new Color(40, 44, 52));
        card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        JLabel valueLabel = new JLabel(value);
        valueLabel.setFont(new Font("Segoe UI", Font.BOLD, 18));
        valueLabel.setForeground(ACCENT_COLOR);
        valueLabel.setHorizontalAlignment(SwingConstants.CENTER);

        JLabel labelLabel = new JLabel(label);
        labelLabel.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        labelLabel.setForeground(Color.GRAY);
        labelLabel.setHorizontalAlignment(SwingConstants.CENTER);

        card.add(valueLabel, BorderLayout.CENTER);
        card.add(labelLabel, BorderLayout.SOUTH);

        return card;
    }

    private JButton createButton(String text, Color color) {
        JButton button = new JButton(text);
        button.setBackground(color);
        button.setForeground(Color.WHITE);
        button.setFont(new Font("Segoe UI", Font.BOLD, 13));
        button.setFocusPainted(false);
        button.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(color.darker(), 1),
                BorderFactory.createEmptyBorder(8, 20, 8, 20)
        ));
        button.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));

        button.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                button.setBackground(color.brighter());
            }

            @Override
            public void mouseExited(MouseEvent e) {
                button.setBackground(color);
            }
        });

        return button;
    }
}