package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import shared.*;

public class StatisticsDialog extends JDialog {
    public StatisticsDialog(JFrame parent, User user) {
        super(parent, "Statistici", true);
        initUI(user);
        setSize(400, 300);
        setLocationRelativeTo(parent);
    }

    private void initUI(User user) {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        String stats = "<html><h2>📊 Statistici</h2>" +
                "<p><b>Utilizator:</b> " + user.getUsername() + "</p>" +
                "<p><b>Thread-uri create:</b> 12</p>" +
                "<p><b>Comentarii postate:</b> 45</p>" +
                "<p><b>Voturi primite:</b> 156</p>" +
                "</html>";

        JLabel label = new JLabel(stats);
        label.setHorizontalAlignment(SwingConstants.CENTER);

        panel.add(label, BorderLayout.CENTER);
        add(panel);
    }
}