package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;

public class SettingsDialog extends JDialog {
    private final Color DARK_BG = new Color(18, 22, 30);
    private final Color CARD_BG = new Color(30, 35, 45);
    private final Color TEXT_COLOR = new Color(248, 248, 248);
    private final Color BORDER_COLOR = new Color(50, 55, 65);
    private final Color ACCENT_COLOR = new Color(88, 101, 242);
    private final Color SUCCESS_COLOR = new Color(46, 204, 113);

    public SettingsDialog(JFrame parent) {
        super(parent, "Setări", true);
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

        JLabel headerLabel = new JLabel("⚙️ Setări");
        headerLabel.setFont(new Font("Segoe UI", Font.BOLD, 18));
        headerLabel.setForeground(TEXT_COLOR);
        headerPanel.add(headerLabel, BorderLayout.WEST);

        // Settings panel
        JPanel settingsPanel = new JPanel(new GridBagLayout());
        settingsPanel.setBackground(CARD_BG);
        settingsPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(20, 20, 20, 20)
        ));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(8, 8, 8, 8);
        gbc.weightx = 1.0;

        // Auto-refresh
        gbc.gridx = 0; gbc.gridy = 0; gbc.gridwidth = 2;
        JCheckBox autoRefreshCheck = new JCheckBox("🔄 Auto-refresh comentarii");
        styleCheckbox(autoRefreshCheck);
        autoRefreshCheck.setSelected(true);
        settingsPanel.add(autoRefreshCheck, gbc);

        // Notifications
        gbc.gridy++;
        JCheckBox notifyCheck = new JCheckBox("🔔 Notificări la comentarii noi");
        styleCheckbox(notifyCheck);
        notifyCheck.setSelected(true);
        settingsPanel.add(notifyCheck, gbc);

        // Theme
        gbc.gridy++;
        gbc.gridwidth = 1;
        JLabel themeLabel = new JLabel("🎨 Temă:");
        themeLabel.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        themeLabel.setForeground(TEXT_COLOR);
        settingsPanel.add(themeLabel, gbc);

        gbc.gridx = 1;
        String[] themes = {"Întunecată (implicită)", "Deschisă", "Auto (sistem)"};
        JComboBox<String> themeCombo = new JComboBox<>(themes);
        themeCombo.setBackground(new Color(40, 44, 52));
        themeCombo.setForeground(TEXT_COLOR);
        themeCombo.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(5, 10, 5, 10)
        ));
        settingsPanel.add(themeCombo, gbc);

        // Font size
        gbc.gridx = 0; gbc.gridy++;
        JLabel fontSizeLabel = new JLabel("🔠 Mărime font:");
        fontSizeLabel.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        fontSizeLabel.setForeground(TEXT_COLOR);
        settingsPanel.add(fontSizeLabel, gbc);

        gbc.gridx = 1;
        JSlider fontSizeSlider = new JSlider(12, 18, 14);
        fontSizeSlider.setBackground(CARD_BG);
        fontSizeSlider.setPaintTicks(true);
        fontSizeSlider.setPaintLabels(true);
        fontSizeSlider.setMajorTickSpacing(2);
        settingsPanel.add(fontSizeSlider, gbc);

        // Save settings button
        gbc.gridx = 0; gbc.gridy++; gbc.gridwidth = 2;
        gbc.anchor = GridBagConstraints.CENTER;
        gbc.insets = new Insets(20, 10, 10, 10);
        JButton saveButton = createButton("💾 Salvează setări", SUCCESS_COLOR);
        saveButton.addActionListener(e -> {
            JOptionPane.showMessageDialog(this,
                    "Setările au fost salvate!",
                    "Succes",
                    JOptionPane.INFORMATION_MESSAGE);
            dispose();
        });

        settingsPanel.add(saveButton, gbc);

        // Cancel button
        gbc.gridy++;
        JButton cancelButton = createButton("❌ Anulează", new Color(231, 76, 60));
        cancelButton.addActionListener(e -> dispose());
        settingsPanel.add(cancelButton, gbc);

        mainPanel.add(headerPanel, BorderLayout.NORTH);
        mainPanel.add(settingsPanel, BorderLayout.CENTER);

        getContentPane().add(mainPanel, BorderLayout.CENTER);

        // ESC to close
        getRootPane().registerKeyboardAction(
                e -> dispose(),
                KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0),
                JComponent.WHEN_IN_FOCUSED_WINDOW
        );
    }

    private void styleCheckbox(JCheckBox checkbox) {
        checkbox.setBackground(CARD_BG);
        checkbox.setForeground(TEXT_COLOR);
        checkbox.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        checkbox.setFocusPainted(false);
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