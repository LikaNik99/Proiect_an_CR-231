package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.util.List;

public class LobbyPanel extends JPanel {
    private ClientApp parent;
    private JLabel welcomeLabel, balanceDisplay, statusLabel;
    private DefaultListModel<String> tablesModel;
    private JList<String> tablesList;
    private JButton adminBtn; // FIX: Referință la butonul admin

    public LobbyPanel(ClientApp parent) {
        this.parent = parent;
        setBackground(new Color(0, 50, 50)); 
        setLayout(new BorderLayout(20, 20));
        setBorder(new EmptyBorder(30, 30, 30, 30));

        JPanel header = new JPanel(new BorderLayout());
        header.setOpaque(false);
        welcomeLabel = new JLabel("ROYAL LOUNGE", SwingConstants.CENTER);
        welcomeLabel.setFont(new Font("Serif", Font.BOLD, 36));
        welcomeLabel.setForeground(Color.CYAN);

        // FIX: Buton ADMIN în stânga sus
        this.adminBtn = createCasinoBtn("ADMIN");
        adminBtn.setBackground(new Color(150, 0, 0)); // Roșu pentru admin
        adminBtn.setPreferredSize(new Dimension(80, 25));
        adminBtn.setFont(new Font("Arial", Font.BOLD, 10));
        adminBtn.setVisible(false); // Ascuns până când se setează modul admin
        adminBtn.addActionListener(e -> parent.showAdmin());

        // PROFIL SUS DREAPTA MIC
        JButton profileBtn = new JButton("PROFIL");
        profileBtn.setPreferredSize(new Dimension(80, 25));
        profileBtn.setFont(new Font("Arial", Font.BOLD, 10));
        profileBtn.setBackground(new Color(0, 80, 80));
        profileBtn.setForeground(Color.WHITE);
        // REPARARE: Profilul acum cere date proaspete de la server
        profileBtn.addActionListener(e -> parent.sendNetworkMessage("GET_PROFILE_INFO", ""));

        JPanel topBar = new JPanel(new BorderLayout());
        topBar.setOpaque(false);
        topBar.add(adminBtn, BorderLayout.WEST); // FIX: Admin în stânga
        JPanel rightPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        rightPanel.setOpaque(false);
        rightPanel.add(profileBtn);
        topBar.add(rightPanel, BorderLayout.EAST); // Profil în dreapta

        balanceDisplay = new JLabel("CHIPS: $" + parent.getBalance(), SwingConstants.RIGHT);
        balanceDisplay.setForeground(Color.ORANGE);
        balanceDisplay.setFont(new Font("Arial", Font.BOLD, 18));
        
        // FIX: Status label pentru a arăta dacă ești la masă
        statusLabel = new JLabel(" ", SwingConstants.LEFT);
        statusLabel.setForeground(Color.GREEN);
        statusLabel.setFont(new Font("Arial", Font.BOLD, 14));
        
        header.add(topBar, BorderLayout.NORTH);
        header.add(welcomeLabel, BorderLayout.CENTER);
        JPanel bottomHeader = new JPanel(new BorderLayout());
        bottomHeader.setOpaque(false);
        bottomHeader.add(balanceDisplay, BorderLayout.EAST);
        bottomHeader.add(statusLabel, BorderLayout.WEST);
        header.add(bottomHeader, BorderLayout.SOUTH);
        add(header, BorderLayout.NORTH);

        tablesModel = new DefaultListModel<>();
        tablesList = new JList<>(tablesModel);
        tablesList.setBackground(new Color(0, 70, 70));
        tablesList.setForeground(Color.WHITE);
        tablesList.setFont(new Font("SansSerif", Font.BOLD, 18));
        
        JScrollPane scroll = new JScrollPane(tablesList);
        scroll.setBorder(new TitledBorder(new LineBorder(Color.CYAN), "MESE ACTIVE", 0, 0, null, Color.CYAN));
        add(scroll, BorderLayout.CENTER);

        // FIX: GridLayout cu 5 coloane pentru distribuție uniformă (fără admin jos)
        JPanel controls = new JPanel(new GridLayout(1, 5, 10, 0));
        controls.setOpaque(false);

        JButton createBtn = createCasinoBtn("CREEAZĂ MASĂ");
        JButton joinBtn = createCasinoBtn("JOACĂ ACUM");
        JButton dailyBtn = createCasinoBtn("DAILY REWARD");
        JButton missionsBtn = createCasinoBtn("MISSIONS");
        JButton friendsBtn = createCasinoBtn("PRIETENI");

        createBtn.addActionListener(e -> {
            String name = JOptionPane.showInputDialog("Nume masă:");
            if (name != null && !name.trim().isEmpty()) {
                String bet = JOptionPane.showInputDialog("Bet minim:", "100");
                parent.sendNetworkMessage("CREATE_TABLE", name.trim() + "|" + bet.trim());
            }
        });

        joinBtn.addActionListener(e -> {
            if (tablesList.getSelectedIndex() != -1) parent.showGame();
            else JOptionPane.showMessageDialog(this, "Selectează o masă!");
        });

        dailyBtn.addActionListener(e -> parent.sendNetworkMessage("DAILY_REWARD", ""));
        missionsBtn.addActionListener(e -> parent.sendNetworkMessage("GET_MISSIONS", ""));
        // REPARARE: Butonul Prieteni acum deschide pagina corectă
        friendsBtn.addActionListener(e -> parent.showFriends());

        controls.add(createBtn); controls.add(joinBtn); controls.add(dailyBtn); 
        controls.add(missionsBtn); controls.add(friendsBtn);
        add(controls, BorderLayout.SOUTH);
    }

    private JButton createCasinoBtn(String t) {
        JButton b = new JButton(t);
        b.setBackground(new Color(0, 100, 100));
        b.setForeground(Color.WHITE);
        b.setFont(new Font("SansSerif", Font.BOLD, 12));
        b.setBorder(new LineBorder(Color.CYAN));
        return b;
    }

    public void setUsername(String user) { welcomeLabel.setText("BINE AI VENIT, " + user.toUpperCase() + "!"); }
    public void updateBalanceDisplay(String bal) { balanceDisplay.setText("CHIPS: $" + bal); }
    
    public void setPlayerAtTable(boolean atTable) { 
        if (atTable) {
            statusLabel.setText("🔴 LA MASĂ"); 
            statusLabel.setForeground(Color.GREEN);
        } else {
            statusLabel.setText(" "); 
        }
    }
    
    public void setAdminMode(boolean admin) {
        // FIX: Afișează butonul admin dacă utilizatorul este admin
        if (adminBtn != null) {
            adminBtn.setVisible(admin);
        }
    }

    public void updateTableList(List<String> tables) {
        SwingUtilities.invokeLater(() -> {
            tablesModel.clear();
            for (String t : tables) {
                String[] p = t.split("\\|");
                if (p.length >= 4) {
                    int total = Integer.parseInt(p[1]);
                    int occupied = Integer.parseInt(p[2]);
                    // REPARARE: Formatul cerut: Disponibile și Ocupate
                    tablesModel.addElement(p[0] + " - Disponibile: " + (total - occupied) + " - Ocupate: " + occupied + " - Bet: $" + p[3]);
                }
            }
        });
    }
}