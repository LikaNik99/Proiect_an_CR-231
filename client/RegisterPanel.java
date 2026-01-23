package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;

public class RegisterPanel extends JPanel {
    private ClientApp parentFrame;
    private JTextField userField, emailField;
    private JPasswordField passField;

    public RegisterPanel(ClientApp parentFrame) {
        this.parentFrame = parentFrame;
        setLayout(new GridBagLayout());
        setBackground(new Color(0, 40, 40));

        JPanel card = new JPanel();
        card.setLayout(new BoxLayout(card, BoxLayout.Y_AXIS));
        card.setBackground(new Color(0, 60, 60));
        card.setBorder(BorderFactory.createCompoundBorder(
            new LineBorder(new Color(0, 255, 255), 2),
            new EmptyBorder(30, 50, 30, 50)));

        JLabel title = new JLabel("INREGISTRARE");
        title.setFont(new Font("Serif", Font.BOLD, 28));
        title.setForeground(Color.CYAN);
        title.setAlignmentX(Component.CENTER_ALIGNMENT);

        userField = new JTextField(15);
        emailField = new JTextField(15);
        passField = new JPasswordField(15);
        
        styleInput(userField, "UTILIZATOR");
        styleInput(emailField, "EMAIL");
        styleInput(passField, "PAROLA");

        JButton regBtn = new JButton("CREEAZA CONT");
        JButton backBtn = new JButton("INAPOI");
        styleBtn(regBtn); styleBtn(backBtn);

        regBtn.addActionListener(e -> {
            String data = userField.getText() + "|" + emailField.getText() + "|" + new String(passField.getPassword());
            parentFrame.sendNetworkMessage("REGISTER", data);
        });
        backBtn.addActionListener(e -> parentFrame.showLogin());

        card.add(title); card.add(Box.createVerticalStrut(20));
        card.add(userField); card.add(Box.createVerticalStrut(10));
        card.add(emailField); card.add(Box.createVerticalStrut(10));
        card.add(passField); card.add(Box.createVerticalStrut(25));
        card.add(regBtn); card.add(Box.createVerticalStrut(10));
        card.add(backBtn);

        add(card);
    }

    private void styleInput(JTextField f, String title) {
        f.setMaximumSize(new Dimension(300, 45));
        f.setBackground(new Color(0, 30, 30));
        f.setForeground(Color.WHITE);
        f.setBorder(new TitledBorder(new LineBorder(Color.CYAN), title, 0, 0, null, Color.CYAN));
    }

    private void styleBtn(JButton b) {
        b.setAlignmentX(Component.CENTER_ALIGNMENT);
        b.setMaximumSize(new Dimension(200, 40));
        b.setBackground(new Color(0, 150, 150));
        b.setForeground(Color.WHITE);
        b.setBorder(new LineBorder(Color.CYAN, 1));
    }
}