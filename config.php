<?php
// Conexiune pentru MySQL (XAMPP)
$host = 'localhost';
$db   = 'quizon'; // Numele bazei create în phpMyAdmin
$user = 'root';   // Utilizatorul standard XAMPP
$pass = '';       // Parola standard XAMPP (gol)

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Eroare de conexiune: " . $e->getMessage());
}
?>