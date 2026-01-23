package client;

import java.io.*;
import java.net.*;
import java.util.Scanner;

public class ClientMain {
    public static void main(String[] args) {
        try (Socket socket = new Socket("localhost", 1234)) {
            ObjectOutputStream out = new ObjectOutputStream(socket.getOutputStream());
            ObjectInputStream in = new ObjectInputStream(socket.getInputStream());
            Scanner sc = new Scanner(System.in);

            System.out.println((String) in.readObject());

            while (true) {
                System.out.print("Comandă (HIT/STAND/NEW): ");
                String cmd = sc.nextLine();
                out.writeObject(cmd);
                String resp = (String) in.readObject();
                System.out.println("Server: " + resp);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
