import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;

public class Launcher extends JFrame {

    private ClientServer server;
    private final Theme theme = Theme.vibrant();

    private JLabel statusPill;
    private GradientButton btnServer;
    private GradientButton btnClient;

    private static final int DEFAULT_PORT = 8080;

    public Launcher() {
        setTitle("CHAT — Launcher");
        setSize(640, 360);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        initGui();
    }

    private void initGui() {
        JPanel root = new JPanel(new BorderLayout(14, 14));
        root.setBorder(new EmptyBorder(16, 16, 16, 16));
        root.setBackground(theme.bg);
        setContentPane(root);

        // ===== Header gradient =====
        GradientPanel header = new GradientPanel(theme.headerGrad1, theme.headerGrad2, 18);
        header.setLayout(new BorderLayout(12, 12));
        header.setBorder(new EmptyBorder(14, 16, 14, 16));

        JPanel left = new JPanel();
        left.setOpaque(false);
        left.setLayout(new BoxLayout(left, BoxLayout.Y_AXIS));

        JLabel title = new JLabel("Launcher");
        title.setFont(new Font("Segoe UI", Font.BOLD, 20));
        title.setForeground(Color.WHITE);

        JLabel subtitle = new JLabel("Pornește serverul și deschide clientul");
        subtitle.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        subtitle.setForeground(new Color(255, 255, 255, 210));

        left.add(title);
        left.add(Box.createVerticalStrut(4));
        left.add(subtitle);

        statusPill = new JLabel("Oprit");
        statusPill.setFont(new Font("Segoe UI", Font.BOLD, 12));
        statusPill.setForeground(Color.WHITE);
        statusPill.setOpaque(true);
        statusPill.setBackground(new Color(255, 255, 255, 40));
        statusPill.setBorder(new EmptyBorder(8, 12, 8, 12));

        header.add(left, BorderLayout.WEST);
        header.add(statusPill, BorderLayout.EAST);

        root.add(header, BorderLayout.NORTH);

        // ===== Center card =====
        RoundedPanel card = new RoundedPanel(theme.card, 18);
        card.setBorder(new EmptyBorder(18, 18, 18, 18));
        card.setLayout(new GridLayout(2, 1, 12, 12));

        btnServer = new GradientButton("Pornește server (8080)", theme.btnGradB1, theme.btnGradB2);
        btnClient = new GradientButton("Deschide client", theme.btnGradA1, theme.btnGradA2);

        btnServer.setFont(new Font("Segoe UI", Font.BOLD, 15));
        btnClient.setFont(new Font("Segoe UI", Font.BOLD, 15));

        btnServer.addActionListener(e -> toggleServer());
        btnClient.addActionListener(e -> openClient());

        card.add(btnServer);
        card.add(btnClient);

        root.add(card, BorderLayout.CENTER);

        setStatus("Oprit", new Color(255, 255, 255, 220), new Color(255, 255, 255, 40));
    }

    private void toggleServer() {
        if (server == null) {
            try {
                server = new ClientServer(DEFAULT_PORT);
                server.start();
                btnServer.setText("Oprește server (8080)");
                setStatus("Server pornit: ws://localhost:" + DEFAULT_PORT,
                        new Color(255, 255, 255, 235),
                        new Color(0, 0, 0, 60));
            } catch (Exception ex) {
                server = null;
                setStatus("Eroare pornire: " + ex.getMessage(),
                        new Color(255, 255, 255, 235),
                        new Color(0, 0, 0, 60));
            }
        } else {
            try { server.stop(1000); } catch (Exception ignored) {}
            server = null;
            btnServer.setText("Pornește server (8080)");
            setStatus("Oprit", new Color(255, 255, 255, 220), new Color(255, 255, 255, 40));
        }
    }

    private void openClient() {
        SwingUtilities.invokeLater(() -> new ChatClient("ws://localhost:" + DEFAULT_PORT).setVisible(true));
    }

    private void setStatus(String text, Color fg, Color bg) {
        statusPill.setText(text);
        statusPill.setForeground(fg);
        statusPill.setBackground(bg);
    }

    // ===== UI classes (same as ChatClient) =====

    private static final class Theme {
        final Color bg, card;
        final Color headerGrad1, headerGrad2;
        final Color btnGradA1, btnGradA2;
        final Color btnGradB1, btnGradB2;

        private Theme() {
            bg = new Color(246, 247, 251);
            card = Color.WHITE;

            headerGrad1 = new Color(123, 45, 255);
            headerGrad2 = new Color(45, 196, 255);

            btnGradA1 = new Color(255, 115, 90);
            btnGradA2 = new Color(255, 70, 145);

            btnGradB1 = new Color(45, 126, 255);
            btnGradB2 = new Color(0, 210, 255);
        }

        static Theme vibrant() { return new Theme(); }
    }

    private static final class RoundedPanel extends JPanel {
        private final Color bg;
        private final int radius;

        RoundedPanel(Color bg, int radius) {
            this.bg = bg;
            this.radius = radius;
            setOpaque(false);
        }

        @Override
        protected void paintComponent(Graphics g) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2.setColor(bg);
            g2.fillRoundRect(0, 0, getWidth(), getHeight(), radius, radius);
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

    private static final class GradientButton extends JButton {
        private final Color g1, g2;
        private boolean hover = false;
        private boolean press = false;

        GradientButton(String text, Color g1, Color g2) {
            super(text);
            this.g1 = g1;
            this.g2 = g2;

            setFont(new Font("Segoe UI", Font.BOLD, 13));
            setForeground(Color.WHITE);
            setFocusPainted(false);
            setBorder(new EmptyBorder(14, 18, 14, 18));
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

        @Override
        protected void paintComponent(Graphics g) {
            Graphics2D g2d = (Graphics2D) g.create();
            g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            Color a = g1, b = g2;
            if (hover) { a = brighten(a, 0.06f); b = brighten(b, 0.06f); }
            if (press) { a = darken(a, 0.08f); b = darken(b, 0.08f); }

            GradientPaint gp = new GradientPaint(0, 0, a, getWidth(), getHeight(), b);
            g2d.setPaint(gp);
            g2d.fillRoundRect(0, 0, getWidth(), getHeight(), 16, 16);

            g2d.dispose();
            super.paintComponent(g);
        }

        private static Color brighten(Color c, float k) {
            return new Color(
                    clamp((int)(c.getRed()   * (1f + k))),
                    clamp((int)(c.getGreen() * (1f + k))),
                    clamp((int)(c.getBlue()  * (1f + k)))
            );
        }

        private static Color darken(Color c, float k) {
            return new Color(
                    clamp((int)(c.getRed()   * (1f - k))),
                    clamp((int)(c.getGreen() * (1f - k))),
                    clamp((int)(c.getBlue()  * (1f - k)))
            );
        }

        private static int clamp(int v) { return Math.max(0, Math.min(255, v)); }
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new Launcher().setVisible(true));
    }
}
