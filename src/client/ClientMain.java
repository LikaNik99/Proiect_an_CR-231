package client;

import javax.swing.*;

public class ClientMain {
    public static void main(String[] args) {
        System.out.println("""
            ===========================================
                  FORUM APP CLIENT - UTM FCIM
                  Autor: Buga Pavel - CR-231
            =========================================== 
            """);

        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception e) {
                e.printStackTrace();
            }

            ClientGUI client = new ClientGUI();
            client.setVisible(true);
        });
    }
}