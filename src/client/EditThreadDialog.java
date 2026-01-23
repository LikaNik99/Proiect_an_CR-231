package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;
import java.util.List;
import shared.*;

public class EditThreadDialog extends JDialog {
    private boolean updated = false;
    private ForumThread thread;
    private final Color DARK_BG = new Color(34, 40, 49);
    private final Color CARD_BG = new Color(57, 62, 70);
    private final Color TEXT_COLOR = new Color(238, 238, 238);
    private final Color BORDER_COLOR = new Color(76, 82, 92);
    private final Color ACCENT_COLOR = new Color(88, 101, 242);
    private final Color SUCCESS_COLOR = new Color(46, 204, 113);

    private JTextField titleField;
    private JTextArea contentArea;

    public EditThreadDialog(JFrame parent, ForumThread thread) {
        super(parent, "Editează Thread", true);
        this.thread = thread;
        initUI();
        setSize(600, 500);
        setLocationRelativeTo(parent);
        setResizable(true);
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

        JLabel headerLabel = new JLabel("✏️ Editează Thread");
        headerLabel.setFont(new Font("Segoe UI", Font.BOLD, 18));
        headerLabel.setForeground(TEXT_COLOR);

        JLabel threadIdLabel = new JLabel("ID: " + thread.getThreadId());
        threadIdLabel.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        threadIdLabel.setForeground(Color.GRAY);

        headerPanel.add(headerLabel, BorderLayout.WEST);
        headerPanel.add(threadIdLabel, BorderLayout.EAST);

        // Form panel
        JPanel formPanel = new JPanel(new GridBagLayout());
        formPanel.setBackground(CARD_BG);
        formPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(20, 20, 20, 20)
        ));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(8, 8, 8, 8);
        gbc.weightx = 1.0;

        // Title
        gbc.gridx = 0; gbc.gridy = 0; gbc.gridwidth = 2;
        JLabel titleLabel = new JLabel("Titlu:");
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 14));
        titleLabel.setForeground(TEXT_COLOR);
        formPanel.add(titleLabel, gbc);

        gbc.gridy++;
        titleField = new JTextField(thread.getTitle(), 40);
        styleTextField(titleField);
        formPanel.add(titleField, gbc);

        // Content
        gbc.gridy++;
        JLabel contentLabel = new JLabel("Conținut:");
        contentLabel.setFont(new Font("Segoe UI", Font.BOLD, 14));
        contentLabel.setForeground(TEXT_COLOR);
        formPanel.add(contentLabel, gbc);

        gbc.gridy++;
        gbc.weighty = 1.0;
        gbc.fill = GridBagConstraints.BOTH;
        contentArea = new JTextArea(thread.getContent(), 10, 40);
        contentArea.setLineWrap(true);
        contentArea.setWrapStyleWord(true);
        contentArea.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        contentArea.setBackground(new Color(40, 44, 52));
        contentArea.setForeground(TEXT_COLOR);
        contentArea.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        JScrollPane scrollPane = new JScrollPane(contentArea);
        scrollPane.setBorder(null);
        formPanel.add(scrollPane, gbc);

        // Buttons panel
        gbc.gridy++;
        gbc.weighty = 0;
        gbc.fill = GridBagConstraints.NONE;
        gbc.anchor = GridBagConstraints.EAST;

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 0));
        buttonPanel.setOpaque(false);

        JButton cancelButton = createButton("❌ Anulează", new Color(231, 76, 60));
        cancelButton.addActionListener(e -> dispose());

        JButton saveButton = createButton("💾 Salvează", SUCCESS_COLOR);
        saveButton.addActionListener(e -> saveChanges());

        buttonPanel.add(cancelButton);
        buttonPanel.add(saveButton);
        formPanel.add(buttonPanel, gbc);

        mainPanel.add(headerPanel, BorderLayout.NORTH);
        mainPanel.add(formPanel, BorderLayout.CENTER);

        getContentPane().add(mainPanel, BorderLayout.CENTER);

        // Add keyboard shortcuts
        setupKeyboardShortcuts();
    }

    private void styleTextField(JTextField field) {
        field.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        field.setBackground(new Color(40, 44, 52));
        field.setForeground(TEXT_COLOR);
        field.setCaretColor(TEXT_COLOR);
        field.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));
    }

    private JButton createButton(String text, Color color) {
        JButton button = new JButton(text);
        button.setBackground(color);
        button.setForeground(Color.WHITE);
        button.setFont(new Font("Segoe UI", Font.BOLD, 13));
        button.setFocusPainted(false);
        button.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(color.darker(), 1),
                BorderFactory.createEmptyBorder(8, 15, 8, 15)
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

    private void setupKeyboardShortcuts() {
        // ESC to cancel
        getRootPane().registerKeyboardAction(
                e -> dispose(),
                KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0),
                JComponent.WHEN_IN_FOCUSED_WINDOW
        );

        // Ctrl+S to save
        getRootPane().registerKeyboardAction(
                e -> saveChanges(),
                KeyStroke.getKeyStroke(KeyEvent.VK_S, Toolkit.getDefaultToolkit().getMenuShortcutKeyMaskEx()),
                JComponent.WHEN_IN_FOCUSED_WINDOW
        );
    }

    private void saveChanges() {
        String title = titleField.getText().trim();
        String content = contentArea.getText().trim();

        if (title.isEmpty()) {
            JOptionPane.showMessageDialog(this,
                    "Titlul nu poate fi gol!",
                    "Eroare",
                    JOptionPane.ERROR_MESSAGE);
            titleField.requestFocus();
            return;
        }

        if (content.isEmpty()) {
            JOptionPane.showMessageDialog(this,
                    "Conținutul nu poate fi gol!",
                    "Eroare",
                    JOptionPane.ERROR_MESSAGE);
            contentArea.requestFocus();
            return;
        }

        // Here you would send the update request to server
        // For now, just mark as updated
        updated = true;

        JOptionPane.showMessageDialog(this,
                "Thread-ul a fost actualizat cu succes!",
                "Succes",
                JOptionPane.INFORMATION_MESSAGE);

        dispose();
    }

    public boolean isUpdated() {
        return updated;
    }

    public String getUpdatedTitle() {
        return titleField.getText().trim();
    }

    public String getUpdatedContent() {
        return contentArea.getText().trim();
    }
}