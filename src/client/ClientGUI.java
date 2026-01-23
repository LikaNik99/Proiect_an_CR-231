package client;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Collections;
import shared.*;

public class ClientGUI extends JFrame {
    // Network
    private Socket socket;
    private ObjectOutputStream objectOut;
    private ObjectInputStream objectIn;
    private boolean isConnected = false;

    // User data
    private User currentUser;
    private String sessionId;

    // Current state
    private ForumThread currentThread;
    private List<ForumThread> threadList = new ArrayList<>();
    private List<Comment> commentList = new ArrayList<>();
    private List<Tag> tagList = new ArrayList<>();
    private List<ActiveUser> activeUsers = new ArrayList<>();

    // Protocol state flags
    private boolean expectingCommentsList = false;
    private boolean pendingCommentsRequest = false;
    private long commentsRequestAt = 0L;
    private boolean expectingThreadUpdate = false;
    private boolean expectingActiveUsersUpdate = false;

    // UI Components - references
    private CardLayout mainCardLayout;
    private JPanel mainPanel;
    private JTextField authUsernameField;
    private JPasswordField authPasswordField;
    private DefaultListModel<ForumThread> threadListModel;
    private JList<ForumThread> threadJList;
    private JLabel userInfoLabel;
    private JPanel contentPanel;
    private DefaultListModel<ActiveUser> activeUsersModel;
    private JList<ActiveUser> activeUsersList;

    // Labels for statistics
    private JLabel threadCountLabel;
    private JLabel commentsCountLabel;
    private JLabel onlineCountLabel;

    // Current reply state
    private Comment currentReplyTo = null;

    // Reference to main components
    private ThreadViewPanel currentThreadViewPanel;
    private JPanel replyIndicatorPanel;
    private JLabel replyToLabel;

    // Modern Color Scheme
    private final Color DARK_BG = new Color(18, 22, 30);
    private final Color CARD_BG = new Color(30, 35, 45);
    private final Color TEXT_COLOR = new Color(248, 248, 248);
    private final Color BORDER_COLOR = new Color(50, 55, 65);
    private final Color INPUT_BG = new Color(25, 30, 40);
    private final Color REPLY_BG = new Color(40, 45, 55);
    private final Color HOVER_COLOR = new Color(70, 75, 85);
    private final Color ACCENT_COLOR = new Color(88, 101, 242);
    private final Color SUCCESS_COLOR = new Color(46, 204, 113);
    private final Color DANGER_COLOR = new Color(231, 76, 60);
    private final Color WARNING_COLOR = new Color(241, 196, 15);

    // Heartbeat timer
    private Timer heartbeatTimer;
    private Timer refreshTimer;
    private Timer commentsReloadTimer;

    // Connection status
    private JLabel connectionStatusLabel;
    private JPanel statusPanel;

    // Context menu
    private JPopupMenu threadContextMenu;
    private JPopupMenu commentContextMenu;

    public ClientGUI() {
        setTitle("Forum App - UTM FCIM");
        setSize(1700, 1000);
        setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        setLocationRelativeTo(null);

        initUI();
        connectToServer();

        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                logoutAndExit();
            }
        });
    }

    private void initUI() {
        mainCardLayout = new CardLayout();
        mainPanel = new JPanel(mainCardLayout);
        mainPanel.setBackground(DARK_BG);

        JPanel authPanel = createAuthPanel();
        JPanel mainAppPanel = createMainAppPanel();

        mainPanel.add(authPanel, "AUTH");
        mainPanel.add(mainAppPanel, "MAIN");

        // Add status bar
        statusPanel = new JPanel(new BorderLayout());
        statusPanel.setBackground(CARD_BG);
        statusPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createMatteBorder(1, 0, 0, 0, BORDER_COLOR),
                BorderFactory.createEmptyBorder(3, 10, 3, 10)
        ));

        connectionStatusLabel = new JLabel("⏳ Conectare la server...");
        connectionStatusLabel.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        connectionStatusLabel.setForeground(Color.GRAY);

        JLabel versionLabel = new JLabel("v2.0 © 2024 UTM FCIM");
        versionLabel.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        versionLabel.setForeground(Color.GRAY);

        statusPanel.add(connectionStatusLabel, BorderLayout.WEST);
        statusPanel.add(versionLabel, BorderLayout.EAST);

        add(mainPanel, BorderLayout.CENTER);
        add(statusPanel, BorderLayout.SOUTH);

        mainCardLayout.show(mainPanel, "AUTH");
    }

    private JPanel createAuthPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(DARK_BG);
        panel.setBorder(BorderFactory.createEmptyBorder(0, 0, 0, 0));

        JPanel bgPanel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                Graphics2D g2d = (Graphics2D) g;
                Color color1 = new Color(18, 22, 30);
                Color color2 = new Color(30, 35, 45);
                GradientPaint gp = new GradientPaint(0, 0, color1, getWidth(), getHeight(), color2);
                g2d.setPaint(gp);
                g2d.fillRect(0, 0, getWidth(), getHeight());
            }
        };
        bgPanel.setLayout(new GridBagLayout());

        JPanel card = new JPanel(new GridBagLayout());
        card.setBackground(new Color(30, 35, 45, 220));
        card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(88, 101, 242, 100), 2),
                BorderFactory.createEmptyBorder(40, 40, 40, 40)
        ));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(10, 10, 10, 10);
        gbc.gridwidth = 2;

        // Logo and title
        gbc.gridx = 0; gbc.gridy = 0;
        JLabel logoLabel = new JLabel("💬");
        logoLabel.setFont(new Font("Segoe UI Emoji", Font.PLAIN, 48));
        logoLabel.setHorizontalAlignment(SwingConstants.CENTER);
        card.add(logoLabel, gbc);

        gbc.gridy++;
        JLabel titleLabel = new JLabel("FORUM UTM");
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 32));
        titleLabel.setForeground(TEXT_COLOR);
        titleLabel.setHorizontalAlignment(SwingConstants.CENTER);
        card.add(titleLabel, gbc);

        gbc.gridy++;
        JLabel subtitleLabel = new JLabel("Aplicație Client-Server Avansată");
        subtitleLabel.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        subtitleLabel.setForeground(Color.GRAY);
        subtitleLabel.setHorizontalAlignment(SwingConstants.CENTER);
        card.add(subtitleLabel, gbc);

        gbc.gridy++;
        card.add(Box.createVerticalStrut(30), gbc);

        JTabbedPane tabbedPane = new JTabbedPane(JTabbedPane.TOP);
        tabbedPane.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        tabbedPane.setBackground(CARD_BG);
        tabbedPane.setForeground(TEXT_COLOR);
        tabbedPane.setBorder(BorderFactory.createLineBorder(BORDER_COLOR, 1));
        tabbedPane.setOpaque(true);

        // Modern tab styling
        try {
            tabbedPane.setUI(new javax.swing.plaf.basic.BasicTabbedPaneUI() {
                @Override
                protected void paintTabBackground(Graphics g, int tabPlacement, int tabIndex, int x, int y, int w, int h, boolean isSelected) {
                    if (isSelected) {
                        g.setColor(ACCENT_COLOR);
                        g.fillRect(x, y, w, h);
                    } else {
                        g.setColor(CARD_BG);
                        g.fillRect(x, y, w, h);
                    }
                }

                @Override
                protected void paintTabBorder(Graphics g, int tabPlacement, int tabIndex, int x, int y, int w, int h, boolean isSelected) {
                    // No borders
                }

                @Override
                protected void paintFocusIndicator(Graphics g, int tabPlacement, Rectangle[] rects, int tabIndex, Rectangle iconRect, Rectangle textRect, boolean isSelected) {
                    // No focus indicator
                }
            });
        } catch (Exception e) {
            // Fallback to default UI
        }

        tabbedPane.addTab("🔐 Autentificare", createLoginPanel());
        tabbedPane.addTab("📝 Înregistrare", createRegisterPanel());

        gbc.gridy++;
        gbc.gridwidth = 2;
        gbc.fill = GridBagConstraints.BOTH;
        gbc.weightx = 1.0;
        gbc.weighty = 1.0;
        card.add(tabbedPane, gbc);

        // Demo credentials
        gbc.gridy++;
        gbc.weighty = 0;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        JLabel demoLabel = new JLabel(
                "<html><center><font color='#95a5a6' size='2'>"
                        + "<b>Credențiale demo:</b><br>"
                        + "student / student123 &nbsp;&nbsp;|&nbsp;&nbsp; "
                        + "admin / admin123 &nbsp;&nbsp;|&nbsp;&nbsp; "
                        + "profesor / prof123"
                        + "</font></center></html>",
                SwingConstants.CENTER
        );
        demoLabel.setBorder(BorderFactory.createEmptyBorder(15, 0, 0, 0));
        card.add(demoLabel, gbc);

        // Add card to background panel with constraints
        GridBagConstraints bgGbc = new GridBagConstraints();
        bgGbc.gridx = 0;
        bgGbc.gridy = 0;
        bgGbc.weightx = 1.0;
        bgGbc.weighty = 1.0;
        bgGbc.anchor = GridBagConstraints.CENTER;
        bgPanel.add(card, bgGbc);

        panel.add(bgPanel, BorderLayout.CENTER);

        return panel;
    }

    private JPanel createLoginPanel() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBackground(CARD_BG);
        panel.setBorder(BorderFactory.createEmptyBorder(30, 30, 30, 30));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(8, 8, 8, 8);
        gbc.gridwidth = 2;

        // Title
        gbc.gridx = 0; gbc.gridy = 0;
        JLabel title = new JLabel("Autentificare", SwingConstants.CENTER);
        title.setFont(new Font("Segoe UI", Font.BOLD, 20));
        title.setForeground(TEXT_COLOR);
        panel.add(title, gbc);

        gbc.gridy++;
        panel.add(Box.createVerticalStrut(20), gbc);

        // Username
        gbc.gridy++; gbc.gridwidth = 1;
        JLabel userLabel = new JLabel("👤 Username:");
        userLabel.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        userLabel.setForeground(TEXT_COLOR);
        panel.add(userLabel, gbc);

        gbc.gridx = 1;
        authUsernameField = new JTextField(20);
        styleTextField(authUsernameField);
        authUsernameField.setText("student");
        panel.add(authUsernameField, gbc);

        // Password
        gbc.gridx = 0; gbc.gridy++;
        JLabel passLabel = new JLabel("🔒 Parolă:");
        passLabel.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        passLabel.setForeground(TEXT_COLOR);
        panel.add(passLabel, gbc);

        gbc.gridx = 1;
        authPasswordField = new JPasswordField(20);
        styleTextField(authPasswordField);
        authPasswordField.setText("student123");
        panel.add(authPasswordField, gbc);

        // Login button
        gbc.gridx = 0; gbc.gridy++; gbc.gridwidth = 2;
        gbc.anchor = GridBagConstraints.CENTER;
        gbc.insets = new Insets(20, 10, 10, 10);
        JButton loginButton = createModernButton("🚀 Autentificare", ACCENT_COLOR);
        loginButton.setPreferredSize(new Dimension(250, 45));
        loginButton.addActionListener(e -> login());

        // Add keyboard shortcut (Enter key)
        panel.getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(
                KeyStroke.getKeyStroke(KeyEvent.VK_ENTER, 0), "login"
        );
        panel.getActionMap().put("login", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                login();
            }
        });

        panel.add(loginButton, gbc);

        return panel;
    }

    private JPanel createRegisterPanel() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBackground(CARD_BG);
        panel.setBorder(BorderFactory.createEmptyBorder(30, 30, 30, 30));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(6, 8, 6, 8);

        gbc.gridx = 0; gbc.gridy = 0; gbc.gridwidth = 2;
        JLabel title = new JLabel("Creează cont nou", SwingConstants.CENTER);
        title.setFont(new Font("Segoe UI", Font.BOLD, 20));
        title.setForeground(TEXT_COLOR);
        panel.add(title, gbc);

        gbc.gridy++; gbc.gridwidth = 1;
        panel.add(Box.createVerticalStrut(15), gbc);

        String[] labels = {"👤 Username*:", "🔒 Parolă*:", "📧 Email*:", "👨‍💼 Nume complet:"};
        JTextField[] fields = new JTextField[4];
        JPasswordField passwordField = null;

        for (int i = 0; i < labels.length; i++) {
            gbc.gridx = 0; gbc.gridy = i + 2;
            JLabel label = new JLabel(labels[i]);
            label.setFont(new Font("Segoe UI", Font.PLAIN, 13));
            label.setForeground(TEXT_COLOR);
            panel.add(label, gbc);

            gbc.gridx = 1;
            if (i == 1) { // Password field
                passwordField = new JPasswordField(20);
                styleTextField(passwordField);
                panel.add(passwordField, gbc);
                JPasswordField finalPasswordField = passwordField;
                fields[i] = new JTextField() {
                    @Override
                    public String getText() {
                        return new String(finalPasswordField.getPassword());
                    }
                };
            } else {
                fields[i] = new JTextField(20);
                styleTextField(fields[i]);
                panel.add(fields[i], gbc);
            }
        }

        // Register button
        gbc.gridx = 0; gbc.gridy = labels.length + 2; gbc.gridwidth = 2;
        gbc.anchor = GridBagConstraints.CENTER;
        gbc.insets = new Insets(20, 10, 10, 10);
        JButton registerButton = createModernButton("📋 Creează cont", SUCCESS_COLOR);
        registerButton.setPreferredSize(new Dimension(250, 45));
        registerButton.addActionListener(e -> {
            register(fields[0].getText(), fields[1].getText(),
                    fields[2].getText(), fields[3].getText());
        });
        panel.add(registerButton, gbc);

        return panel;
    }

    private JPanel createMainAppPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(DARK_BG);

        panel.add(createToolbarPanel(), BorderLayout.NORTH);

        JSplitPane mainSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        mainSplitPane.setDividerLocation(280);
        mainSplitPane.setLeftComponent(createSidebarPanel());
        mainSplitPane.setRightComponent(createContentPanel());
        mainSplitPane.setBorder(null);
        mainSplitPane.setDividerSize(3);
        mainSplitPane.setResizeWeight(0.2);

        mainSplitPane.setDividerSize(5);
        mainSplitPane.setBorder(BorderFactory.createLineBorder(DARK_BG, 5));

        panel.add(mainSplitPane, BorderLayout.CENTER);

        return panel;
    }

    private JPanel createToolbarPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(DARK_BG);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createMatteBorder(0, 0, 1, 0, BORDER_COLOR),
                BorderFactory.createEmptyBorder(8, 20, 8, 20)
        ));

        // Left: Logo + User info
        JPanel leftPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 15, 0));
        leftPanel.setOpaque(false);

        JButton menuButton = new JButton("☰");
        menuButton.setFont(new Font("Segoe UI", Font.PLAIN, 20));
        menuButton.setBackground(CARD_BG);
        menuButton.setForeground(TEXT_COLOR);
        menuButton.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
        menuButton.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        menuButton.addActionListener(e -> showSidebarMenu());
        leftPanel.add(menuButton);

        JLabel logoLabel = new JLabel("💬 Forum UTM");
        logoLabel.setFont(new Font("Segoe UI", Font.BOLD, 20));
        logoLabel.setForeground(TEXT_COLOR);
        leftPanel.add(logoLabel);

        userInfoLabel = new JLabel(" | Neautentificat");
        userInfoLabel.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        userInfoLabel.setForeground(Color.GRAY);
        leftPanel.add(userInfoLabel);

        // Center: Search bar
        JPanel centerPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 10, 0));
        centerPanel.setOpaque(false);

        JTextField searchField = new JTextField(25);
        styleTextField(searchField);
        searchField.setForeground(Color.LIGHT_GRAY);
        searchField.setText("🔍 Caută thread-uri...");
        searchField.addFocusListener(new FocusAdapter() {
            @Override
            public void focusGained(FocusEvent e) {
                if (searchField.getText().equals("🔍 Caută thread-uri...")) {
                    searchField.setText("");
                    searchField.setForeground(TEXT_COLOR);
                }
            }

            @Override
            public void focusLost(FocusEvent e) {
                if (searchField.getText().isEmpty()) {
                    searchField.setText("🔍 Caută thread-uri...");
                    searchField.setForeground(Color.LIGHT_GRAY);
                }
            }
        });

        searchField.addActionListener(e -> searchThreads(searchField.getText()));

        JButton searchButton = createIconButton("🔍", "Caută");
        searchButton.addActionListener(e -> searchThreads(searchField.getText()));

        centerPanel.add(searchField);
        centerPanel.add(searchButton);

        // Right: Action buttons
        JPanel rightPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 0));
        rightPanel.setOpaque(false);

        JButton refreshButton = createIconButton("🔄", "Reîmprospătează");
        refreshButton.setBackground(ACCENT_COLOR);
        refreshButton.addActionListener(e -> {
            if (currentThread != null) {
                loadThreadDetails(currentThread.getThreadId());
            } else {
                loadThreads();
            }
        });

        JButton newThreadButton = createModernButton("📝 Thread nou", ACCENT_COLOR);
        newThreadButton.setPreferredSize(new Dimension(140, 35));
        newThreadButton.addActionListener(e -> showNewThreadDialog());

        JButton logoutButton = createModernButton("🚪 Deconectare", DANGER_COLOR);
        logoutButton.setPreferredSize(new Dimension(140, 35));
        logoutButton.addActionListener(e -> logout());

        rightPanel.add(refreshButton);
        rightPanel.add(newThreadButton);
        rightPanel.add(logoutButton);

        panel.add(leftPanel, BorderLayout.WEST);
        panel.add(centerPanel, BorderLayout.CENTER);
        panel.add(rightPanel, BorderLayout.EAST);

        return panel;
    }

    private void showSidebarMenu() {
        JPopupMenu menu = new JPopupMenu();
        menu.setBackground(CARD_BG);
        menu.setBorder(BorderFactory.createLineBorder(BORDER_COLOR, 1));

        JMenuItem profileItem = new JMenuItem("👤 Profilul meu");
        styleMenuItem(profileItem);
        profileItem.addActionListener(e -> showProfileDialog());

        JMenuItem settingsItem = new JMenuItem("⚙️ Setări");
        styleMenuItem(settingsItem);
        settingsItem.addActionListener(e -> showSettingsDialog());

        JMenuItem statsItem = new JMenuItem("📊 Statistici");
        styleMenuItem(statsItem);
        statsItem.addActionListener(e -> showStatisticsDialog());

        JMenuItem tagsItem = new JMenuItem("🏷️ Manager Tag-uri");
        styleMenuItem(tagsItem);
        tagsItem.addActionListener(e -> showTagManager());

        menu.add(profileItem);
        menu.add(settingsItem);
        menu.add(statsItem);
        menu.add(tagsItem);
        menu.addSeparator();

        JMenuItem aboutItem = new JMenuItem("ℹ️ Despre aplicație");
        styleMenuItem(aboutItem);
        aboutItem.addActionListener(e -> showAboutDialog());

        menu.add(aboutItem);

        Component source = (Component) SwingUtilities.getRoot(this);
        menu.show(source, 10, 40);
    }

    private void styleMenuItem(JMenuItem item) {
        item.setBackground(CARD_BG);
        item.setForeground(TEXT_COLOR);
        item.setBorder(BorderFactory.createEmptyBorder(8, 15, 8, 15));
        item.setFont(new Font("Segoe UI", Font.PLAIN, 13));

        item.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                item.setBackground(HOVER_COLOR);
            }

            @Override
            public void mouseExited(MouseEvent e) {
                item.setBackground(CARD_BG);
            }
        });
    }

    private JPanel createSidebarPanel() {
        JPanel panel = new JPanel(new BorderLayout(0, 10));
        panel.setBackground(DARK_BG);
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 5));

        // Header with filter options
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setBackground(CARD_BG);
        headerPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(12, 15, 12, 15)
        ));

        JLabel threadsLabel = new JLabel("📋 Thread-uri");
        threadsLabel.setFont(new Font("Segoe UI", Font.BOLD, 16));
        threadsLabel.setForeground(TEXT_COLOR);

        // Filter buttons
        JPanel filterPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 5, 0));
        filterPanel.setOpaque(false);

        JButton filterAll = createFilterButton("Toate", true);
        JButton filterPinned = createFilterButton("Fixate", false);
        JButton filterMine = createFilterButton("Mele", false);

        filterAll.addActionListener(e -> loadThreads());
        filterPinned.addActionListener(e -> filterPinnedThreads());
        filterMine.addActionListener(e -> filterMyThreads());

        filterPanel.add(filterAll);
        filterPanel.add(filterPinned);
        filterPanel.add(filterMine);

        headerPanel.add(threadsLabel, BorderLayout.WEST);
        headerPanel.add(filterPanel, BorderLayout.EAST);

        // Thread count
        JPanel countPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 5));
        countPanel.setBackground(CARD_BG);
        countPanel.setBorder(BorderFactory.createEmptyBorder(0, 15, 5, 15));

        threadCountLabel = new JLabel("0 thread-uri");
        threadCountLabel.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        threadCountLabel.setForeground(Color.GRAY);
        countPanel.add(threadCountLabel);

        // Threads list
        JPanel listPanel = new JPanel(new BorderLayout());
        listPanel.setBackground(CARD_BG);

        threadListModel = new DefaultListModel<>();
        threadJList = new JList<>(threadListModel) {
            @Override
            public int getScrollableUnitIncrement(Rectangle visibleRect, int orientation, int direction) {
                return 16;
            }
        };
        threadJList.setCellRenderer(new ThreadListRenderer());
        threadJList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        threadJList.setBackground(CARD_BG);
        threadJList.setFixedCellHeight(85);
        threadJList.addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting() && threadJList.getSelectedValue() != null) {
                loadThreadDetails(threadJList.getSelectedValue().getThreadId());
            }
        });

        // Add right-click context menu for threads
        createThreadContextMenu();

        JScrollPane threadsScroll = new JScrollPane(threadJList);
        threadsScroll.setBorder(BorderFactory.createLineBorder(BORDER_COLOR, 1));
        threadsScroll.getViewport().setBackground(CARD_BG);
        threadsScroll.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);

        JScrollBar verticalBar = threadsScroll.getVerticalScrollBar();
        try {
            verticalBar.setUI(new javax.swing.plaf.basic.BasicScrollBarUI() {
                @Override
                protected void configureScrollBarColors() {
                    this.thumbColor = BORDER_COLOR;
                    this.trackColor = DARK_BG;
                }

                @Override
                protected JButton createDecreaseButton(int orientation) {
                    return createInvisibleButton();
                }

                @Override
                protected JButton createIncreaseButton(int orientation) {
                    return createInvisibleButton();
                }

                private JButton createInvisibleButton() {
                    JButton button = new JButton();
                    button.setPreferredSize(new Dimension(0, 0));
                    button.setMinimumSize(new Dimension(0, 0));
                    button.setMaximumSize(new Dimension(0, 0));
                    return button;
                }
            });
        } catch (Exception e) {
            // Fallback to default scrollbar
        }

        listPanel.add(threadsScroll, BorderLayout.CENTER);

        // Assemble sidebar
        panel.add(headerPanel, BorderLayout.NORTH);
        panel.add(countPanel, BorderLayout.CENTER);
        panel.add(listPanel, BorderLayout.SOUTH);

        return panel;
    }

    private void createThreadContextMenu() {
        threadContextMenu = new JPopupMenu();
        threadContextMenu.setBackground(CARD_BG);
        threadContextMenu.setBorder(BorderFactory.createLineBorder(BORDER_COLOR, 1));

        JMenuItem viewItem = new JMenuItem("👁️ Vizualizează");
        styleMenuItem(viewItem);
        viewItem.addActionListener(e -> {
            ForumThread selected = threadJList.getSelectedValue();
            if (selected != null) {
                loadThreadDetails(selected.getThreadId());
            }
        });

        JMenuItem editItem = new JMenuItem("✏️ Editează");
        styleMenuItem(editItem);
        editItem.addActionListener(e -> {
            ForumThread selected = threadJList.getSelectedValue();
            if (selected != null && currentUser != null) {
                if (selected.getUserId() == currentUser.getUserId() || currentUser.getRole().equals("admin")) {
                    editThread(selected);
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Nu poți edita decât thread-urile tale!",
                            "Eroare", JOptionPane.ERROR_MESSAGE);
                }
            }
        });

        JMenuItem deleteItem = new JMenuItem("🗑️ Șterge");
        styleMenuItem(deleteItem);
        deleteItem.addActionListener(e -> {
            ForumThread selected = threadJList.getSelectedValue();
            if (selected != null && currentUser != null) {
                if (selected.getUserId() == currentUser.getUserId() || currentUser.getRole().equals("admin")) {
                    deleteThread(selected);
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Nu ai permisiunea să ștergi acest thread!",
                            "Eroare", JOptionPane.ERROR_MESSAGE);
                }
            }
        });

        threadContextMenu.add(viewItem);
        threadContextMenu.addSeparator();
        threadContextMenu.add(editItem);
        threadContextMenu.add(deleteItem);

        // Add mouse listener for right-click
        threadJList.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (SwingUtilities.isRightMouseButton(e)) {
                    int index = threadJList.locationToIndex(e.getPoint());
                    if (index != -1) {
                        threadJList.setSelectedIndex(index);
                        threadContextMenu.show(threadJList, e.getX(), e.getY());
                    }
                }
            }
        });
    }

    private JButton createFilterButton(String text, boolean active) {
        JButton button = new JButton(text);
        button.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        button.setBackground(active ? ACCENT_COLOR : CARD_BG);
        button.setForeground(active ? Color.WHITE : Color.GRAY);
        button.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(active ? ACCENT_COLOR : BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(3, 8, 3, 8)
        ));
        button.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        button.setFocusPainted(false);

        button.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                if (!active) {
                    button.setBackground(HOVER_COLOR);
                }
            }

            @Override
            public void mouseExited(MouseEvent e) {
                if (!active) {
                    button.setBackground(CARD_BG);
                }
            }
        });

        return button;
    }

    class ThreadListRenderer extends DefaultListCellRenderer {
        @Override
        public Component getListCellRendererComponent(JList<?> list, Object value,
                                                      int index, boolean isSelected, boolean cellHasFocus) {
            super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);

            setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createMatteBorder(0, 0, 1, 0, BORDER_COLOR),
                    BorderFactory.createEmptyBorder(12, 15, 12, 15)
            ));

            if (isSelected) {
                setBackground(new Color(ACCENT_COLOR.getRed(), ACCENT_COLOR.getGreen(), ACCENT_COLOR.getBlue(), 80));
                setForeground(TEXT_COLOR);
            } else {
                setBackground(index % 2 == 0 ? new Color(30, 35, 45) : new Color(25, 30, 40));
                setForeground(TEXT_COLOR);
            }

            if (value instanceof ForumThread) {
                ForumThread thread = (ForumThread) value;
                String pinIcon = thread.isPinned() ? "📌 " : "";
                String lockIcon = thread.isLocked() ? "🔒 " : "";
                String viewIcon = "👁️ " + thread.getViewCount();
                String commentIcon = "💬 " + thread.getCommentCount();
                String voteIcon = "⭐ " + thread.getVoteScore();

                // Highlight user's own threads
                String userIndicator = "";
                if (currentUser != null && thread.getUserId() == currentUser.getUserId()) {
                    userIndicator = "<span style='color: #4CAF50; font-size: 10px;'>• Meu</span> ";
                }

                setText("<html><div style='width: 250px;'>"
                        + "<div style='display: flex; justify-content: space-between; align-items: center;'>"
                        + "<b style='font-size: 13px; color: " + (thread.isPinned() ? "#FFD700" : "#ffffff") + ";'>"
                        + pinIcon + lockIcon + thread.getTitle() + "</b>"
                        + userIndicator
                        + "</div>"
                        + "<div style='font-size: 11px; color: #95a5a6; margin-top: 5px;'>"
                        + "👤 " + thread.getUsername()
                        + "</div>"
                        + "<div style='font-size: 10px; color: #7f8c8d; margin-top: 3px; display: flex; justify-content: space-between;'>"
                        + "<span>" + viewIcon + "</span>"
                        + "<span>" + commentIcon + "</span>"
                        + "<span>" + voteIcon + "</span>"
                        + "</div>"
                        + "</div></html>");
            }

            return this;
        }
    }

    private JPanel createContentPanel() {
        contentPanel = new JPanel(new BorderLayout());
        contentPanel.setBackground(DARK_BG);
        contentPanel.setBorder(BorderFactory.createEmptyBorder(10, 5, 10, 10));

        // Welcome screen
        JPanel welcomePanel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                Graphics2D g2d = (Graphics2D) g;
                Color color1 = new Color(18, 22, 30);
                Color color2 = new Color(30, 35, 45);
                GradientPaint gp = new GradientPaint(0, 0, color1, getWidth(), getHeight(), color2);
                g2d.setPaint(gp);
                g2d.fillRect(0, 0, getWidth(), getHeight());

                g2d.setColor(new Color(255, 255, 255, 5));
                for (int i = 0; i < getWidth(); i += 40) {
                    for (int j = 0; j < getHeight(); j += 40) {
                        g2d.fillOval(i, j, 2, 2);
                    }
                }
            }
        };
        welcomePanel.setLayout(new GridBagLayout());

        JPanel welcomeCard = new JPanel(new GridBagLayout());
        welcomeCard.setBackground(new Color(30, 35, 45, 200));
        welcomeCard.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ACCENT_COLOR, 2),
                BorderFactory.createEmptyBorder(40, 40, 40, 40)
        ));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridx = 0; gbc.gridy = 0;
        gbc.insets = new Insets(10, 10, 10, 10);

        JLabel welcomeIcon = new JLabel("💬");
        welcomeIcon.setFont(new Font("Segoe UI Emoji", Font.PLAIN, 64));
        welcomeIcon.setForeground(ACCENT_COLOR);
        welcomeCard.add(welcomeIcon, gbc);

        gbc.gridy++;
        JLabel welcomeTitle = new JLabel("Bine ai venit în Forum UTM!");
        welcomeTitle.setFont(new Font("Segoe UI", Font.BOLD, 28));
        welcomeTitle.setForeground(TEXT_COLOR);
        welcomeCard.add(welcomeTitle, gbc);

        gbc.gridy++;
        JLabel welcomeText = new JLabel(
                "<html><div style='text-align: center; width: 400px;'>"
                        + "<p style='color: #95a5a6; font-size: 16px; margin-top: 10px;'>"
                        + "Selectează un thread din lista din stânga pentru a-l vizualiza,<br>"
                        + "sau creează un thread nou folosind butonul <b>\"Thread nou\"</b>."
                        + "</p>"
                        + "</div></html>"
        );
        welcomeCard.add(welcomeText, gbc);

        gbc.gridy++;
        JLabel tipsLabel = new JLabel(
                "<html><div style='text-align: center; width: 400px; margin-top: 30px;'>"
                        + "<h4 style='color: #7f8c8d;'>💡 Sfaturi:</h4>"
                        + "<ul style='text-align: left; color: #95a5a6; font-size: 14px;'>"
                        + "<li>Folosește Ctrl+Enter pentru a posta comentarii rapid</li>"
                        + "<li>Poți răspunde direct la comentarii folosind butonul 'Răspunde'</li>"
                        + "<li>Thread-urile tale sunt marcate cu punct verde</li>"
                        + "<li>Utilizatorii online sunt afișați în panoul din dreapta</li>"
                        + "</ul>"
                        + "</div></html>"
        );
        welcomeCard.add(tipsLabel, gbc);

        welcomePanel.add(welcomeCard);
        contentPanel.add(welcomePanel, BorderLayout.CENTER);

        return contentPanel;
    }

    // ==================== DIALOGURI INTEGRATE ====================

    private void showNewThreadDialog() {
        if (currentUser == null) {
            JOptionPane.showMessageDialog(this,
                    "Trebuie să fii autentificat pentru a crea thread-uri!",
                    "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        NewThreadDialog dialog = new NewThreadDialog(this, tagList, currentUser.getUserId());
        dialog.setVisible(true);

        if (dialog.isSuccess()) {
            String title = dialog.getTitle();
            String content = dialog.getContent();
            int tagId = dialog.getTagId();

            String tagsStr = tagId > 0 ? String.valueOf(tagId) : "";
            sendRequest("CREATE_THREAD:" + currentUser.getUserId() + ":" +
                    title + ":" + content + ":" + tagsStr);

            JOptionPane.showMessageDialog(this,
                    "Thread-ul a fost creat! Va apărea în listă după reîmprospătare.",
                    "Succes", JOptionPane.INFORMATION_MESSAGE);

            // Refresh thread list
            loadThreads();
        }
    }

    private void showProfileDialog() {
        if (currentUser == null) {
            JOptionPane.showMessageDialog(this,
                    "Trebuie să fii autentificat pentru a vedea profilul!",
                    "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        ProfileDialog dialog = new ProfileDialog(this, currentUser);
        dialog.setVisible(true);
    }

    private void showSettingsDialog() {
        SettingsDialog dialog = new SettingsDialog(this);
        dialog.setVisible(true);

        // Aici poți adăuga logica pentru salvarea setărilor
        // De exemplu, salvezi într-un fișier de configurare
    }

    private void showStatisticsDialog() {
        if (currentUser == null) {
            JOptionPane.showMessageDialog(this,
                    "Trebuie să fii autentificat pentru a vedea statisticile!",
                    "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        StatisticsDialog dialog = new StatisticsDialog(this, currentUser);
        dialog.setVisible(true);
    }

    private void showAboutDialog() {
        JOptionPane.showMessageDialog(this,
                "<html><div style='width: 300px;'>"
                        + "<h2>Forum UTM v2.0</h2>"
                        + "<p><b>Autor:</b> Buga Pavel - CR-231</p>"
                        + "<p><b>Universitatea Tehnică a Moldovei</b></p>"
                        + "<p>Facultatea Calculatoare, Informatică și Microelectronică</p>"
                        + "<hr>"
                        + "<p>Aplicație Client-Server pentru discuții pe forum</p>"
                        + "<p>© 2024 Toate drepturile rezervate</p>"
                        + "</div></html>",
                "Despre aplicație",
                JOptionPane.INFORMATION_MESSAGE);
    }

    private void showTagManager() {
        if (currentUser == null) {
            JOptionPane.showMessageDialog(this,
                    "Trebuie să fii autentificat pentru a gestiona tag-urile!",
                    "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        // Dialog simplu pentru tag-uri
        JDialog dialog = new JDialog(this, "Manager Tag-uri", true);
        dialog.setSize(400, 300);
        dialog.setLocationRelativeTo(this);
        dialog.getContentPane().setBackground(DARK_BG);

        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setBackground(DARK_BG);
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        JLabel title = new JLabel("🏷️ Tag-uri disponibile");
        title.setFont(new Font("Segoe UI", Font.BOLD, 18));
        title.setForeground(TEXT_COLOR);
        title.setHorizontalAlignment(SwingConstants.CENTER);

        DefaultListModel<String> tagModel = new DefaultListModel<>();
        for (Tag tag : tagList) {
            tagModel.addElement(tag.getName() + " - " + tag.getDescription());
        }

        JList<String> tagListDisplay = new JList<>(tagModel);
        tagListDisplay.setBackground(CARD_BG);
        tagListDisplay.setForeground(TEXT_COLOR);
        tagListDisplay.setFont(new Font("Segoe UI", Font.PLAIN, 13));

        JScrollPane scrollPane = new JScrollPane(tagListDisplay);
        scrollPane.setBorder(BorderFactory.createLineBorder(BORDER_COLOR, 1));

        JButton closeButton = createModernButton("Închide", ACCENT_COLOR);
        closeButton.addActionListener(e -> dialog.dispose());

        panel.add(title, BorderLayout.NORTH);
        panel.add(scrollPane, BorderLayout.CENTER);
        panel.add(closeButton, BorderLayout.SOUTH);

        dialog.add(panel);
        dialog.setVisible(true);
    }

    private void editThread(ForumThread thread) {
        if (currentUser == null) {
            JOptionPane.showMessageDialog(this,
                    "Trebuie să fii autentificat pentru a edita thread-uri!",
                    "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        if (thread.getUserId() != currentUser.getUserId() && !currentUser.getRole().equals("admin")) {
            JOptionPane.showMessageDialog(this,
                    "Nu poți edita decât thread-urile tale!",
                    "Eroare", JOptionPane.ERROR_MESSAGE);
            return;
        }

        EditThreadDialog dialog = new EditThreadDialog(this, thread);
        dialog.setVisible(true);

        if (dialog.isUpdated()) {
            String newTitle = dialog.getUpdatedTitle();
            String newContent = dialog.getUpdatedContent();

            // Obține tag-urile curente
            List<Integer> tagIds = new ArrayList<>();
            if (!tagList.isEmpty()) {
                // Pentru simplitate, folosim primul tag
                tagIds.add(tagList.get(0).getTagId());
            }

            String tagsStr = "";
            for (int tagId : tagIds) {
                tagsStr += tagId + ",";
            }
            if (!tagsStr.isEmpty()) {
                tagsStr = tagsStr.substring(0, tagsStr.length() - 1);
            }

            sendRequest("EDIT_THREAD:" + thread.getThreadId() + ":" +
                    currentUser.getUserId() + ":" + newTitle + ":" +
                    newContent + ":" + tagsStr);

            JOptionPane.showMessageDialog(this,
                    "Thread-ul a fost actualizat cu succes!",
                    "Succes", JOptionPane.INFORMATION_MESSAGE);

            // Refresh thread details
            if (currentThread != null && currentThread.getThreadId() == thread.getThreadId()) {
                loadThreadDetails(thread.getThreadId());
            }
            loadThreads();
        }
    }

    private void deleteThread(ForumThread thread) {
        if (currentUser == null) {
            JOptionPane.showMessageDialog(this,
                    "Trebuie să fii autentificat pentru a șterge thread-uri!",
                    "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        if (thread.getUserId() != currentUser.getUserId() && !currentUser.getRole().equals("admin")) {
            JOptionPane.showMessageDialog(this,
                    "Nu ai permisiunea să ștergi acest thread!",
                    "Eroare", JOptionPane.ERROR_MESSAGE);
            return;
        }

        int confirm = JOptionPane.showConfirmDialog(this,
                "<html><div style='width: 300px;'>"
                        + "<b>Ștergere thread</b><br><br>"
                        + "Sigur dorești să ștergi thread-ul:<br>"
                        + "<b>\"" + thread.getTitle() + "\"</b>?<br><br>"
                        + "Această acțiune este ireversibilă și va șterge toate comentariile asociate."
                        + "</div></html>",
                "Confirmare ștergere",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            sendRequest("DELETE_THREAD:" + thread.getThreadId() + ":" + currentUser.getUserId());

            JOptionPane.showMessageDialog(this,
                    "Thread-ul a fost șters cu succes!",
                    "Succes", JOptionPane.INFORMATION_MESSAGE);

            // Clear current thread if it was deleted
            if (currentThread != null && currentThread.getThreadId() == thread.getThreadId()) {
                currentThread = null;
                contentPanel.removeAll();
                contentPanel.add(createWelcomePanel(), BorderLayout.CENTER);
                contentPanel.revalidate();
                contentPanel.repaint();
            }

            loadThreads();
        }
    }

    private JPanel createWelcomePanel() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBackground(DARK_BG);

        JLabel welcomeLabel = new JLabel(
                "<html><div style='text-align: center;'>"
                        + "<h1 style='color: #ffffff; font-size: 32px;'>👋 Bine ai venit!</h1>"
                        + "<p style='color: #95a5a6; font-size: 16px; margin-top: 10px;'>"
                        + "Selectează un thread din lista din stânga pentru a-l vizualiza."
                        + "</p>"
                        + "</div></html>",
                SwingConstants.CENTER
        );
        panel.add(welcomeLabel);

        return panel;
    }

    // ==================== METODE DE NETWORKING ====================

    private void connectToServer() {
        updateConnectionStatus("⏳ Conectare la server...", Color.ORANGE);

        new Thread(() -> {
            int attempts = 0;
            final int maxAttempts = 3;

            while (attempts < maxAttempts && !isConnected) {
                attempts++;
                try {
                    socket = new Socket("localhost", 12345);
                    objectOut = new ObjectOutputStream(socket.getOutputStream());
                    objectOut.flush();
                    objectIn = new ObjectInputStream(socket.getInputStream());

                    isConnected = true;
                    SwingUtilities.invokeLater(() -> {
                        updateConnectionStatus("✅ Conectat la server", SUCCESS_COLOR);
                    });
                    System.out.println("✅ Conectat la server");

                    startMessageListener();
                    startHeartbeat();
                    break;

                } catch (IOException e) {
                    System.err.println("❌ Eroare conexiune (încercarea " + attempts + "/" + maxAttempts + "): " + e.getMessage());

                    if (attempts < maxAttempts) {
                        int finalAttempts = attempts;
                        SwingUtilities.invokeLater(() -> {
                            updateConnectionStatus("🔄 Reîncercare " + finalAttempts + "/" + maxAttempts + "...", Color.ORANGE);
                        });

                        try {
                            Thread.sleep(2000);
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                        }
                    } else {
                        SwingUtilities.invokeLater(() -> {
                            updateConnectionStatus("❌ Conexiune eșuată", DANGER_COLOR);
                            int option = JOptionPane.showOptionDialog(this,
                                    "Nu mă pot conecta la server. Dorești să reîncerci?",
                                    "Eroare conexiune",
                                    JOptionPane.YES_NO_OPTION,
                                    JOptionPane.ERROR_MESSAGE,
                                    null,
                                    new String[]{"Reîncearcă", "Continuă offline"},
                                    "Reîncearcă");

                            if (option == JOptionPane.YES_OPTION) {
                                reconnectToServer();
                            }
                        });
                    }
                }
            }
        }).start();
    }

    private void updateConnectionStatus(String message, Color color) {
        if (connectionStatusLabel != null) {
            connectionStatusLabel.setText(message);
            connectionStatusLabel.setForeground(color);
        }
    }

    private void reconnectToServer() {
        cleanDisconnect();
        isConnected = false;

        SwingUtilities.invokeLater(() -> {
            if (currentUser != null) {
                logout();
            }
            connectToServer();
        });
    }

    private void login() {
        String username = authUsernameField.getText().trim();
        String password = new String(authPasswordField.getPassword()).trim();

        if (username.isEmpty() || password.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Completează username și parola!", "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        sendRequest("LOGIN:" + username + ":" + password);
        authPasswordField.setText("");
    }

    private void register(String username, String password, String email, String fullName) {
        if (username.isEmpty() || password.isEmpty() || email.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Completează toate câmpurile obligatorii!", "Atenție", JOptionPane.WARNING_MESSAGE);
            return;
        }

        sendRequest("REGISTER:" + username + ":" + password + ":" + email + ":" +
                (fullName.isEmpty() ? username : fullName));
    }

    private void logout() {
        int confirm = JOptionPane.showConfirmDialog(this,
                "<html><div style='width: 250px;'>"
                        + "<b>Sigur dorești să te deconectezi?</b><br><br>"
                        + "Toate mesajele nesalvate se vor pierde."
                        + "</div></html>",
                "Confirmare deconectare",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.QUESTION_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            sendRequest("LOGOUT");

            stopAllTimers();
            cleanDisconnect();

            SwingUtilities.invokeLater(() -> {
                mainCardLayout.show(mainPanel, "AUTH");
                currentUser = null;
                sessionId = null;
                userInfoLabel.setText(" | Neautentificat");
                updateConnectionStatus("🔌 Deconectat", Color.GRAY);

                threadListModel.clear();
                if (activeUsersModel != null) activeUsersModel.clear();
                if (threadCountLabel != null) threadCountLabel.setText("0 thread-uri");

                contentPanel.removeAll();
                contentPanel.add(createWelcomePanel(), BorderLayout.CENTER);
                contentPanel.revalidate();
                contentPanel.repaint();
            });
        }
    }

    private void stopAllTimers() {
        if (heartbeatTimer != null) {
            heartbeatTimer.stop();
            heartbeatTimer = null;
        }
        if (refreshTimer != null) {
            refreshTimer.stop();
            refreshTimer = null;
        }
        if (commentsReloadTimer != null) {
            commentsReloadTimer.stop();
            commentsReloadTimer = null;
        }
    }

    private void logoutAndExit() {
        if (currentUser != null) {
            int confirm = JOptionPane.showConfirmDialog(this,
                    "<html><div style='width: 300px;'>"
                            + "<b>Sigur dorești să închizi aplicația?</b><br><br>"
                            + "Toate modificările nesalvate se vor pierde.<br>"
                            + "Veți fi deconectat automat."
                            + "</div></html>",
                    "Confirmare închidere",
                    JOptionPane.YES_NO_OPTION,
                    JOptionPane.WARNING_MESSAGE);

            if (confirm == JOptionPane.YES_OPTION) {
                sendRequest("LOGOUT");
                cleanDisconnect();
                System.exit(0);
            }
        } else {
            cleanDisconnect();
            System.exit(0);
        }
    }

    private void cleanDisconnect() {
        isConnected = false;
        stopAllTimers();

        try {
            if (objectOut != null) {
                try {
                    objectOut.close();
                } catch (IOException e) {
                    // Ignore
                }
                objectOut = null;
            }
            if (objectIn != null) {
                try {
                    objectIn.close();
                } catch (IOException e) {
                    // Ignore
                }
                objectIn = null;
            }
            if (socket != null && !socket.isClosed()) {
                try {
                    socket.close();
                } catch (IOException e) {
                    // Ignore
                }
                socket = null;
            }
        } catch (Exception e) {
            System.err.println("❌ Eroare deconectare: " + e.getMessage());
        }
    }

    // Metode pentru încărcarea datelor
    private void loadThreads() {
        if (currentUser == null) return;
        sendRequest("GET_THREADS");
    }

    private void loadThreadDetails(int threadId) {
        if (currentUser == null) return;
        sendRequest("GET_THREAD:" + threadId);
    }

    private void loadComments(int threadId) {
        if (currentUser == null) return;
        pendingCommentsRequest = true;
        commentsRequestAt = System.currentTimeMillis();
        sendRequest("GET_COMMENTS:" + threadId);
    }

    private void refreshActiveUsers() {
        if (currentUser == null) return;
        sendRequest("GET_ACTIVE_USERS:" + (currentThread != null ? currentThread.getThreadId() : "null"));
    }

    private void filterPinnedThreads() {
        DefaultListModel<ForumThread> filteredModel = new DefaultListModel<>();
        for (int i = 0; i < threadListModel.size(); i++) {
            ForumThread thread = threadListModel.getElementAt(i);
            if (thread.isPinned()) {
                filteredModel.addElement(thread);
            }
        }
        threadJList.setModel(filteredModel);
        threadCountLabel.setText(filteredModel.size() + " thread-uri fixate");
    }

    private void filterMyThreads() {
        if (currentUser == null) return;

        DefaultListModel<ForumThread> filteredModel = new DefaultListModel<>();
        for (int i = 0; i < threadListModel.size(); i++) {
            ForumThread thread = threadListModel.getElementAt(i);
            if (thread.getUserId() == currentUser.getUserId()) {
                filteredModel.addElement(thread);
            }
        }
        threadJList.setModel(filteredModel);
        threadCountLabel.setText(filteredModel.size() + " thread-uri personale");
    }

    private void searchThreads(String query) {
        if (query == null || query.trim().isEmpty() || query.equals("🔍 Caută thread-uri...")) {
            threadJList.setModel(threadListModel);
            threadCountLabel.setText(threadListModel.size() + " thread-uri");
            return;
        }

        DefaultListModel<ForumThread> filteredModel = new DefaultListModel<>();
        String searchLower = query.toLowerCase();

        for (int i = 0; i < threadListModel.size(); i++) {
            ForumThread thread = threadListModel.getElementAt(i);
            if (thread.getTitle().toLowerCase().contains(searchLower) ||
                    thread.getContent().toLowerCase().contains(searchLower) ||
                    thread.getUsername().toLowerCase().contains(searchLower)) {
                filteredModel.addElement(thread);
            }
        }

        threadJList.setModel(filteredModel);
        threadCountLabel.setText(filteredModel.size() + " thread-uri găsite");
    }

    // METODE NOI INTEGRATE
    private void displayThread(ForumThread thread) {
        contentPanel.removeAll();

        ThreadViewPanel threadViewPanel = new ThreadViewPanel(
                thread,
                currentUser,
                commentList,
                activeUsers,
                new ThreadViewPanel.ThreadActionListener() {
                    @Override
                    public void onVoteThread(int threadId, String voteType) {
                        voteThread(threadId, voteType);
                    }

                    @Override
                    public void onAddComment(String content, Integer parentCommentId) {
                        if (currentUser != null && currentThread != null) {
                            if (parentCommentId != null) {
                                sendRequest("ADD_COMMENT:" + currentThread.getThreadId() + ":" +
                                        currentUser.getUserId() + ":" + content + ":" + parentCommentId);
                            } else {
                                sendRequest("ADD_COMMENT:" + currentThread.getThreadId() + ":" +
                                        currentUser.getUserId() + ":" + content);
                            }
                        }
                    }

                    @Override
                    public void onVoteComment(int commentId, String voteType) {
                        voteComment(commentId, voteType);
                    }

                    @Override
                    public void onReplyToComment(Comment comment) {
                        setReplyTo(comment);
                    }

                    @Override
                    public void onRefresh() {
                        if (currentThread != null) {
                            loadThreadDetails(currentThread.getThreadId());
                        }
                    }
                }
        );

        this.currentThreadViewPanel = threadViewPanel;

        JScrollPane scrollPane = new JScrollPane(threadViewPanel);
        scrollPane.setBorder(BorderFactory.createLineBorder(BORDER_COLOR, 1));
        scrollPane.getViewport().setBackground(DARK_BG);
        scrollPane.getVerticalScrollBar().setUnitIncrement(16);

        contentPanel.add(scrollPane, BorderLayout.CENTER);
        contentPanel.revalidate();
        contentPanel.repaint();

        if (sessionId != null && currentUser != null) {
            sendRequest("UPDATE_ACTIVITY:" + sessionId + ":" + currentUser.getUserId() + ":" + thread.getThreadId());
        }
        startCommentsAutoReload();
    }

    private void setReplyTo(Comment comment) {
        if (comment != null) {
            currentReplyTo = comment;
            JOptionPane.showMessageDialog(this,
                    "Acum răspunzi la comentariul lui: " + comment.getUsername() +
                            "\n\n" + comment.getContent().substring(0, Math.min(100, comment.getContent().length())) + "...",
                    "Mod Răspuns",
                    JOptionPane.INFORMATION_MESSAGE);
        }
    }

    private void voteThread(int threadId, String voteType) {
        if (currentUser == null) return;
        sendRequest("VOTE:" + currentUser.getUserId() + ":" + threadId + ":null:" + voteType);
    }

    private void voteComment(int commentId, String voteType) {
        if (currentUser == null) return;
        sendRequest("VOTE:" + currentUser.getUserId() + ":null:" + commentId + ":" + voteType);
    }

    private void sendRequest(String request) {
        if (isConnected && objectOut != null && socket != null && socket.isConnected()) {
            try {
                objectOut.writeObject(request);
                objectOut.flush();
                System.out.println("📤 Client trimite: " + request);
            } catch (IOException e) {
                System.err.println("❌ Eroare trimitere request: " + e.getMessage());
                if (e.getMessage().contains("Socket closed") || e.getMessage().contains("Connection reset")) {
                    isConnected = false;
                    reconnectToServer();
                }
            }
        }
    }

    private void startMessageListener() {
        new Thread(() -> {
            try {
                while (isConnected && socket != null && !socket.isClosed()) {
                    Object obj = objectIn.readObject();
                    handleServerMessage(obj);
                }
            } catch (EOFException e) {
                System.out.println("📴 Conexiune închisă de server");
            } catch (IOException e) {
                if (isConnected) {
                    System.err.println("❌ Eroare citire mesaje: " + e.getMessage());
                    SwingUtilities.invokeLater(() -> {
                        if (!e.getMessage().contains("Socket closed")) {
                            JOptionPane.showMessageDialog(this,
                                    "Conexiunea cu serverul a fost pierdută.",
                                    "Eroare conexiune", JOptionPane.ERROR_MESSAGE);
                        }
                    });
                }
            } catch (ClassNotFoundException e) {
                System.err.println("❌ Eroare clasă necunoscută: " + e.getMessage());
            }
        }).start();
    }

    private void startHeartbeat() {
        if (heartbeatTimer != null) {
            heartbeatTimer.stop();
        }

        heartbeatTimer = new Timer(30000, e -> {
            if (isConnected && currentUser != null && sessionId != null) {
                sendRequest("HEARTBEAT:" + sessionId + ":" +
                        currentUser.getUserId() + ":" +
                        (currentThread != null ? currentThread.getThreadId() : "null"));
            }
        });
        heartbeatTimer.start();
    }

    private void startPeriodicRefresh() {
        if (refreshTimer != null) {
            refreshTimer.stop();
        }

        refreshTimer = new Timer(30000, e -> {
            if (isConnected && currentUser != null) {
                loadThreads();
                refreshActiveUsers();
            }
        });
        refreshTimer.start();
    }

    private void startCommentsAutoReload() {
        if (commentsReloadTimer != null) {
            commentsReloadTimer.stop();
        }

        commentsReloadTimer = new Timer(7000, e -> {
            if (isConnected && currentUser != null) {
                if (currentThread != null) {
                    loadComments(currentThread.getThreadId());
                }
                refreshActiveUsers();
            }
        });
        commentsReloadTimer.start();
    }

    // Handler pentru mesaje de la server
    private void handleServerMessage(Object message) {
        SwingUtilities.invokeLater(() -> {
            if (message instanceof String) {
                String msg = (String) message;

                if (msg.startsWith("SUCCESS:")) {
                    if (msg.startsWith("SUCCESS:Autentificare")) {
                        mainCardLayout.show(mainPanel, "MAIN");
                        startPeriodicRefresh();
                        startCommentsAutoReload();
                        loadThreads();
                        refreshActiveUsers();
                    } else if (msg.contains("Comentariu adăugat")) {
                        if (currentThread != null) {
                            loadComments(currentThread.getThreadId());
                        }
                        refreshActiveUsers();
                        loadThreads();
                    } else if (msg.contains("Thread creat")) {
                        loadThreads();
                    } else if (msg.contains("Thread actualizat") || msg.contains("Thread șters")) {
                        loadThreads();
                    }
                } else if (msg.startsWith("ERROR:")) {
                    String details = msg.substring("ERROR:".length());
                    JOptionPane.showMessageDialog(this, details, "Eroare", JOptionPane.ERROR_MESSAGE);
                } else if (msg.equals("REFRESH_THREADS")) {
                    loadThreads();
                } else if (msg.equals("HEARTBEAT_OK")) {
                    // Do nothing
                } else if (msg.equals("COMMENTS_UPDATE")) {
                    expectingCommentsList = true;
                } else if (msg.equals("THREAD_UPDATE")) {
                    expectingThreadUpdate = true;
                } else if (msg.equals("ACTIVE_USERS_UPDATE")) {
                    expectingActiveUsersUpdate = true;
                } else if (msg.startsWith("SESSION:")) {
                    sessionId = msg.substring("SESSION:".length());
                    startHeartbeat();
                } else {
                    System.out.println("📥 Server: " + msg);
                }
            }
            else if (message instanceof List) {
                List<?> list = (List<?>) message;

                if (expectingCommentsList || pendingCommentsRequest) {
                    expectingCommentsList = false;
                    pendingCommentsRequest = false;
                    if (list.isEmpty() || list.get(0) instanceof Comment) {
                        commentList = (List<Comment>) list;
                        System.out.println("✅ [COMMENTS] Încărcat " + commentList.size() + " comentarii");
                        updateCommentsDisplay();
                        return;
                    }
                }

                if (expectingThreadUpdate) {
                    expectingThreadUpdate = false;
                    return;
                }

                if (expectingActiveUsersUpdate) {
                    expectingActiveUsersUpdate = false;
                    if (!list.isEmpty() && list.get(0) instanceof ActiveUser) {
                        activeUsers = (List<ActiveUser>) list;
                        System.out.println("✅ Încărcat " + activeUsers.size() + " utilizatori activi");
                        updateOnlineUsersPanel();
                        if (currentThreadViewPanel != null) {
                            currentThreadViewPanel.updateOnlineUsers(activeUsers);
                        }
                        return;
                    }
                }

                if (!list.isEmpty()) {
                    Object first = list.get(0);

                    if (first instanceof ForumThread) {
                        threadList = (List<ForumThread>) list;
                        threadListModel.clear();
                        for (ForumThread thread : threadList) {
                            threadListModel.addElement(thread);
                        }
                        System.out.println("✅ Încărcat " + threadList.size() + " thread-uri");

                        if (threadCountLabel != null) {
                            threadCountLabel.setText(threadList.size() + " thread-uri");
                        }
                    } else if (first instanceof ActiveUser) {
                        activeUsers = (List<ActiveUser>) list;
                        System.out.println("✅ Încărcat " + activeUsers.size() + " utilizatori activi");
                        updateOnlineUsersPanel();
                    } else if (first instanceof Tag) {
                        tagList = (List<Tag>) list;
                        System.out.println("✅ Încărcat " + tagList.size() + " tag-uri");
                    } else if (first instanceof Comment) {
                        commentList = (List<Comment>) list;
                        System.out.println("✅ Încărcat " + commentList.size() + " comentarii");
                        updateCommentsDisplay();
                    }
                } else {
                    if (commentsRequestAt > 0 && System.currentTimeMillis() - commentsRequestAt < 3000) {
                        commentList = Collections.emptyList();
                        System.out.println("✅ [COMMENTS] Listă goală primită (fallback)");
                        updateCommentsDisplay();
                    }
                }
            }
            else if (message instanceof User) {
                currentUser = (User) message;
                userInfoLabel.setText(" | Autentificat ca: " + currentUser.getUsername());

                if (sessionId == null) {
                    // nimic de făcut aici, heartbeat pornește după ce avem sessionId
                }

                mainCardLayout.show(mainPanel, "MAIN");
                startPeriodicRefresh();
                loadThreads();
                refreshActiveUsers();
            }
            else if (message instanceof ForumThread) {
                currentThread = (ForumThread) message;
                displayThread(currentThread);
                loadComments(currentThread.getThreadId());
                refreshActiveUsers();
            }
            else {
                System.out.println("📥 Server trimite obiect de tip: " + message.getClass().getName());
            }
        });
    }

    private void updateOnlineUsersPanel() {
        if (activeUsersList != null && onlineCountLabel != null) {
            activeUsersModel.clear();
            for (ActiveUser user : activeUsers) {
                activeUsersModel.addElement(user);
            }
            onlineCountLabel.setText(String.valueOf(activeUsers.size()));
        }
    }

    private void updateCommentsDisplay() {
        if (currentThreadViewPanel != null) {
            currentThreadViewPanel.updateComments(commentList);
        }
        if (commentsCountLabel != null) {
            commentsCountLabel.setText((commentList != null ? commentList.size() : 0) + " comentarii");
        }
    }

    // ==================== METODE UTILITARE ====================

    private JButton createModernButton(String text, Color bgColor) {
        JButton button = new JButton(text);
        button.setBackground(bgColor);
        button.setForeground(Color.WHITE);
        button.setFont(new Font("Segoe UI", Font.BOLD, 13));
        button.setFocusPainted(false);
        button.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(bgColor.darker(), 1),
                BorderFactory.createEmptyBorder(10, 20, 10, 20)
        ));
        button.setCursor(new Cursor(Cursor.HAND_CURSOR));

        button.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(bgColor.darker(), 1),
                BorderFactory.createEmptyBorder(10, 20, 10, 20)
        ));

        button.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                button.setBackground(bgColor.brighter());
                button.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(bgColor.brighter().darker(), 1),
                        BorderFactory.createEmptyBorder(10, 20, 10, 20)
                ));
            }

            @Override
            public void mouseExited(MouseEvent e) {
                button.setBackground(bgColor);
                button.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(bgColor.darker(), 1),
                        BorderFactory.createEmptyBorder(10, 20, 10, 20)
                ));
            }

            @Override
            public void mousePressed(MouseEvent e) {
                button.setBackground(bgColor.darker());
            }
        });

        return button;
    }

    private JButton createIconButton(String icon, String tooltip) {
        JButton button = new JButton(icon);
        button.setFont(new Font("Segoe UI Emoji", Font.PLAIN, 18));
        button.setBackground(CARD_BG);
        button.setForeground(TEXT_COLOR);
        button.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
        button.setCursor(new Cursor(Cursor.HAND_CURSOR));
        button.setToolTipText(tooltip);

        button.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                button.setBackground(HOVER_COLOR);
            }

            @Override
            public void mouseExited(MouseEvent e) {
                button.setBackground(CARD_BG);
            }
        });

        return button;
    }

    private void styleTextField(JTextField field) {
        field.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        field.setBackground(INPUT_BG);
        field.setForeground(TEXT_COLOR);
        field.setCaretColor(TEXT_COLOR);
        field.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_COLOR, 1),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));
    }
}