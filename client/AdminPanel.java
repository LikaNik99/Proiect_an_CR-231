package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.util.List;
import javax.swing.Timer;

public class AdminPanel extends JPanel {
    private ClientApp parent;
    private DefaultListModel<String> usersModel;
    private JList<String> usersList;
    private DefaultListModel<String> tablesModel;
    private JList<String> tablesList;
    private DefaultListModel<String> onlineUsersModel;
    private JList<String> onlineUsersList;
    
    // Statistics labels
    private JLabel registeredLabel, onlineLabel, offlineLabel;
    private Timer refreshTimer;
    
    public AdminPanel(ClientApp parent) {
        this.parent = parent;
        setLayout(new BorderLayout(15, 15));
        setBackground(new Color(0, 40, 40));
        setBorder(new EmptyBorder(15, 15, 15, 15));

        // Header
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setOpaque(false);
        
        JLabel title = new JLabel("PANEL ADMINISTRATOR", SwingConstants.CENTER);
        title.setFont(new Font("Serif", Font.BOLD, 32));
        title.setForeground(Color.RED);
        headerPanel.add(title, BorderLayout.CENTER);
        
        // Statistics panel at top
        JPanel statsPanel = createStatsPanel();
        headerPanel.add(statsPanel, BorderLayout.SOUTH);
        
        add(headerPanel, BorderLayout.NORTH);

        // Main content - split în trei panouri
        JPanel mainContent = new JPanel(new GridLayout(1, 3, 15, 0));
        mainContent.setOpaque(false);

        // Panou utilizatori
        JPanel usersPanel = createUsersPanel();
        mainContent.add(usersPanel);
        
        // Panou jucători online
        JPanel onlinePanel = createOnlinePanel();
        mainContent.add(onlinePanel);

        // Panou mese
        JPanel tablesPanel = createTablesPanel();
        mainContent.add(tablesPanel);

        add(mainContent, BorderLayout.CENTER);

        // Buton înapoi și istoric
        JPanel bottomPanel = new JPanel(new BorderLayout(10, 0));
        bottomPanel.setOpaque(false);
        
        JButton historyBtn = createAdminBtn("ISTORIC ACȚIUNI", new Color(100, 50, 150));
        historyBtn.addActionListener(e -> showHistory());
        bottomPanel.add(historyBtn, BorderLayout.WEST);
        
        JButton backBtn = createAdminBtn("ÎNAPOI LA LOBBY", Color.GRAY);
        backBtn.addActionListener(e -> parent.showLobby());
        bottomPanel.add(backBtn, BorderLayout.EAST);
        
        add(bottomPanel, BorderLayout.SOUTH);
        
        // Timer pentru actualizare automată la fiecare 5 secunde
        refreshTimer = new Timer(5000, e -> refreshData());
        refreshTimer.setRepeats(true);
        refreshTimer.start();
    }
    
    public void startRefreshTimer() {
        if (refreshTimer != null && !refreshTimer.isRunning()) {
            refreshTimer.start();
        }
    }
    
    public void stopRefreshTimer() {
        if (refreshTimer != null && refreshTimer.isRunning()) {
            refreshTimer.stop();
        }
    }
    
    private JPanel createStatsPanel() {
        JPanel stats = new JPanel(new FlowLayout(FlowLayout.CENTER, 30, 10));
        stats.setOpaque(false);
        stats.setBorder(new TitledBorder(new LineBorder(Color.CYAN, 2), "STATISTICI", 0, 0, null, Color.CYAN));
        
        registeredLabel = createStatLabel("JUCĂTORI ÎNREGISTRAȚI", "0", Color.GREEN);
        onlineLabel = createStatLabel("JUCĂTORI ONLINE", "0", Color.CYAN);
        offlineLabel = createStatLabel("JUCĂTORI OFFLINE", "0", Color.ORANGE);
        
        stats.add(registeredLabel);
        stats.add(onlineLabel);
        stats.add(offlineLabel);
        
        return stats;
    }
    
    private JLabel createStatLabel(String title, String value, Color color) {
        JLabel label = new JLabel("<html><center><b>" + title + "</b><br><font size='+2' color='" + 
                                  String.format("#%02x%02x%02x", color.getRed(), color.getGreen(), color.getBlue()) + 
                                  "'>" + value + "</font></center></html>", SwingConstants.CENTER);
        label.setFont(new Font("Arial", Font.BOLD, 12));
        label.setForeground(Color.WHITE);
        label.setBorder(new EmptyBorder(10, 20, 10, 20));
        label.setBackground(new Color(0, 60, 60));
        label.setOpaque(true);
        label.setBorder(new CompoundBorder(new LineBorder(color, 2), new EmptyBorder(5, 10, 5, 10)));
        return label;
    }
    
    private JPanel createUsersPanel() {
        JPanel usersPanel = new JPanel(new BorderLayout());
        usersPanel.setOpaque(false);
        usersPanel.setBorder(new TitledBorder(new LineBorder(Color.RED, 2), "TOȚI UTILIZATORII", 0, 0, null, Color.RED));
        
        usersModel = new DefaultListModel<>();
        usersList = new JList<>(usersModel);
        usersList.setBackground(new Color(0, 60, 60));
        usersList.setForeground(Color.WHITE);
        usersList.setFont(new Font("Arial", Font.PLAIN, 11));
        usersList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        
        JScrollPane usersScroll = new JScrollPane(usersList);
        usersPanel.add(usersScroll, BorderLayout.CENTER);

        JPanel usersActions = new JPanel(new GridLayout(2, 2, 5, 5));
        usersActions.setOpaque(false);
        
        JButton viewUserBtn = createAdminBtn("VEZI PROFIL", Color.CYAN);
        JButton banUserBtn = createAdminBtn("BAN", Color.RED);
        JButton deleteUserBtn = createAdminBtn("ȘTERGE", Color.ORANGE);
        JButton refreshUsersBtn = createAdminBtn("REÎNCARCĂ", new Color(0, 150, 150));
        
        viewUserBtn.addActionListener(e -> viewUserProfile());
        banUserBtn.addActionListener(e -> banUser());
        deleteUserBtn.addActionListener(e -> deleteUser());
        refreshUsersBtn.addActionListener(e -> refreshData());

        usersActions.add(viewUserBtn);
        usersActions.add(banUserBtn);
        usersActions.add(deleteUserBtn);
        usersActions.add(refreshUsersBtn);
        
        usersPanel.add(usersActions, BorderLayout.SOUTH);
        return usersPanel;
    }
    
    private JPanel createOnlinePanel() {
        JPanel onlinePanel = new JPanel(new BorderLayout());
        onlinePanel.setOpaque(false);
        onlinePanel.setBorder(new TitledBorder(new LineBorder(Color.CYAN, 2), "JUCĂTORI ONLINE", 0, 0, null, Color.CYAN));
        
        onlineUsersModel = new DefaultListModel<>();
        onlineUsersList = new JList<>(onlineUsersModel);
        onlineUsersList.setBackground(new Color(0, 60, 60));
        onlineUsersList.setForeground(Color.GREEN);
        onlineUsersList.setFont(new Font("Arial", Font.BOLD, 12));
        onlineUsersList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        
        JScrollPane onlineScroll = new JScrollPane(onlineUsersList);
        onlinePanel.add(onlineScroll, BorderLayout.CENTER);
        
        JPanel onlineActions = new JPanel(new GridLayout(1, 1, 5, 5));
        onlineActions.setOpaque(false);
        JButton refreshOnlineBtn = createAdminBtn("REÎNCARCĂ", new Color(0, 150, 150));
        refreshOnlineBtn.addActionListener(e -> refreshData());
        onlineActions.add(refreshOnlineBtn);
        onlinePanel.add(onlineActions, BorderLayout.SOUTH);
        
        return onlinePanel;
    }
    
    private JPanel createTablesPanel() {
        JPanel tablesPanel = new JPanel(new BorderLayout());
        tablesPanel.setOpaque(false);
        tablesPanel.setBorder(new TitledBorder(new LineBorder(Color.YELLOW, 2), "MESE ACTIVE", 0, 0, null, Color.YELLOW));
        
        tablesModel = new DefaultListModel<>();
        tablesList = new JList<>(tablesModel);
        tablesList.setBackground(new Color(0, 60, 60));
        tablesList.setForeground(Color.WHITE);
        tablesList.setFont(new Font("Arial", Font.PLAIN, 11));
        tablesList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        
        JScrollPane tablesScroll = new JScrollPane(tablesList);
        tablesPanel.add(tablesScroll, BorderLayout.CENTER);

        JPanel tablesActions = new JPanel(new GridLayout(2, 1, 5, 5));
        tablesActions.setOpaque(false);
        
        JButton createTableBtn = createAdminBtn("CREEAZĂ MASĂ", Color.GREEN);
        JButton deleteTableBtn = createAdminBtn("ȘTERGE MASĂ", Color.RED);
        
        createTableBtn.addActionListener(e -> createTable());
        deleteTableBtn.addActionListener(e -> deleteTable());

        tablesActions.add(createTableBtn);
        tablesActions.add(deleteTableBtn);
        tablesPanel.add(tablesActions, BorderLayout.SOUTH);
        
        return tablesPanel;
    }

    private JButton createAdminBtn(String text, Color color) {
        JButton btn = new JButton(text);
        btn.setBackground(color);
        btn.setForeground(Color.WHITE);
        btn.setFont(new Font("Arial", Font.BOLD, 11));
        btn.setBorder(new LineBorder(Color.WHITE, 1));
        btn.setFocusPainted(false);
        return btn;
    }
    
    private void viewUserProfile() {
        int idx = usersList.getSelectedIndex();
        if (idx == -1) {
            JOptionPane.showMessageDialog(this, "Selectează un utilizator!", "Eroare", JOptionPane.WARNING_MESSAGE);
            return;
        }
        
        String userData = usersModel.getElementAt(idx);
        String[] parts = userData.split("\\|");
        if (parts.length < 5) {
            JOptionPane.showMessageDialog(this, "Date invalide pentru utilizator!", "Eroare", JOptionPane.ERROR_MESSAGE);
            return;
        }
        
        String username = parts[0];
        String email = parts[1];
        String balance = parts[3];
        String regDate = parts[4];
        
        // Create profile dialog with balance modification
        JDialog profileDialog = new JDialog((Frame) SwingUtilities.getWindowAncestor(this), "Profil Utilizator: " + username, true);
        profileDialog.setSize(450, 400);
        profileDialog.setLocationRelativeTo(this);
        profileDialog.setLayout(new BorderLayout(10, 10));
        profileDialog.getContentPane().setBackground(new Color(0, 40, 40));
        
        // Info panel
        JPanel infoPanel = new JPanel();
        infoPanel.setLayout(new BoxLayout(infoPanel, BoxLayout.Y_AXIS));
        infoPanel.setBackground(new Color(0, 60, 60));
        infoPanel.setBorder(new EmptyBorder(15, 15, 15, 15));
        
        JLabel usernameLabel = new JLabel("Username: " + username);
        usernameLabel.setForeground(Color.WHITE);
        usernameLabel.setFont(new Font("Arial", Font.BOLD, 14));
        
        JLabel emailLabel = new JLabel("Email: " + email);
        emailLabel.setForeground(Color.WHITE);
        
        JLabel regDateLabel = new JLabel("Membru din: " + regDate);
        regDateLabel.setForeground(Color.WHITE);
        
        infoPanel.add(usernameLabel);
        infoPanel.add(Box.createVerticalStrut(10));
        infoPanel.add(emailLabel);
        infoPanel.add(Box.createVerticalStrut(10));
        infoPanel.add(regDateLabel);
        infoPanel.add(Box.createVerticalStrut(20));
        
        // Balance modification
        JPanel balancePanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        balancePanel.setOpaque(false);
        JLabel balanceLabel = new JLabel("Balanță: $");
        balanceLabel.setForeground(Color.GREEN);
        balanceLabel.setFont(new Font("Arial", Font.BOLD, 14));
        JTextField balanceField = new JTextField(balance, 10);
        balanceField.setFont(new Font("Arial", Font.BOLD, 14));
        JButton updateBalanceBtn = new JButton("Actualizează");
        updateBalanceBtn.setBackground(Color.GREEN);
        updateBalanceBtn.setForeground(Color.WHITE);
        updateBalanceBtn.addActionListener(e -> {
            try {
                int newBalance = Integer.parseInt(balanceField.getText());
                parent.sendNetworkMessage("ADMIN_UPDATE_BALANCE", username + "|" + newBalance);
                profileDialog.dispose();
            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(profileDialog, "Balanța trebuie să fie un număr!", "Eroare", JOptionPane.ERROR_MESSAGE);
            }
        });
        balancePanel.add(balanceLabel);
        balancePanel.add(balanceField);
        balancePanel.add(updateBalanceBtn);
        infoPanel.add(balancePanel);
        
        profileDialog.add(infoPanel, BorderLayout.CENTER);
        
        // Buttons
        JPanel buttonPanel = new JPanel(new FlowLayout());
        buttonPanel.setOpaque(false);
        JButton closeBtn = new JButton("Închide");
        closeBtn.addActionListener(e -> profileDialog.dispose());
        buttonPanel.add(closeBtn);
        profileDialog.add(buttonPanel, BorderLayout.SOUTH);
        
        profileDialog.setVisible(true);
    }
    
    private void banUser() {
        int idx = usersList.getSelectedIndex();
        if (idx == -1) {
            JOptionPane.showMessageDialog(this, "Selectează un utilizator!", "Eroare", JOptionPane.WARNING_MESSAGE);
            return;
        }
        
        String userData = usersModel.getElementAt(idx);
        String username = userData.split("\\|")[0];
        
        if (username.equalsIgnoreCase("admin")) {
            JOptionPane.showMessageDialog(this, "Nu poți bana administratorul!", "Eroare", JOptionPane.ERROR_MESSAGE);
            return;
        }
        
        int resp = JOptionPane.showConfirmDialog(this, 
            "Ești sigur că vrei să banezi utilizatorul " + username + "?", 
            "Confirmare Ban", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
        if (resp == JOptionPane.YES_OPTION) {
            parent.sendNetworkMessage("ADMIN_BAN_USER", username);
        }
    }
    
    private void deleteUser() {
        int idx = usersList.getSelectedIndex();
        if (idx == -1) {
            JOptionPane.showMessageDialog(this, "Selectează un utilizator!", "Eroare", JOptionPane.WARNING_MESSAGE);
            return;
        }
        
        String userData = usersModel.getElementAt(idx);
        String username = userData.split("\\|")[0];
        
        if (username.equalsIgnoreCase("admin")) {
            JOptionPane.showMessageDialog(this, "Nu poți șterge administratorul!", "Eroare", JOptionPane.ERROR_MESSAGE);
            return;
        }
        
        int resp = JOptionPane.showConfirmDialog(this, 
            "Ești sigur că vrei să ștergi utilizatorul " + username + "?", 
            "Confirmare Ștergere", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
        if (resp == JOptionPane.YES_OPTION) {
            parent.sendNetworkMessage("ADMIN_DELETE_USER", username);
        }
    }
    
    private void createTable() {
        JTextField nameField = new JTextField(15);
        JTextField minBetField = new JTextField(15);
        
        JPanel inputPanel = new JPanel(new GridLayout(2, 2, 5, 5));
        inputPanel.add(new JLabel("Nume masă:"));
        inputPanel.add(nameField);
        inputPanel.add(new JLabel("Min bet:"));
        inputPanel.add(minBetField);
        
        int result = JOptionPane.showConfirmDialog(this, inputPanel, 
            "Creează Masă Nouă", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
        
        if (result == JOptionPane.OK_OPTION) {
            String name = nameField.getText().trim();
            String minBet = minBetField.getText().trim();
            
            if (name.isEmpty() || minBet.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Completează toate câmpurile!", "Eroare", JOptionPane.ERROR_MESSAGE);
                return;
            }
            
            try {
                Integer.parseInt(minBet);
                parent.sendNetworkMessage("ADMIN_CREATE_TABLE", name + "|" + minBet);
            } catch (NumberFormatException e) {
                JOptionPane.showMessageDialog(this, "Min bet trebuie să fie un număr!", "Eroare", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    private void deleteTable() {
        int idx = tablesList.getSelectedIndex();
        if (idx == -1) {
            JOptionPane.showMessageDialog(this, "Selectează o masă!", "Eroare", JOptionPane.WARNING_MESSAGE);
            return;
        }
        
        String tableData = tablesModel.getElementAt(idx);
        String tableName = tableData.split("\\|")[0];
        
        int resp = JOptionPane.showConfirmDialog(this, 
            "Ești sigur că vrei să ștergi masa " + tableName + "?", 
            "Confirmare Ștergere", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
        if (resp == JOptionPane.YES_OPTION) {
            parent.sendNetworkMessage("ADMIN_DELETE_TABLE", tableName);
        }
    }
    
    private void showHistory() {
        parent.sendNetworkMessage("ADMIN_GET_HISTORY", "50");
    }
    
    private void refreshData() {
        parent.sendNetworkMessage("ADMIN_GET_USERS", "");
        parent.sendNetworkMessage("ADMIN_GET_TABLES", "");
        parent.sendNetworkMessage("ADMIN_GET_STATS", "");
        parent.sendNetworkMessage("ADMIN_GET_ONLINE_USERS", "");
    }

    public void updateUsers(List<String> users) {
        SwingUtilities.invokeLater(() -> {
            usersModel.clear();
            for (String user : users) {
                if (!user.trim().isEmpty()) {
                    usersModel.addElement(user);
                }
            }
        });
    }

    public void updateTables(List<String> tables) {
        SwingUtilities.invokeLater(() -> {
            tablesModel.clear();
            for (String table : tables) {
                tablesModel.addElement(table);
            }
        });
    }
    
    public void updateStats(String stats) {
        SwingUtilities.invokeLater(() -> {
            String[] parts = stats.split("\\|");
            if (parts.length == 3) {
                registeredLabel.setText("<html><center><b>JUCĂTORI ÎNREGISTRAȚI</b><br><font size='+2' color='#00FF00'>" + parts[0] + "</font></center></html>");
                onlineLabel.setText("<html><center><b>JUCĂTORI ONLINE</b><br><font size='+2' color='#00FFFF'>" + parts[1] + "</font></center></html>");
                offlineLabel.setText("<html><center><b>JUCĂTORI OFFLINE</b><br><font size='+2' color='#FFA500'>" + parts[2] + "</font></center></html>");
            }
        });
    }
    
    public void updateOnlineUsers(List<String> onlineUsers) {
        SwingUtilities.invokeLater(() -> {
            onlineUsersModel.clear();
            if (onlineUsers != null) {
                for (String user : onlineUsers) {
                    if (user != null && !user.trim().isEmpty() && !user.equalsIgnoreCase("admin")) {
                        onlineUsersModel.addElement("🟢 " + user);
                    }
                }
            }
        });
    }
    
    public void showHistoryDialog(List<String> history) {
        SwingUtilities.invokeLater(() -> {
            JDialog historyDialog = new JDialog((Frame) SwingUtilities.getWindowAncestor(this), "Istoric Acțiuni Admin", true);
            historyDialog.setSize(700, 500);
            historyDialog.setLocationRelativeTo(this);
            historyDialog.setLayout(new BorderLayout());
            historyDialog.getContentPane().setBackground(new Color(0, 40, 40));
            
            DefaultListModel<String> historyModel = new DefaultListModel<>();
            for (String entry : history) {
                if (entry != null && !entry.trim().isEmpty()) {
                    String[] parts = entry.split("\\|");
                    if (parts.length >= 4) {
                        historyModel.addElement(parts[0] + " | " + parts[1] + " | " + parts[2] + " | " + parts[3]);
                    } else {
                        historyModel.addElement(entry);
                    }
                }
            }
            
            JList<String> historyList = new JList<>(historyModel);
            historyList.setBackground(new Color(0, 60, 60));
            historyList.setForeground(Color.WHITE);
            historyList.setFont(new Font("Courier New", Font.PLAIN, 11));
            
            JScrollPane scrollPane = new JScrollPane(historyList);
            historyDialog.add(scrollPane, BorderLayout.CENTER);
            
            JButton closeBtn = new JButton("Închide");
            closeBtn.addActionListener(e -> historyDialog.dispose());
            JPanel buttonPanel = new JPanel();
            buttonPanel.setOpaque(false);
            buttonPanel.add(closeBtn);
            historyDialog.add(buttonPanel, BorderLayout.SOUTH);
            
            historyDialog.setVisible(true);
        });
    }
}
