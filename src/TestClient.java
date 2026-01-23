import java.io.*;
import java.net.*;

public class TestClient {
    public static void main(String[] args) throws IOException {
        System.out.println("🧪 Test Client pentru Tweets App");

        Socket socket = new Socket("localhost", 12345);
        BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        PrintWriter out = new PrintWriter(socket.getOutputStream(), true);

        // Citește mesajul de bun venit
        String line;
        while ((line = in.readLine()) != null) {
            System.out.println("Server: " + line);
            if (line.contains("autentificare")) break;
        }

        // Trimite login
        out.println("LOGIN:student:student123");
        System.out.println("Am trimis: LOGIN:student:student123");

        // Citește răspuns
        String response = in.readLine();
        System.out.println("Răspuns login: " + response);

        if (response != null && response.startsWith("SUCCESS")) {
            // Trimite un mesaj
            out.println("Salutare de la test client!");
            System.out.println("Am trimis mesaj de test");

            // Citește echo
            String echo = in.readLine();
            System.out.println("Echo: " + echo);
        }

        socket.close();
    }
}