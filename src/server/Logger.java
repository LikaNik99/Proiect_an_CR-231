package server;

import java.io.*;
import java.text.SimpleDateFormat;
import java.util.Date;

public class Logger {
    private PrintWriter writer;
    private String currentLogFile;
    private final SimpleDateFormat dateFormat = new SimpleDateFormat("dd.MM.yyyy");
    private final SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm:ss");

    public Logger() {
        openLogFile();
    }

    private void openLogFile() {
        try {
            String dateStr = dateFormat.format(new Date());
            currentLogFile = "logs/server_" + dateStr + ".log";

            // Create logs directory if it doesn't exist
            File logsDir = new File("logs");
            if (!logsDir.exists()) {
                logsDir.mkdirs();
            }

            // Open file in append mode
            writer = new PrintWriter(new FileWriter(currentLogFile, true), true);
            log("📁 Log file opened: " + currentLogFile);
        } catch (IOException e) {
            System.err.println("❌ Error opening log file: " + e.getMessage());
            // Fallback to console
            writer = new PrintWriter(System.out, true);
        }
    }

    public void log(String message) {
        String timestamp = timeFormat.format(new Date());
        String logMessage = "[" + timestamp + "] " + message;

        writer.println(logMessage);
        System.out.println(logMessage);
    }

    public void error(String message) {
        String timestamp = timeFormat.format(new Date());
        String logMessage = "[" + timestamp + "] ❌ ERROR: " + message;

        writer.println(logMessage);
        System.err.println(logMessage);
    }

    public void warn(String message) {
        String timestamp = timeFormat.format(new Date());
        String logMessage = "[" + timestamp + "] ⚠️ WARN: " + message;

        writer.println(logMessage);
        System.out.println(logMessage);
    }

    public void info(String message) {
        String timestamp = timeFormat.format(new Date());
        String logMessage = "[" + timestamp + "] ℹ️ INFO: " + message;

        writer.println(logMessage);
        System.out.println(logMessage);
    }

    public void rotateIfNeeded() {
        String newDateStr = dateFormat.format(new Date());
        String currentDateStr = currentLogFile.substring(
                currentLogFile.lastIndexOf("_") + 1,
                currentLogFile.lastIndexOf(".")
        );

        if (!newDateStr.equals(currentDateStr)) {
            close();
            openLogFile();
        }
    }

    public void close() {
        if (writer != null) {
            log("📁 Closing log file");
            writer.close();
        }
    }

    public String getCurrentLogFile() {
        return currentLogFile;
    }
}