package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;

public class LoginPanel extends JPanel {
    private ClientApp parentFrame;
    private JTextField userField;
    private JPasswordField passField;

    public LoginPanel(ClientApp parentFrame) {
        this.parentFrame = parentFrame;
        setLayout(new GridBagLayout());
        setBackground(new Color(0, 40, 40)); // Turcoaz inchis

        JPanel card = new JPanel();
        card.setLayout(new BoxLayout(card, BoxLayout.Y_AXIS));
        card.setBackground(new Color(0, 60, 60)); // Turcoaz mediu
        card.setBorder(BorderFactory.createCompoundBorder(
            new LineBorder(new Color(0, 255, 255), 2),
            new EmptyBorder(30, 50, 30, 50)));

        JLabel title = new JLabel("ROYAL BLACKJACK");
        title.setFont(new Font("Serif", Font.BOLD, 32));
        title.setForeground(Color.CYAN);
        title.setAlignmentX(Component.CENTER_ALIGNMENT);

        userField = new JTextField(15);
        passField = new JPasswordField(15);
        styleInput(userField, "UTILIZATOR");
        styleInput(passField, "PAROLA");

        JButton loginBtn = createBtn("LOGARE");
        JButton regBtn = createBtn("CONT NOU");

        loginBtn.addActionListener(e -> parentFrame.sendNetworkMessage("LOGIN", userField.getText().trim() + "|" + new String(passField.getPassword()).trim()));
        regBtn.addActionListener(e -> parentFrame.showRegister());

        card.add(title); card.add(Box.createVerticalStrut(25));
        card.add(userField); card.add(Box.createVerticalStrut(15));
        card.add(passField); card.add(Box.createVerticalStrut(25));
        card.add(loginBtn); card.add(Box.createVerticalStrut(10));
        card.add(regBtn);

        add(card);
    }

    private void styleInput(JTextField f, String title) {
        f.setMaximumSize(new Dimension(300, 50));
        f.setBackground(new Color(0, 30, 30));
        f.setForeground(Color.WHITE);
        f.setCaretColor(Color.WHITE);
        f.setBorder(new TitledBorder(new LineBorder(Color.CYAN), title, 0, 0, null, Color.CYAN));
    }

    private JButton createBtn(String t) {
        JButton b = new JButton(t);
        b.setAlignmentX(Component.CENTER_ALIGNMENT);
        b.setMaximumSize(new Dimension(200, 45));
        b.setBackground(new Color(0, 150, 150));
        b.setForeground(Color.WHITE);
        b.setFont(new Font("SansSerif", Font.BOLD, 14));
        b.setBorder(new LineBorder(Color.CYAN, 1));
        return b;
    }
}