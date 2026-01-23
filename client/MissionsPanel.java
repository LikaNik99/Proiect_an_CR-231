package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

public class MissionsPanel extends JPanel {
    private JPanel listContainer;
    private ClientApp parent;
    private JLabel timerLabel;

    public MissionsPanel(ClientApp parent) {
        this.parent = parent;
        setLayout(new BorderLayout());
        setBackground(new Color(0, 40, 40)); 
        setBorder(new EmptyBorder(20, 30, 20, 30));

        JPanel header = new JPanel(new GridLayout(2, 1));
        header.setOpaque(false);
        JLabel title = new JLabel("DAILY CHALLENGES", SwingConstants.CENTER);
        title.setFont(new Font("Serif", Font.BOLD, 36));
        title.setForeground(Color.CYAN);
        
        timerLabel = new JLabel("Reset în: 00:00:00", SwingConstants.CENTER);
        timerLabel.setFont(new Font("Monospaced", Font.BOLD, 18));
        timerLabel.setForeground(Color.ORANGE);
        startResetTimer();

        header.add(title);
        header.add(timerLabel);
        add(header, BorderLayout.NORTH);

        listContainer = new JPanel();
        listContainer.setLayout(new BoxLayout(listContainer, BoxLayout.Y_AXIS));
        listContainer.setOpaque(false);
        
        // FIX: Reparare fundal alb
        JScrollPane scroll = new JScrollPane(listContainer);
        scroll.setOpaque(false);
        scroll.getViewport().setOpaque(false);
        scroll.setBorder(new LineBorder(Color.CYAN, 1));
        add(scroll, BorderLayout.CENTER);

        JButton backBtn = new JButton("ÎNAPOI ÎN LOBBY");
        backBtn.setBackground(new Color(0, 80, 80));
        backBtn.setForeground(Color.WHITE);
        backBtn.addActionListener(e -> parent.showLobby());
        add(backBtn, BorderLayout.SOUTH);
    }

    private void startResetTimer() {
        new Timer(1000, e -> {
            Duration d = Duration.between(LocalDateTime.now(), LocalDateTime.now().toLocalDate().plusDays(1).atStartOfDay());
            timerLabel.setText(String.format("Reset în: %02d:%02d:%02d", d.toHours(), d.toMinutesPart(), d.toSecondsPart()));
        }).start();
    }

    public void updateMissions(List<String> missions) {
        listContainer.removeAll();
        int[] rewards = {1500, 2500, 5000};
        for (int i = 0; i < missions.size(); i++) {
            String[] p = missions.get(i).split("\\|");
            listContainer.add(createMissionCard(i, p[0], p[1], p[2], p[3], rewards[i]));
            listContainer.add(Box.createRigidArea(new Dimension(0, 10)));
        }
        listContainer.revalidate();
        listContainer.repaint();
    }

    private JPanel createMissionCard(int index, String name, String prog, String target, String status, int reward) {
        JPanel card = new JPanel(new BorderLayout(15, 0));
        card.setMaximumSize(new Dimension(900, 100));
        card.setPreferredSize(new Dimension(900, 100));
        card.setBackground(new Color(0, 60, 60));
        card.setBorder(new LineBorder(status.equals("CLAIMED") ? Color.GREEN : Color.CYAN, 2));

        JPanel infoLeft = new JPanel(new GridLayout(2, 1));
        infoLeft.setOpaque(false);
        infoLeft.setPreferredSize(new Dimension(250, 100)); 
        JLabel nameLbl = new JLabel("  " + name.toUpperCase());
        nameLbl.setForeground(Color.WHITE);
        nameLbl.setFont(new Font("SansSerif", Font.BOLD, 16));
        JLabel rewardLbl = new JLabel("  Premiu: $" + reward);
        rewardLbl.setForeground(Color.ORANGE);
        infoLeft.add(nameLbl);
        infoLeft.add(rewardLbl);
        card.add(infoLeft, BorderLayout.WEST);

        JProgressBar bar = new JProgressBar(0, Integer.parseInt(target));
        bar.setValue(Integer.parseInt(prog));
        bar.setStringPainted(true);
        bar.setString(prog + " / " + target);
        bar.setForeground(new Color(0, 255, 200));
        bar.setBackground(Color.BLACK);
        card.add(bar, BorderLayout.CENTER);

        JPanel actionPanel = new JPanel(new BorderLayout());
        actionPanel.setOpaque(false);
        actionPanel.setPreferredSize(new Dimension(150, 100));

        // BUTONUL DE CLAIM (image_cd847c.png)
        if (status.equals("COMPLETED")) {
            JButton claimBtn = new JButton("CLAIM");
            claimBtn.setBackground(Color.GREEN);
            claimBtn.addActionListener(e -> parent.sendNetworkMessage("CLAIM_MISSION", String.valueOf(index)));
            actionPanel.add(claimBtn, BorderLayout.CENTER);
        } else {
            JLabel statusLbl = new JLabel(status.equals("CLAIMED") ? "REVENDICAT  " : "ÎN CURS  ");
            statusLbl.setForeground(status.equals("CLAIMED") ? Color.GREEN : Color.YELLOW);
            statusLbl.setHorizontalAlignment(SwingConstants.CENTER);
            actionPanel.add(statusLbl, BorderLayout.CENTER);
        }
        card.add(actionPanel, BorderLayout.EAST);

        return card;
    }
}