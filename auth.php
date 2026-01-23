<?php
session_start();
header('Content-Type: application/json');

try {
    $pdo = new PDO("mysql:host=localhost;dbname=quizon;charset=utf8", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Eroare DB']); exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$user = $input['username'] ?? '';
$pass = $input['password'] ?? '';

$stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
$stmt->execute([$user]);
$userData = $stmt->fetch(PDO::FETCH_ASSOC);

if ($userData && password_verify($pass, $userData['password'])) {
    $_SESSION['user'] = $userData['username'];
    $_SESSION['role'] = $userData['role'];
    echo json_encode(['success' => true, 'role' => $userData['role']]);
} else {
    echo json_encode(['success' => false, 'message' => 'Utilizator sau parolă incorectă!']);
}