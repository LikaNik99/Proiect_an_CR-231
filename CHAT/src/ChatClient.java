import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;

import javax.imageio.ImageIO;
import javax.sound.sampled.*;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import javax.swing.filechooser.FileNameExtensionFilter;
import javax.swing.text.JTextComponent;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Base64;

public class ChatClient extends JFrame {

    // ====== CONFIG ======
    private static final DateTimeFormatter TS_FMT =
            DateTimeFormatter.ofPattern("HH:mm:ss").withZone(ZoneId.systemDefault());

    private static final int MAX_IMAGE_BYTES = 800_000;
    private static final int MAX_AUDIO_BYTES = 700_000; // WAV
    private static final int MAX_RECORD_MS = 15_000;     // 15 sec

    private final Theme theme = Theme.vibrant();

    // ====== UI ======
    private JPanel messagesPanel;
    private JScrollPane messagesScroll;
    private PromptTextField inputField;

    private GradientButton sendButton;
    private GradientButton imgButton;
    private GradientButton voiceButton;

    private DefaultListModel<String> userListModel;
    private JList<String> userList;

    private JLabel statusPill;
    private JLabel toastLabel;
    private Timer toastTimer;

    // ====== WS ======
    private WebSocketClient socket;
    private final String serverUri;

    private String username;
    private String password;
    private String mode; // LOGIN / REGISTER
    private boolean authed = false;

    // ===== Voice recording/playback =====
    private volatile boolean recording = false;
    private volatile String recordingTo = "";
    private Thread recordThread;
    private Timer recordPulseTimer;
    private boolean pulseOn = false;

    private volatile Clip playingClip;

    public ChatClient(String serverUri) {
        this.serverUri = serverUri;

        setTitle("CHAT — Client");
        setSize(1040, 700);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);

        initLook();
        initGui();

        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                stopRecordingIfAny(false);
                stopPlaying();
                try { if (socket != null) socket.close(); } catch (Exception ignored) {}
                dispose();
                System.exit(0);
            }
        });

        if (!showAuthDialog()) {
            dispose();
            System.exit(0);
        }

        connect();
    }

    private void initLook() {
        try { UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); }
        catch (Exception ignored) {}
        UIManager.put("ToolTip.font", new Font("Segoe UI", Font.PLAIN, 12));
    }

    private void initGui() {
        JPanel root = new JPanel(new BorderLayout(14, 14));
        root.setBorder(new EmptyBorder(16, 16, 16, 16));
        root.setBackground(theme.bg);
        setContentPane(root);

        // ===== Header (gradient + toast) =====
        GradientPanel header = new GradientPanel(theme.headerGrad1, theme.headerGrad2, 18);
        header.setLayout(new BorderLayout(10, 10));
        header.setBorder(new EmptyBorder(14, 16, 12, 16));

        JPanel topRow = new JPanel(new BorderLayout(12, 12));
        topRow.setOpaque(false);

        JPanel left = new JPanel();
        left.setOpaque(false);
        left.setLayout(new BoxLayout(left, BoxLayout.Y_AXIS));

        JLabel title = new JLabel("Chat Multifuncțional");
        title.setFont(new Font("Segoe UI", Font.BOLD, 20));
        title.setForeground(Color.WHITE);

        JLabel subtitle = new JLabel("Text • Poze • Voice • PM (selectează user)");
        subtitle.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        subtitle.setForeground(new Color(255, 255, 255, 210));

        left.add(title);
        left.add(Box.createVerticalStrut(4));
        left.add(subtitle);

        JPanel right = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 0));
        right.setOpaque(false);

        statusPill = new JLabel("Deconectat");
        statusPill.setFont(new Font("Segoe UI", Font.BOLD, 12));
        statusPill.setForeground(Color.WHITE);
        statusPill.setOpaque(true);
        statusPill.setBackground(new Color(255, 255, 255, 40));
        statusPill.setBorder(new EmptyBorder(8, 12, 8, 12));

        GradientButton switchAcc = new GradientButton(null, theme.btnGradA1, theme.btnGradA2);
        switchAcc.setIconOnly(new SwapIcon(18, Color.WHITE));
        switchAcc.setSmall(true);
        switchAcc.setToolTipText("Schimbă cont (login/register)");
        switchAcc.addActionListener(e -> switchAccount());

        right.add(statusPill);
        right.add(switchAcc);

        topRow.add(left, BorderLayout.WEST);
        topRow.add(right, BorderLayout.EAST);

        toastLabel = new JLabel("");
        toastLabel.setFont(new Font("Segoe UI", Font.BOLD, 12));
        toastLabel.setForeground(Color.WHITE);
        toastLabel.setOpaque(true);
        toastLabel.setBackground(new Color(0, 0, 0, 35));
        toastLabel.setBorder(new EmptyBorder(7, 10, 7, 10));
        toastLabel.setVisible(false);

        JPanel toastWrap = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 0));
        toastWrap.setOpaque(false);
        toastWrap.add(toastLabel);

        header.add(topRow, BorderLayout.NORTH);
        header.add(toastWrap, BorderLayout.SOUTH);

        root.add(header, BorderLayout.NORTH);

        // ===== Center =====
        JPanel center = new JPanel(new BorderLayout(14, 14));
        center.setOpaque(false);

        // Messages card
        ShadowRoundedPanel msgCard = new ShadowRoundedPanel(theme.card, 18);
        msgCard.setLayout(new BorderLayout(10, 10));
        msgCard.setBorder(new EmptyBorder(12, 12, 12, 12));

        messagesPanel = new JPanel();
        messagesPanel.setLayout(new BoxLayout(messagesPanel, BoxLayout.Y_AXIS));
        messagesPanel.setBackground(theme.card);

        messagesScroll = new JScrollPane(messagesPanel);
        messagesScroll.setBorder(BorderFactory.createEmptyBorder());
        messagesScroll.getViewport().setBackground(theme.card);
        messagesScroll.getVerticalScrollBar().setUnitIncrement(16);

        msgCard.add(messagesScroll, BorderLayout.CENTER);

        // Input bar
        ShadowRoundedPanel inputBar = new ShadowRoundedPanel(theme.inputBar, 16);
        inputBar.setLayout(new BorderLayout(10, 10));
        inputBar.setBorder(new EmptyBorder(10, 10, 10, 10));

        JPanel tools = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 0));
        tools.setOpaque(false);

        imgButton = new GradientButton(null, theme.btnGradA1, theme.btnGradA2);
        imgButton.setSmall(true);
        imgButton.setIconOnly(new CameraIcon(18, Color.WHITE));
        imgButton.setToolTipText("Trimite imagine (PNG/JPG/GIF)");
        imgButton.setEnabled(false);
        imgButton.addActionListener(e -> chooseAndSendImage());

        voiceButton = new GradientButton(null, theme.btnGradA1, theme.btnGradA2);
        voiceButton.setSmall(true);
        voiceButton.setIconOnly(new MicIcon(18, Color.WHITE));
        voiceButton.setToolTipText("Înregistrează voice (max 15 sec) • click = start/stop");
        voiceButton.setEnabled(false);
        voiceButton.addActionListener(e -> toggleRecordVoice());

        tools.add(imgButton);
        tools.add(voiceButton);

        inputField = new PromptTextField("Scrie mesaj… (Enter = trimite)");
        inputField.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        inputField.setBorder(BorderFactory.createCompoundBorder(
                new RoundedBorder(theme.border, 14),
                new EmptyBorder(10, 12, 10, 12)
        ));
        inputField.setBackground(theme.inputBg);
        inputField.setForeground(theme.text);
        inputField.setCaretColor(theme.text);
        inputField.setEnabled(false);

        sendButton = new GradientButton(null, theme.btnGradB1, theme.btnGradB2);
        sendButton.setIconOnly(new SendIcon(18, Color.WHITE));
        sendButton.setToolTipText("Trimite mesaj");
        sendButton.setEnabled(false);

        inputBar.add(tools, BorderLayout.WEST);
        inputBar.add(inputField, BorderLayout.CENTER);
        inputBar.add(sendButton, BorderLayout.EAST);

        msgCard.add(inputBar, BorderLayout.SOUTH);

        // Users card
        ShadowRoundedPanel usersCard = new ShadowRoundedPanel(theme.card, 18);
        usersCard.setLayout(new BorderLayout(10, 10));
        usersCard.setBorder(new EmptyBorder(12, 12, 12, 12));

        JLabel usersTitle = new JLabel("Utilizatori online");
        usersTitle.setFont(new Font("Segoe UI", Font.BOLD, 13));
        usersTitle.setForeground(theme.text);

        userListModel = new DefaultListModel<>();
        userList = new JList<>(userListModel);
        userList.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        userList.setBorder(new EmptyBorder(8, 8, 8, 8));
        userList.setBackground(theme.inputBg);
        userList.setSelectionBackground(theme.selection);
        userList.setSelectionForeground(theme.text);
        userList.setCellRenderer(new UserCell(theme));

        JScrollPane us = new JScrollPane(userList);
        us.setBorder(BorderFactory.createCompoundBorder(
                new RoundedBorder(theme.border, 14),
                BorderFactory.createEmptyBorder()
        ));
        us.getViewport().setBackground(theme.inputBg);
        us.setPreferredSize(new Dimension(280, 0));

        usersCard.add(usersTitle, BorderLayout.NORTH);
        usersCard.add(us, BorderLayout.CENTER);

        center.add(msgCard, BorderLayout.CENTER);
        center.add(usersCard, BorderLayout.EAST);

        root.add(center, BorderLayout.CENTER);

        // Actions
        sendButton.addActionListener(e -> sendMessage());
        inputField.addActionListener(e -> sendMessage());

        showToast("Conectează-te cu un cont (LOGIN/REGISTER).", false);
    }

    // ===== Auth dialog =====
    private boolean showAuthDialog() {
        GradientPanel wrap = new GradientPanel(theme.headerGrad1, theme.headerGrad2, 16);
        wrap.setBorder(new EmptyBorder(14, 14, 14, 14));
        wrap.setLayout(new BorderLayout(10, 10));

        JLabel h = new JLabel("Autentificare / Înregistrare");
        h.setFont(new Font("Segoe UI", Font.BOLD, 15));
        h.setForeground(Color.WHITE);

        ShadowRoundedPanel formCard = new ShadowRoundedPanel(Color.WHITE, 16);
        formCard.setBorder(new EmptyBorder(12, 12, 12, 12));
        formCard.setLayout(new GridLayout(3, 2, 10, 10));

        JComboBox<String> modeBox = new JComboBox<>(new String[]{"LOGIN", "REGISTER"});
        JTextField userField = new JTextField();
        JPasswordField passField = new JPasswordField();

        styleField(modeBox);
        styleField(userField);
        styleField(passField);

        formCard.add(new JLabel("Mod:"));
        formCard.add(modeBox);
        formCard.add(new JLabel("Username:"));
        formCard.add(userField);
        formCard.add(new JLabel("Parolă:"));
        formCard.add(passField);

        wrap.add(h, BorderLayout.NORTH);
        wrap.add(formCard, BorderLayout.CENTER);

        int result = JOptionPane.showConfirmDialog(
                this, wrap, "Cont",
                JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE
        );

        if (result != JOptionPane.OK_OPTION) return false;

        String u = userField.getText().trim();
        String p = new String(passField.getPassword()).trim();
        if (u.isEmpty() || p.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Completează username și parolă!");
            return showAuthDialog();
        }

        this.mode = (String) modeBox.getSelectedItem();
        this.username = u;
        this.password = p;
        return true;
    }

    private void styleField(JComponent c) {
        c.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        c.setBorder(BorderFactory.createCompoundBorder(
                new RoundedBorder(new Color(220, 224, 231), 14),
                new EmptyBorder(8, 10, 8, 10)
        ));
        c.setBackground(Color.WHITE);
        c.setForeground(new Color(25, 28, 33));
        if (c instanceof JTextComponent) {
            ((JTextComponent) c).setCaretColor(new Color(25, 28, 33));
        }
    }

    // ===== Connect / switch account =====
    private void connect() {
        setStatus("Conectare…", new Color(255, 255, 255, 220), new Color(255, 255, 255, 40));
        showToast("Se conectează la server…", false);

        try {
            socket = new WebSocketClient(new URI(serverUri)) {
                @Override
                public void onOpen(ServerHandshake handshakedata) {
                    String authMsg = "AUTH|" + mode + "|" + username + "|" + password;
                    send(authMsg);
                }

                @Override
                public void onMessage(String message) {
                    SwingUtilities.invokeLater(() -> handleServerMessage(message));
                }

                @Override
                public void onClose(int code, String reason, boolean remote) {
                    SwingUtilities.invokeLater(() -> {
                        authed = false;
                        stopRecordingIfAny(false);
                        stopPlaying();
                        setStatus("Deconectat", new Color(255, 255, 255, 220), new Color(255, 255, 255, 40));
                        setInputEnabled(false);
                        showToast("Deconectat.", true);
                    });
                }

                @Override
                public void onError(Exception ex) {
                    SwingUtilities.invokeLater(() -> {
                        addError("Eroare: " + ex.getMessage());
                        showToast("Eroare conexiune.", true);
                        soundError();
                    });
                }
            };

            new Thread(socket::connect, "ws-connect").start();

        } catch (Exception e) {
            addError("URI invalid: " + e.getMessage());
            showToast("URI invalid.", true);
            soundError();
            setStatus("Deconectat", new Color(255, 255, 255, 220), new Color(255, 255, 255, 40));
        }
    }

    private void reconnect() {
        try { if (socket != null) socket.close(); } catch (Exception ignored) {}
        authed = false;
        setInputEnabled(false);
        connect();
    }

    private void switchAccount() {
        int r = JOptionPane.showConfirmDialog(
                this,
                "Vrei să schimbi contul? Vei fi deconectat.",
                "Schimbă cont",
                JOptionPane.YES_NO_OPTION
        );
        if (r != JOptionPane.YES_OPTION) return;

        stopRecordingIfAny(false);
        stopPlaying();

        try { if (socket != null) socket.close(); } catch (Exception ignored) {}

        authed = false;
        setInputEnabled(false);
        userListModel.clear();
        clearMessages();
        showToast("Alege alt cont…", false);

        if (showAuthDialog()) {
            reconnect();
        } else {
            showToast("Anulat.", false);
            setStatus("Deconectat", new Color(255, 255, 255, 220), new Color(255, 255, 255, 40));
        }
    }

    private void setInputEnabled(boolean enabled) {
        inputField.setEnabled(enabled);
        sendButton.setEnabled(enabled);
        imgButton.setEnabled(enabled);
        voiceButton.setEnabled(enabled);
    }

    private void clearMessages() {
        messagesPanel.removeAll();
        messagesPanel.revalidate();
        messagesPanel.repaint();
    }

    // ===== Server messages (clean mode: NO spam INFO in chat) =====
    private void handleServerMessage(String msg) {
        if (msg == null) return;

        // INFO: nu mai afișăm în chat. Doar toast pentru intrări/ieșiri.
        if (msg.startsWith("INFO|")) {
            String text = msg.substring(5).trim();

            // păstrăm doar evenimente utile (intră/iese) ca toast
            String lower = text.toLowerCase();
            if (lower.contains("a intrat") || lower.contains("a ieșit") || lower.contains("a iesit")) {
                showToast(text.replace("**", "").trim(), false);
                soundJoin();
            }
            return;
        }

        if (msg.startsWith("ERROR|")) {
            addError(msg.substring(6));
            showToast("Eroare.", true);
            soundError();
            return;
        }

        if (msg.startsWith("AUTH_OK|")) {
            authed = true;
            setStatus("Conectat: " + msg.substring(8), Color.WHITE, new Color(0, 0, 0, 60));
            setInputEnabled(true);
            showToast("Autentificat cu succes.", false);
            soundLogin();
            return;
        }

        if (msg.startsWith("AUTH_FAIL|")) {
            authed = false;
            setInputEnabled(false);
            setStatus("Auth eșuat", Color.WHITE, new Color(0, 0, 0, 60));
            JOptionPane.showMessageDialog(this, "Autentificare eșuată: " + msg.substring(10));
            showToast("Autentificare eșuată.", true);
            soundError();
            return;
        }

        if (msg.startsWith("USERS|")) {
            updateUsers(msg.substring(6));
            return;
        }

        // ===== Images history ===== HIMG|from|to|file|mime|ts|base64
        if (msg.startsWith("HIMG|")) {
            String[] p = msg.split("\\|", 7);
            if (p.length == 7) {
                addImage(p[1], p[2], p[3], p[4], p[6], p[1].equalsIgnoreCase(username), parseTs(p[5]));
            }
            return;
        }

        // ===== Images live ===== IMG|from|to|file|mime|ts|base64
        if (msg.startsWith("IMG|")) {
            String[] p = msg.split("\\|", 7);
            if (p.length == 7) {
                boolean mine = p[1].equalsIgnoreCase(username);
                addImage(p[1], p[2], p[3], p[4], p[6], mine, parseTs(p[5]));
                if (!mine) { soundRecvImage(); showToast("Ai primit o imagine.", false); }
            }
            return;
        }

        // ===== Voice history ===== HVOICE|from|to|file|mime|ts|base64
        if (msg.startsWith("HVOICE|")) {
            String[] p = msg.split("\\|", 7);
            if (p.length == 7) {
                addVoice(p[1], p[2], p[3], p[4], p[6], p[1].equalsIgnoreCase(username), parseTs(p[5]));
            }
            return;
        }

        // ===== Voice live ===== VOICE|from|to|file|mime|ts|base64
        if (msg.startsWith("VOICE|")) {
            String[] p = msg.split("\\|", 7);
            if (p.length == 7) {
                boolean mine = p[1].equalsIgnoreCase(username);
                addVoice(p[1], p[2], p[3], p[4], p[6], mine, parseTs(p[5]));
                if (!mine) { soundRecvVoice(); showToast("Ai primit un mesaj vocal.", false); }
            }
            return;
        }

        // ===== Text history =====
        if (msg.startsWith("HMSG|")) {
            String[] p = msg.split("\\|", 4);
            if (p.length >= 3) addChat(p[1], p[2], p[1].equalsIgnoreCase(username), parseTs(p.length == 4 ? p[3] : ""));
            return;
        }

        if (msg.startsWith("HPM|")) {
            String[] p = msg.split("\\|", 5);
            if (p.length >= 4) addPm(p[1], p[2], p[3], p[1].equalsIgnoreCase(username), parseTs(p.length == 5 ? p[4] : ""));
            return;
        }

        // ===== Text live =====
        if (msg.startsWith("MSG|")) {
            String[] p = msg.split("\\|", 3);
            if (p.length == 3) {
                boolean mine = p[1].equalsIgnoreCase(username);
                addChat(p[1], p[2], mine, System.currentTimeMillis());
                if (!mine) soundRecvMsg();
            }
            return;
        }

        if (msg.startsWith("PM|")) {
            String[] p = msg.split("\\|", 4);
            if (p.length == 4) {
                boolean mine = p[1].equalsIgnoreCase(username);
                addPm(p[1], p[2], p[3], mine, System.currentTimeMillis());
                if (!mine) soundRecvMsg();
            }
            return;
        }

        // fallback (rar)
        showToast("Mesaj necunoscut primit.", false);
    }

    private long parseTs(String tsMillis) {
        try { return Long.parseLong(tsMillis); }
        catch (Exception e) { return System.currentTimeMillis(); }
    }

    private void updateUsers(String csv) {
        userListModel.clear();
        if (csv == null || csv.isBlank()) return;
        for (String u : csv.split(",")) {
            u = u.trim();
            if (!u.isEmpty()) userListModel.addElement(u);
        }
    }

    private void setStatus(String text, Color fg, Color bg) {
        statusPill.setText(text);
        statusPill.setForeground(fg);
        statusPill.setBackground(bg);
    }

    // ===== Toast (info util, fără spam în chat) =====
    private void showToast(String text, boolean danger) {
        if (text == null || text.isBlank()) return;

        toastLabel.setText(text);
        toastLabel.setBackground(danger ? new Color(220, 40, 40, 120) : new Color(0, 0, 0, 35));
        toastLabel.setVisible(true);

        if (toastTimer != null) toastTimer.stop();
        toastTimer = new Timer(3500, e -> toastLabel.setVisible(false));
        toastTimer.setRepeats(false);
        toastTimer.start();
    }

    // ===== Send text =====
    private void sendMessage() {
        if (!authed || socket == null || !socket.isOpen()) return;

        String text = inputField.getText().trim();
        if (text.isEmpty()) return;

        String selected = getSelectedUserOrEmpty();
        if (!selected.isBlank()) {
            socket.send("/w " + selected + " " + text);
        } else {
            socket.send(text);
        }

        inputField.setText("");
        soundSendMsg();
    }

    private String getSelectedUserOrEmpty() {
        String selected = userList.getSelectedValue();
        if (selected != null && !selected.isBlank() && !selected.equalsIgnoreCase(username)) return selected.trim();
        return "";
    }

    // ===== Images =====
    private void chooseAndSendImage() {
        if (!authed || socket == null || !socket.isOpen()) return;

        JFileChooser fc = new JFileChooser();
        fc.setDialogTitle("Alege o imagine");
        fc.setFileFilter(new FileNameExtensionFilter("Imagini (png/jpg/jpeg/gif)", "png", "jpg", "jpeg", "gif"));

        int r = fc.showOpenDialog(this);
        if (r != JFileChooser.APPROVE_OPTION) return;

        Path path = fc.getSelectedFile().toPath();

        new Thread(() -> {
            try {
                byte[] bytes = Files.readAllBytes(path);
                if (bytes.length > MAX_IMAGE_BYTES) {
                    SwingUtilities.invokeLater(() -> showToast("Imagine prea mare (max ~0.8MB).", true));
                    soundError();
                    return;
                }

                String fileName = path.getFileName().toString().replace("|", "_");
                String mime = guessMime(fileName);
                String b64 = Base64.getEncoder().encodeToString(bytes);

                String to = getSelectedUserOrEmpty();
                socket.send("SENDIMG|" + to + "|" + fileName + "|" + mime + "|" + b64);

                SwingUtilities.invokeLater(() -> showToast(to.isBlank() ? "Imagine trimisă (global)." : ("Imagine trimisă către " + to + "."), false));
                soundSendImage();

            } catch (Exception ex) {
                SwingUtilities.invokeLater(() -> showToast("Eroare la imagine.", true));
                soundError();
            }
        }, "img-send").start();
    }

    private String guessMime(String fileName) {
        String f = fileName.toLowerCase();
        if (f.endsWith(".png")) return "image/png";
        if (f.endsWith(".jpg") || f.endsWith(".jpeg")) return "image/jpeg";
        if (f.endsWith(".gif")) return "image/gif";
        return "application/octet-stream";
    }

    // ===== Voice =====
    private void toggleRecordVoice() {
        if (!authed || socket == null || !socket.isOpen()) return;
        if (!recording) startRecording();
        else stopRecordingIfAny(true);
    }

    private void startRecording() {
        recording = true;
        recordingTo = getSelectedUserOrEmpty();

        // switch button to STOP + pulse red
        voiceButton.setIconOnly(new StopIcon(18, Color.WHITE));
        voiceButton.setToolTipText("Stop & trimite voice");
        voiceButton.setGradient(theme.recGrad1, theme.recGrad2);

        startPulse();

        showToast("Înregistrare voice… (max 15 sec)", false);
        soundRecordStart();

        recordThread = new Thread(() -> {
            AudioFormat format = new AudioFormat(16000f, 16, 1, true, false);
            TargetDataLine line = null;

            try {
                DataLine.Info info = new DataLine.Info(TargetDataLine.class, format);
                if (!AudioSystem.isLineSupported(info)) {
                    SwingUtilities.invokeLater(() -> showToast("Microfon indisponibil.", true));
                    soundError();
                    return;
                }

                line = (TargetDataLine) AudioSystem.getLine(info);
                line.open(format);
                line.start();

                ByteArrayOutputStream rawOut = new ByteArrayOutputStream();
                byte[] buf = new byte[4096];

                long start = System.currentTimeMillis();

                while (recording) {
                    int read = line.read(buf, 0, buf.length);
                    if (read > 0) rawOut.write(buf, 0, read);
                    if (System.currentTimeMillis() - start > MAX_RECORD_MS) break;
                }

                try { line.stop(); } catch (Exception ignored) {}
                try { line.close(); } catch (Exception ignored) {}

                byte[] raw = rawOut.toByteArray();
                if (raw.length < 2500) {
                    SwingUtilities.invokeLater(() -> showToast("Voice prea scurt (nu trimit).", true));
                    soundError();
                    return;
                }

                byte[] wav = pcmToWav(raw, format);
                if (wav.length > MAX_AUDIO_BYTES) {
                    SwingUtilities.invokeLater(() -> showToast("Voice prea mare. Înregistrează mai scurt.", true));
                    soundError();
                    return;
                }

                String fileName = "voice_" + System.currentTimeMillis() + ".wav";
                String b64 = Base64.getEncoder().encodeToString(wav);

                socket.send("SENDVOICE|" + recordingTo + "|" + fileName + "|audio/wav|" + b64);

                SwingUtilities.invokeLater(() -> showToast(
                        recordingTo.isBlank() ? "Voice trimis (global)." : ("Voice trimis către " + recordingTo + "."),
                        false
                ));
                soundSendVoice();

            } catch (Exception ex) {
                SwingUtilities.invokeLater(() -> showToast("Eroare voice.", true));
                soundError();
            } finally {
                recording = false;
                SwingUtilities.invokeLater(this::resetVoiceButton);
                if (line != null) {
                    try { line.stop(); } catch (Exception ignored) {}
                    try { line.close(); } catch (Exception ignored) {}
                }
            }
        }, "voice-rec");

        recordThread.start();
    }

    private void stopRecordingIfAny(boolean userStop) {
        if (!recording) return;
        recording = false;
        if (userStop) {
            showToast("Se procesează voice…", false);
            soundRecordStop();
        }
    }

    private void resetVoiceButton() {
        stopPulse();
        voiceButton.setIconOnly(new MicIcon(18, Color.WHITE));
        voiceButton.setToolTipText("Înregistrează voice (max 15 sec) • click = start/stop");
        voiceButton.setGradient(theme.btnGradA1, theme.btnGradA2);
    }

    private void startPulse() {
        pulseOn = false;
        if (recordPulseTimer != null) recordPulseTimer.stop();

        recordPulseTimer = new Timer(220, e -> {
            pulseOn = !pulseOn;
            if (pulseOn) voiceButton.setGradient(theme.recGrad1, theme.recGrad2);
            else voiceButton.setGradient(theme.recGrad1b, theme.recGrad2b);
            voiceButton.repaint();
        });
        recordPulseTimer.start();
    }

    private void stopPulse() {
        if (recordPulseTimer != null) recordPulseTimer.stop();
        recordPulseTimer = null;
        pulseOn = false;
    }

    private byte[] pcmToWav(byte[] pcm, AudioFormat format) throws Exception {
        ByteArrayInputStream bais = new ByteArrayInputStream(pcm);
        long frames = pcm.length / format.getFrameSize();
        AudioInputStream ais = new AudioInputStream(bais, format, frames);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        AudioSystem.write(ais, AudioFileFormat.Type.WAVE, baos);
        return baos.toByteArray();
    }

    // ===== Voice playback =====
    private void playWav(byte[] wavBytes) {
        new Thread(() -> {
            try {
                AudioInputStream ais = AudioSystem.getAudioInputStream(new ByteArrayInputStream(wavBytes));
                Clip clip = AudioSystem.getClip();
                clip.open(ais);
                playingClip = clip;
                clip.start();
                soundPlay();
            } catch (Exception ex) {
                SwingUtilities.invokeLater(() -> showToast("Nu pot reda voice.", true));
                soundError();
            }
        }, "voice-play").start();
    }

    private void stopPlaying() {
        try {
            Clip c = playingClip;
            playingClip = null;
            if (c != null) {
                c.stop();
                c.close();
            }
        } catch (Exception ignored) {}
    }

    // ===== Bubbles =====
    private void addError(String text) {
        addBubble(makeTextBubble("EROARE", text, theme.errBubble, theme.errGrad1, theme.errGrad2, false, System.currentTimeMillis()));
    }

    private void addChat(String sender, String text, boolean mine, long tsMillis) {
        if (mine) addBubble(makeTextBubble(sender, text, theme.myBubble, theme.myGrad1, theme.myGrad2, true, tsMillis));
        else addBubble(makeTextBubble(sender, text, theme.otherBubble, null, null, false, tsMillis));
    }

    private void addPm(String from, String to, String text, boolean mine, long tsMillis) {
        String title = "[PM] " + from + " → " + to;
        if (mine) addBubble(makeTextBubble(title, text, theme.myPm, theme.pmGrad1, theme.pmGrad2, true, tsMillis));
        else addBubble(makeTextBubble(title, text, theme.otherPm, null, null, false, tsMillis));
    }

    private void addImage(String from, String to, String file, String mime, String b64, boolean mine, long tsMillis) {
        String title = (to != null && !to.isBlank()) ? "[IMG PM] " + from + " → " + to : "[IMG] " + from;
        if (mine) addBubble(makeImageBubble(title, file, mime, b64, theme.myGrad1, theme.myGrad2, true, tsMillis));
        else addBubble(makeImageBubble(title, file, mime, b64, null, null, false, tsMillis));
    }

    private void addVoice(String from, String to, String file, String mime, String b64, boolean mine, long tsMillis) {
        String title = (to != null && !to.isBlank()) ? "[VOICE PM] " + from + " → " + to : "[VOICE] " + from;
        if (mine) addBubble(makeVoiceBubble(title, file, mime, b64, theme.myGrad1, theme.myGrad2, true, tsMillis));
        else addBubble(makeVoiceBubble(title, file, mime, b64, null, null, false, tsMillis));
    }

    private JPanel makeTextBubble(String title, String text, Color solidBg, Color g1, Color g2,
                                  boolean alignRight, long tsMillis) {

        JPanel row = new JPanel(new BorderLayout());
        row.setOpaque(false);
        row.setBorder(new EmptyBorder(6, 6, 6, 6));

        JPanel bubble = (g1 != null && g2 != null) ? new GradientPanel(g1, g2, 16) : new ShadowRoundedPanel(solidBg, 16);
        bubble.setLayout(new BorderLayout(8, 6));
        bubble.setBorder(new EmptyBorder(10, 12, 10, 12));

        JLabel t = new JLabel(title + "  •  " + TS_FMT.format(Instant.ofEpochMilli(tsMillis)));
        t.setFont(new Font("Segoe UI", Font.BOLD, 12));
        t.setForeground(alignRight && g1 != null ? Color.WHITE : theme.text);

        JTextArea body = new JTextArea(text);
        body.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        body.setForeground(alignRight && g1 != null ? new Color(255, 255, 255, 235) : theme.text);
        body.setOpaque(false);
        body.setLineWrap(true);
        body.setWrapStyleWord(true);
        body.setEditable(false);

        bubble.add(t, BorderLayout.NORTH);
        bubble.add(body, BorderLayout.CENTER);

        JPanel wrap = new JPanel(new BorderLayout());
        wrap.setOpaque(false);
        wrap.add(bubble, alignRight ? BorderLayout.EAST : BorderLayout.WEST);

        bubble.setMaximumSize(new Dimension(600, Integer.MAX_VALUE));
        row.add(wrap, BorderLayout.CENTER);
        return row;
    }

    private JPanel makeImageBubble(String title, String fileName, String mime, String b64,
                                   Color g1, Color g2, boolean alignRight, long tsMillis) {

        JPanel row = new JPanel(new BorderLayout());
        row.setOpaque(false);
        row.setBorder(new EmptyBorder(6, 6, 6, 6));

        JPanel bubble = (g1 != null && g2 != null) ? new GradientPanel(g1, g2, 16) : new ShadowRoundedPanel(theme.otherBubble, 16);
        bubble.setLayout(new BorderLayout(8, 8));
        bubble.setBorder(new EmptyBorder(10, 12, 10, 12));

        JLabel t = new JLabel(title + "  •  " + TS_FMT.format(Instant.ofEpochMilli(tsMillis)));
        t.setFont(new Font("Segoe UI", Font.BOLD, 12));
        t.setForeground(alignRight && g1 != null ? Color.WHITE : theme.text);

        JLabel meta = new JLabel(fileName + "  (" + mime + ")");
        meta.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        meta.setForeground(alignRight && g1 != null ? new Color(255,255,255,220) : new Color(110, 116, 128));

        JPanel top = new JPanel();
        top.setOpaque(false);
        top.setLayout(new BoxLayout(top, BoxLayout.Y_AXIS));
        top.add(t);
        top.add(Box.createVerticalStrut(2));
        top.add(meta);

        JLabel imgLabel = new JLabel("Imagine…");
        imgLabel.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        imgLabel.setForeground(alignRight && g1 != null ? new Color(255,255,255,220) : theme.text);
        imgLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        imgLabel.setBorder(new EmptyBorder(6, 0, 2, 0));

        byte[] bytes;
        try { bytes = Base64.getDecoder().decode(b64); }
        catch (Exception e) { bytes = null; }

        if (bytes != null) {
            try {
                BufferedImage bi = ImageIO.read(new ByteArrayInputStream(bytes));
                if (bi != null) {
                    imgLabel.setText("");
                    imgLabel.setIcon(scaleIcon(bi, 440, 270));
                    byte[] finalBytes = bytes;
                    imgLabel.setToolTipText("Click pentru mărire");
                    imgLabel.addMouseListener(new MouseAdapter() {
                        @Override public void mouseClicked(MouseEvent e) { openImageViewer(finalBytes, fileName); }
                    });
                } else imgLabel.setText("Nu pot afișa această imagine.");
            } catch (Exception e) {
                imgLabel.setText("Eroare afișare.");
            }
        } else imgLabel.setText("Imagine invalidă.");

        bubble.add(top, BorderLayout.NORTH);
        bubble.add(imgLabel, BorderLayout.CENTER);

        JPanel wrap = new JPanel(new BorderLayout());
        wrap.setOpaque(false);
        wrap.add(bubble, alignRight ? BorderLayout.EAST : BorderLayout.WEST);

        bubble.setMaximumSize(new Dimension(650, Integer.MAX_VALUE));
        row.add(wrap, BorderLayout.CENTER);
        return row;
    }

    private JPanel makeVoiceBubble(String title, String fileName, String mime, String b64,
                                   Color g1, Color g2, boolean alignRight, long tsMillis) {

        JPanel row = new JPanel(new BorderLayout());
        row.setOpaque(false);
        row.setBorder(new EmptyBorder(6, 6, 6, 6));

        JPanel bubble = (g1 != null && g2 != null) ? new GradientPanel(g1, g2, 16) : new ShadowRoundedPanel(theme.otherBubble, 16);
        bubble.setLayout(new BorderLayout(8, 8));
        bubble.setBorder(new EmptyBorder(10, 12, 10, 12));

        JLabel t = new JLabel(title + "  •  " + TS_FMT.format(Instant.ofEpochMilli(tsMillis)));
        t.setFont(new Font("Segoe UI", Font.BOLD, 12));
        t.setForeground(alignRight && g1 != null ? Color.WHITE : theme.text);

        byte[] wav;
        try { wav = Base64.getDecoder().decode(b64); }
        catch (Exception e) { wav = null; }

        String dur = "";
        if (wav != null) {
            try {
                AudioInputStream ais = AudioSystem.getAudioInputStream(new ByteArrayInputStream(wav));
                AudioFormat af = ais.getFormat();
                long frames = ais.getFrameLength();
                double sec = (frames > 0 && af.getFrameRate() > 0) ? (frames / af.getFrameRate()) : 0;
                if (sec > 0) dur = String.format(" • %.1fs", sec);
            } catch (Exception ignored) {}
        }

        JLabel meta = new JLabel(fileName + "  (" + mime + ")" + dur);
        meta.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        meta.setForeground(alignRight && g1 != null ? new Color(255,255,255,220) : new Color(110, 116, 128));

        JPanel top = new JPanel();
        top.setOpaque(false);
        top.setLayout(new BoxLayout(top, BoxLayout.Y_AXIS));
        top.add(t);
        top.add(Box.createVerticalStrut(2));
        top.add(meta);

        GradientButton play = new GradientButton(null, theme.btnGradB1, theme.btnGradB2);
        play.setSmall(true);
        play.setIconOnly(new PlayIcon(18, Color.WHITE));
        play.setToolTipText("Redă voice");
        play.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));

        if (wav == null) {
            play.setEnabled(false);
            play.setToolTipText("Voice invalid");
        } else {
            byte[] finalWav = wav;
            play.addActionListener(e -> {
                stopPlaying();
                playWav(finalWav);
            });
        }

        bubble.add(top, BorderLayout.NORTH);
        bubble.add(play, BorderLayout.CENTER);

        JPanel wrap = new JPanel(new BorderLayout());
        wrap.setOpaque(false);
        wrap.add(bubble, alignRight ? BorderLayout.EAST : BorderLayout.WEST);

        bubble.setMaximumSize(new Dimension(520, Integer.MAX_VALUE));
        row.add(wrap, BorderLayout.CENTER);
        return row;
    }

    private ImageIcon scaleIcon(BufferedImage bi, int maxW, int maxH) {
        int w = bi.getWidth(), h = bi.getHeight();
        double s = Math.min((double) maxW / w, (double) maxH / h);
        s = Math.min(1.0, s);
        int nw = Math.max(1, (int) (w * s));
        int nh = Math.max(1, (int) (h * s));
        Image scaled = bi.getScaledInstance(nw, nh, Image.SCALE_SMOOTH);
        return new ImageIcon(scaled);
    }

    private void openImageViewer(byte[] bytes, String fileName) {
        JFrame f = new JFrame(fileName);
        f.setSize(900, 650);
        f.setLocationRelativeTo(this);

        JLabel lbl = new JLabel();
        lbl.setHorizontalAlignment(SwingConstants.CENTER);

        try {
            BufferedImage bi = ImageIO.read(new ByteArrayInputStream(bytes));
            if (bi != null) lbl.setIcon(new ImageIcon(bi));
            else lbl.setText("Nu pot deschide imaginea.");
        } catch (Exception e) {
            lbl.setText("Eroare la imagine.");
        }

        f.setContentPane(new JScrollPane(lbl));
        f.setVisible(true);
    }

    private void addBubble(JPanel bubbleRow) {
        messagesPanel.add(bubbleRow);
        messagesPanel.add(Box.createVerticalStrut(4));
        messagesPanel.revalidate();
        SwingUtilities.invokeLater(() -> {
            JScrollBar bar = messagesScroll.getVerticalScrollBar();
            bar.setValue(bar.getMaximum());
        });
    }

    // ====== SUNETE (schimbate) ======
    // stil: "soft click + whoosh"
    private void soundLogin()       { Tone.playSequence(new int[]{523, 659, 784}, new int[]{80, 80, 120}); }
    private void soundJoin()        { Tone.playSequence(new int[]{740, 988}, new int[]{70, 110}); }
    private void soundSendMsg()     { Tone.play(880, 45); }
    private void soundRecvMsg()     { Tone.playSequence(new int[]{392, 523}, new int[]{70, 90}); }
    private void soundSendImage()   { Tone.playSequence(new int[]{659, 988}, new int[]{65, 110}); }
    private void soundRecvImage()   { Tone.playSequence(new int[]{587, 784}, new int[]{65, 120}); }
    private void soundSendVoice()   { Tone.playSequence(new int[]{494, 659, 880}, new int[]{60, 70, 120}); }
    private void soundRecvVoice()   { Tone.playSequence(new int[]{440, 587, 784}, new int[]{60, 70, 110}); }
    private void soundRecordStart() { Tone.playSequence(new int[]{660, 660}, new int[]{45, 45}); }
    private void soundRecordStop()  { Tone.playSequence(new int[]{660, 440}, new int[]{60, 120}); }
    private void soundPlay()        { Tone.playSequence(new int[]{784, 988}, new int[]{50, 90}); }
    private void soundError()       { Tone.playSequence(new int[]{196, 165}, new int[]{120, 160}); }

    // ===== UI style classes =====
    private static final class Theme {
        final Color bg, card, text, border;
        final Color inputBg, inputBar, selection;

        final Color headerGrad1, headerGrad2;
        final Color btnGradA1, btnGradA2;
        final Color btnGradB1, btnGradB2;

        // recording pulse
        final Color recGrad1, recGrad2;
        final Color recGrad1b, recGrad2b;

        // bubbles
        final Color otherBubble, errBubble, otherPm;
        final Color myBubble, myPm;

        final Color myGrad1, myGrad2;
        final Color pmGrad1, pmGrad2;
        final Color errGrad1, errGrad2;

        private Theme() {
            bg = new Color(246, 247, 251);
            card = Color.WHITE;
            text = new Color(25, 28, 33);
            border = new Color(224, 228, 238);

            inputBg = new Color(255, 255, 255);
            inputBar = new Color(250, 251, 255);
            selection = new Color(232, 240, 255);

            headerGrad1 = new Color(123, 45, 255);
            headerGrad2 = new Color(45, 196, 255);

            btnGradA1 = new Color(255, 115, 90);
            btnGradA2 = new Color(255, 70, 145);

            btnGradB1 = new Color(45, 126, 255);
            btnGradB2 = new Color(0, 210, 255);

            // recording (red pulse)
            recGrad1  = new Color(255, 70, 70);
            recGrad2  = new Color(255, 70, 145);
            recGrad1b = new Color(230, 45, 45);
            recGrad2b = new Color(230, 60, 120);

            otherBubble = new Color(245, 246, 248);
            errBubble = new Color(255, 238, 238);
            otherPm = new Color(255, 244, 230);

            myBubble = new Color(230, 245, 255);
            myPm = new Color(240, 232, 255);

            myGrad1 = new Color(45, 126, 255);
            myGrad2 = new Color(0, 210, 255);

            pmGrad1 = new Color(145, 70, 255);
            pmGrad2 = new Color(255, 70, 145);

            errGrad1 = new Color(255, 90, 90);
            errGrad2 = new Color(255, 145, 70);
        }

        static Theme vibrant() { return new Theme(); }
    }

    private static final class ShadowRoundedPanel extends JPanel {
        private final Color bg;
        private final int radius;

        ShadowRoundedPanel(Color bg, int radius) {
            this.bg = bg;
            this.radius = radius;
            setOpaque(false);
        }

        @Override
        protected void paintComponent(Graphics g) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            // shadow
            int x = 0, y = 0, w = getWidth(), h = getHeight();
            for (int i = 10; i >= 1; i--) {
                int alpha = i * 2; // soft
                g2.setColor(new Color(0, 0, 0, alpha));
                g2.fillRoundRect(x + 2, y + 3, w - 4, h - 4, radius, radius);
            }

            // body
            g2.setColor(bg);
            g2.fillRoundRect(x, y, w - 1, h - 1, radius, radius);

            g2.dispose();
            super.paintComponent(g);
        }
    }

    private static final class GradientPanel extends JPanel {
        private final Color c1, c2;
        private final int radius;

        GradientPanel(Color c1, Color c2, int radius) {
            this.c1 = c1;
            this.c2 = c2;
            this.radius = radius;
            setOpaque(false);
        }

        @Override
        protected void paintComponent(Graphics g) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            GradientPaint gp = new GradientPaint(0, 0, c1, getWidth(), getHeight(), c2);
            g2.setPaint(gp);
            g2.fillRoundRect(0, 0, getWidth(), getHeight(), radius, radius);

            g2.dispose();
            super.paintComponent(g);
        }
    }

    private static final class RoundedBorder extends LineBorder {
        private final int radius;

        RoundedBorder(Color color, int radius) {
            super(color, 1, true);
            this.radius = radius;
        }

        @Override
        public void paintBorder(Component c, Graphics g, int x, int y, int width, int height) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2.setColor(lineColor);
            g2.drawRoundRect(x, y, width - 1, height - 1, radius, radius);
            g2.dispose();
        }
    }

    private static final class GradientButton extends JButton {
        private Color g1, g2;
        private boolean hover = false;
        private boolean press = false;
        private boolean small = false;

        GradientButton(String text, Color g1, Color g2) {
            super(text);
            this.g1 = g1;
            this.g2 = g2;

            setFont(new Font("Segoe UI", Font.BOLD, 13));
            setForeground(Color.WHITE);
            setFocusPainted(false);
            setBorder(new EmptyBorder(12, 16, 12, 16));
            setContentAreaFilled(false);
            setOpaque(false);
            setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));

            addMouseListener(new MouseAdapter() {
                @Override public void mouseEntered(MouseEvent e) { hover = true; repaint(); }
                @Override public void mouseExited(MouseEvent e)  { hover = false; press = false; repaint(); }
                @Override public void mousePressed(MouseEvent e) { press = true; repaint(); }
                @Override public void mouseReleased(MouseEvent e){ press = false; repaint(); }
            });
        }

        void setGradient(Color a, Color b) { this.g1 = a; this.g2 = b; repaint(); }

        void setSmall(boolean v) {
            small = v;
            setFont(new Font("Segoe UI", Font.BOLD, 12));
            setBorder(new EmptyBorder(9, 12, 9, 12));
        }

        void setIconOnly(Icon icon) {
            setText(null);
            setIcon(icon);
            setHorizontalAlignment(SwingConstants.CENTER);
            setVerticalAlignment(SwingConstants.CENTER);
            setBorder(new EmptyBorder(small ? 9 : 12, small ? 12 : 14, small ? 9 : 12, small ? 12 : 14));
        }

        @Override
        protected void paintComponent(Graphics g) {
            Graphics2D g2d = (Graphics2D) g.create();
            g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            int arc = small ? 12 : 14;

            Color a = isEnabled() ? g1 : new Color(175, 180, 190);
            Color b = isEnabled() ? g2 : new Color(175, 180, 190);

            if (isEnabled() && hover) { a = brighten(a, 0.06f); b = brighten(b, 0.06f); }
            if (isEnabled() && press) { a = darken(a, 0.08f); b = darken(b, 0.08f); }

            GradientPaint gp = new GradientPaint(0, 0, a, getWidth(), getHeight(), b);
            g2d.setPaint(gp);
            g2d.fillRoundRect(0, 0, getWidth(), getHeight(), arc, arc);

            g2d.dispose();
            super.paintComponent(g);
        }

        private static Color brighten(Color c, float k) {
            return new Color(clamp((int)(c.getRed()*(1f+k))), clamp((int)(c.getGreen()*(1f+k))), clamp((int)(c.getBlue()*(1f+k))));
        }
        private static Color darken(Color c, float k) {
            return new Color(clamp((int)(c.getRed()*(1f-k))), clamp((int)(c.getGreen()*(1f-k))), clamp((int)(c.getBlue()*(1f-k))));
        }
        private static int clamp(int v) { return Math.max(0, Math.min(255, v)); }
    }

    private static final class PromptTextField extends JTextField {
        private final String prompt;
        PromptTextField(String prompt) { this.prompt = prompt; }

        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            if (isEnabled() && getText().isEmpty() && !isFocusOwner()) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
                g2.setFont(getFont());
                g2.setColor(new Color(150, 156, 168));
                Insets in = getInsets();
                g2.drawString(prompt, in.left + 2, getHeight() / 2 + getFont().getSize() / 2 - 2);
                g2.dispose();
            }
        }
    }

    private static final class UserCell extends DefaultListCellRenderer {
        private final Theme t;
        UserCell(Theme t) { this.t = t; }

        @Override
        public Component getListCellRendererComponent(JList<?> list, Object value, int index,
                                                     boolean isSelected, boolean cellHasFocus) {
            JLabel c = (JLabel) super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
            c.setBorder(new EmptyBorder(8, 10, 8, 10));
            c.setFont(new Font("Segoe UI", Font.PLAIN, 13));
            c.setForeground(t.text);
            c.setBackground(isSelected ? t.selection : t.inputBg);
            return c;
        }
    }

    // ===== Tone generator =====
    private static final class Tone {
        private static final float SAMPLE_RATE = 44100f;

        static void play(int hz, int ms) { playSequence(new int[]{hz}, new int[]{ms}); }

        static void playSequence(int[] hz, int[] ms) {
            new Thread(() -> {
                try {
                    AudioFormat af = new AudioFormat(SAMPLE_RATE, 16, 1, true, false);
                    SourceDataLine line = AudioSystem.getSourceDataLine(af);
                    line.open(af);
                    line.start();

                    for (int i = 0; i < hz.length; i++) {
                        writeTone(line, hz[i], ms[i]);
                        writeSilence(line, 20);
                    }

                    line.drain();
                    line.stop();
                    line.close();
                } catch (Exception ignored) {}
            }, "tone").start();
        }

        private static void writeTone(SourceDataLine line, int hz, int ms) {
            int samples = (int) ((ms / 1000f) * SAMPLE_RATE);
            byte[] out = new byte[samples * 2];

            double omega = 2.0 * Math.PI * hz;
            for (int i = 0; i < samples; i++) {
                double t = i / SAMPLE_RATE;
                short val = (short) (Math.sin(omega * t) * 10500);
                out[i * 2] = (byte) (val & 0xff);
                out[i * 2 + 1] = (byte) ((val >> 8) & 0xff);
            }
            line.write(out, 0, out.length);
        }

        private static void writeSilence(SourceDataLine line, int ms) {
            int samples = (int) ((ms / 1000f) * SAMPLE_RATE);
            byte[] out = new byte[samples * 2];
            line.write(out, 0, out.length);
        }
    }

    // ===== Vector icons (no files needed) =====
    private static abstract class VIcon implements Icon {
        final int size;
        final Color color;
        VIcon(int size, Color color) { this.size = size; this.color = color; }
        @Override public int getIconWidth() { return size; }
        @Override public int getIconHeight() { return size; }
        protected Graphics2D g2(Graphics g) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2.setStroke(new BasicStroke(2.2f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            g2.setColor(color);
            return g2;
        }
    }

    private static final class CameraIcon extends VIcon {
        CameraIcon(int size, Color color) { super(size, color); }
        @Override public void paintIcon(Component c, Graphics g, int x, int y) {
            Graphics2D g2 = g2(g);
            int s = size;
            int px = x, py = y;

            g2.drawRoundRect(px + 2, py + 5, s - 4, s - 8, 6, 6);
            g2.drawRect(px + 5, py + 3, 6, 4); // top bump
            g2.drawOval(px + s/2 - 4, py + s/2 - 2, 8, 8); // lens

            g2.dispose();
        }
    }

    private static final class MicIcon extends VIcon {
        MicIcon(int size, Color color) { super(size, color); }
        @Override public void paintIcon(Component c, Graphics g, int x, int y) {
            Graphics2D g2 = g2(g);
            int s = size;
            int px = x, py = y;

            g2.drawRoundRect(px + s/2 - 4, py + 3, 8, 10, 6, 6);     // capsule
            g2.drawLine(px + s/2, py + 13, px + s/2, py + 15);        // stem
            g2.drawArc(px + s/2 - 6, py + 10, 12, 10, 200, 140);      // holder arc
            g2.drawLine(px + s/2 - 6, py + 16, px + s/2 + 6, py + 16);// base

            g2.dispose();
        }
    }

    private static final class StopIcon extends VIcon {
        StopIcon(int size, Color color) { super(size, color); }
        @Override public void paintIcon(Component c, Graphics g, int x, int y) {
            Graphics2D g2 = g2(g);
            int s = size;
            g2.fillRoundRect(x + 4, y + 4, s - 8, s - 8, 4, 4);
            g2.dispose();
        }
    }

    private static final class SendIcon extends VIcon {
        SendIcon(int size, Color color) { super(size, color); }
        @Override public void paintIcon(Component c, Graphics g, int x, int y) {
            Graphics2D g2 = g2(g);
            int s = size;
            int px = x, py = y;

            Polygon p = new Polygon();
            p.addPoint(px + 2, py + s/2);
            p.addPoint(px + s - 2, py + 2);
            p.addPoint(px + s - 6, py + s/2);
            p.addPoint(px + s - 2, py + s - 2);
            g2.fillPolygon(p);

            g2.setColor(new Color(255,255,255,170));
            g2.setStroke(new BasicStroke(1.6f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            g2.drawLine(px + 6, py + s/2, px + s - 9, py + s/2);

            g2.dispose();
        }
    }

    private static final class PlayIcon extends VIcon {
        PlayIcon(int size, Color color) { super(size, color); }
        @Override public void paintIcon(Component c, Graphics g, int x, int y) {
            Graphics2D g2 = g2(g);
            int s = size;
            Polygon p = new Polygon();
            p.addPoint(x + 6, y + 4);
            p.addPoint(x + s - 4, y + s/2);
            p.addPoint(x + 6, y + s - 4);
            g2.fillPolygon(p);
            g2.dispose();
        }
    }

    private static final class SwapIcon extends VIcon {
        SwapIcon(int size, Color color) { super(size, color); }
        @Override public void paintIcon(Component c, Graphics g, int x, int y) {
            Graphics2D g2 = g2(g);
            int s = size;

            g2.drawLine(x + 4, y + 6, x + s - 6, y + 6);
            g2.drawLine(x + s - 8, y + 4, x + s - 6, y + 6);
            g2.drawLine(x + s - 8, y + 8, x + s - 6, y + 6);

            g2.drawLine(x + s - 4, y + s - 6, x + 6, y + s - 6);
            g2.drawLine(x + 8, y + s - 8, x + 6, y + s - 6);
            g2.drawLine(x + 8, y + s - 4, x + 6, y + s - 6);

            g2.dispose();
        }
    }

    public static void main(String[] args) {
        String uri = (args != null && args.length > 0 && args[0] != null && !args[0].isBlank())
                ? args[0].trim()
                : "ws://localhost:8080";
        SwingUtilities.invokeLater(() -> new ChatClient(uri).setVisible(true));
    }
}
