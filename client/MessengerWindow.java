package client;

import javax.swing.*;
import java.awt.*;
import java.util.List;

public class MessengerWindow extends JFrame {
    private JTextArea chatArea;
    private JTextField inputField;
    private String friendName;
    private ClientApp parent;

    public MessengerWindow(String friendName, ClientApp parent) {
        this.friendName = friendName;
        this.parent = parent;
        
        setTitle(" Messenger: " + friendName);
        setSize(450, 550);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());
        getContentPane().setBackground(new Color(0, 40, 40));

        // Header
        JLabel header = new JLabel(" Conversație cu " + friendName, SwingConstants.CENTER);
        header.setFont(new Font("SansSerif", Font.BOLD, 18));
        header.setForeground(Color.CYAN);
        header.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        add(header, BorderLayout.NORTH);

        // Chat Area
        chatArea = new JTextArea();
        chatArea.setEditable(false);
        chatArea.setBackground(new Color(0, 30, 30));
        chatArea.setForeground(Color.WHITE);
        chatArea.setFont(new Font("Monospaced", Font.PLAIN, 14));
        chatArea.setMargin(new Insets(10,10,10,10));
        JScrollPane scroll = new JScrollPane(chatArea);
        scroll.setBorder(BorderFactory.createLineBorder(Color.CYAN));
        add(scroll, BorderLayout.CENTER);

        // Input Panel
        JPanel inputPanel = new JPanel(new BorderLayout(5, 5));
        inputPanel.setOpaque(false);
        inputPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        inputField = new JTextField();
        inputField.setBackground(new Color(0, 60, 60));
        inputField.setForeground(Color.WHITE);
        inputField.setCaretColor(Color.WHITE);
        inputField.setBorder(BorderFactory.createLineBorder(Color.CYAN));
        
        JButton sendBtn = new JButton("TRIMITE");
        sendBtn.setBackground(new Color(0, 120, 120));
        sendBtn.setForeground(Color.WHITE);
        
        sendBtn.addActionListener(e -> sendMessage());
        inputField.addActionListener(e -> sendMessage());

        inputPanel.add(inputField, BorderLayout.CENTER);
        inputPanel.add(sendBtn, BorderLayout.EAST);
        add(inputPanel, BorderLayout.SOUTH);
    }

    private void sendMessage() {
        String msg = inputField.getText().trim();
        if (!msg.isEmpty()) {
            parent.sendNetworkMessage("PRIVATE_MSG", friendName + "|" + msg);
            inputField.setText("");
        }
    }

    public void updateChat(List<String> messages) {
        SwingUtilities.invokeLater(() -> {
            chatArea.setText("");
            for (String m : messages) {
                chatArea.append(m + "\n");
            }
        });
    }
}