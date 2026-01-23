package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.util.List;

public class FriendsPanel extends JPanel {
    private ClientApp parent;
    private JPanel listContainer;

    public FriendsPanel(ClientApp parent) {
        this.parent = parent;
        setLayout(new BorderLayout());
        setBackground(new Color(0, 40, 40));
        setBorder(new EmptyBorder(20, 20, 20, 20));

        JLabel title = new JLabel("LISTA DE PRIETENI", SwingConstants.CENTER);
        title.setFont(new Font("Serif", Font.BOLD, 32));
        title.setForeground(Color.CYAN);
        add(title, BorderLayout.NORTH);

        listContainer = new JPanel();
        listContainer.setLayout(new BoxLayout(listContainer, BoxLayout.Y_AXIS));
        listContainer.setOpaque(false);
        
        JScrollPane scroll = new JScrollPane(listContainer);
        scroll.setOpaque(false);
        scroll.getViewport().setOpaque(false);
        scroll.setBorder(null);
        add(scroll, BorderLayout.CENTER);

        // FIX: Butoanele din dreapta aranjate mai frumos
        JPanel sideButtons = new JPanel();
        sideButtons.setLayout(new BoxLayout(sideButtons, BoxLayout.Y_AXIS));
        sideButtons.setOpaque(false);
        sideButtons.setBorder(new EmptyBorder(10, 10, 10, 10));
        sideButtons.add(Box.createVerticalGlue());
        
        JButton addBtn = createStyledBtn("ADĂUGĂ", new Color(0, 150, 0), new Color(0, 200, 0));
        JButton reqBtn = createStyledBtn("CERERI", new Color(200, 150, 0), new Color(255, 200, 0));
        JButton backBtn = createStyledBtn("ÎNAPOI", new Color(100, 100, 100), new Color(150, 150, 150));
        
        addBtn.addActionListener(e -> {
            String t = JOptionPane.showInputDialog("Username prieten:");
            if (t != null) parent.sendNetworkMessage("SEND_FRIEND_REQUEST", t);
        });
        reqBtn.addActionListener(e -> parent.sendNetworkMessage("GET_FRIEND_REQUESTS", ""));
        backBtn.addActionListener(e -> parent.showLobby());

        sideButtons.add(addBtn);
        sideButtons.add(Box.createRigidArea(new Dimension(0, 15)));
        sideButtons.add(reqBtn);
        sideButtons.add(Box.createRigidArea(new Dimension(0, 15)));
        sideButtons.add(backBtn);
        sideButtons.add(Box.createVerticalGlue());
        
        add(sideButtons, BorderLayout.EAST);
    }

    private JButton createBtn(String t, Color c) {
        JButton b = new JButton(t);
        b.setBackground(new Color(0, 60, 60));
        b.setForeground(c);
        b.setBorder(new LineBorder(c, 2));
        return b;
    }

    private JButton createStyledBtn(String text, Color bgColor, Color hoverColor) {
        JButton btn = new JButton(text);
        btn.setPreferredSize(new Dimension(150, 45));
        btn.setMaximumSize(new Dimension(150, 45));
        btn.setMinimumSize(new Dimension(150, 45));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFont(new Font("Arial", Font.BOLD, 14));
        btn.setBorder(new LineBorder(new Color(0, 200, 200), 2));
        btn.setFocusPainted(false);
        btn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        
        // Efect hover
        btn.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                btn.setBackground(hoverColor);
            }
            public void mouseExited(java.awt.event.MouseEvent evt) {
                btn.setBackground(bgColor);
            }
        });
        
        return btn;
    }

    public void updateFriends(List<String> friends) {
        listContainer.removeAll();
        for (String f : friends) {
            JPanel p = new JPanel(new BorderLayout());
            p.setMaximumSize(new Dimension(800, 50));
            p.setBackground(new Color(0, 60, 60));
            p.setBorder(new LineBorder(Color.CYAN));

            JLabel lbl = new JLabel("  👤 " + f.toUpperCase());
            lbl.setForeground(Color.WHITE);
            lbl.setFont(new Font("Arial", Font.BOLD, 16));
            p.add(lbl, BorderLayout.WEST);

            JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 0));
            actions.setOpaque(false);

            // FIX: Butoanele albe să intre în culorile aplicației
            JButton msgBtn = new JButton("MESAJE");
            msgBtn.setBackground(new Color(0, 120, 120));
            msgBtn.setForeground(Color.WHITE);
            msgBtn.setFont(new Font("Arial", Font.BOLD, 12));
            msgBtn.setBorder(new LineBorder(new Color(0, 200, 200), 1));
            msgBtn.setPreferredSize(new Dimension(100, 35));
            msgBtn.setFocusPainted(false);
            msgBtn.setCursor(new Cursor(Cursor.HAND_CURSOR));
            msgBtn.addMouseListener(new java.awt.event.MouseAdapter() {
                public void mouseEntered(java.awt.event.MouseEvent evt) {
                    msgBtn.setBackground(new Color(0, 150, 150));
                }
                public void mouseExited(java.awt.event.MouseEvent evt) {
                    msgBtn.setBackground(new Color(0, 120, 120));
                }
            });
            msgBtn.addActionListener(e -> parent.openChatWith(f));

            JButton delBtn = new JButton("ȘTERGE");
            delBtn.setBackground(new Color(150, 0, 0));
            delBtn.setForeground(Color.WHITE);
            delBtn.setFont(new Font("Arial", Font.BOLD, 12));
            delBtn.setBorder(new LineBorder(new Color(200, 0, 0), 1));
            delBtn.setPreferredSize(new Dimension(100, 35));
            delBtn.setFocusPainted(false);
            delBtn.setCursor(new Cursor(Cursor.HAND_CURSOR));
            delBtn.addMouseListener(new java.awt.event.MouseAdapter() {
                public void mouseEntered(java.awt.event.MouseEvent evt) {
                    delBtn.setBackground(new Color(200, 0, 0));
                }
                public void mouseExited(java.awt.event.MouseEvent evt) {
                    delBtn.setBackground(new Color(150, 0, 0));
                }
            });
            delBtn.addActionListener(e -> {
                int resp = JOptionPane.showConfirmDialog(this, "Ștergi prietenul " + f + "?");
                if(resp == JOptionPane.YES_OPTION) parent.sendNetworkMessage("REMOVE_FRIEND", f);
            });

            actions.add(msgBtn); actions.add(delBtn);
            p.add(actions, BorderLayout.EAST);

            listContainer.add(p);
            listContainer.add(Box.createRigidArea(new Dimension(0, 5)));
        }
        listContainer.revalidate(); listContainer.repaint();
    }
}