<?php
session_start();
header('Content-Type: application/json');
$pdo = new PDO("mysql:host=localhost;dbname=quizon;charset=utf8", "root", "");

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

switch ($action) {
    case 'register':
        $u = trim($input['user']); $p = trim($input['pass']); $r = $input['role'];
        $hashed = password_hash($p, PASSWORD_DEFAULT);
        try {
            $stmt = $pdo->prepare("INSERT INTO users (username, password, role) VALUES (?, ?, ?)");
            $stmt->execute([$u, $hashed, $r]);
            echo json_encode(['success' => true]);
        } catch (Exception $e) { echo json_encode(['success' => false, 'error' => 'Utilizator existent!']); }
        break;

    case 'login':
        $u = trim($input['user']); $p = trim($input['pass']);
        $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
        $stmt->execute([$u]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$user || !password_verify($p, $user['password'])) {
            echo json_encode(['success' => false, 'error' => 'Date incorecte!']);
        } else {
            $_SESSION['user'] = $user['username'];
            $_SESSION['role'] = $user['role'];
            echo json_encode(['success' => true, 'role' => $user['role']]);
        }
        break;

    case 'check_and_get_questions':
        $code = $input['testCode']; $user = $_SESSION['user'];
        $stmtCheck = $pdo->prepare("SELECT id FROM results WHERE student_name = ? AND test_code = ?");
        $stmtCheck->execute([$user, $code]);
        if ($stmtCheck->fetch()) {
            echo json_encode(['success' => false, 'error' => 'Ai susținut deja acest test!']);
            break;
        }
        $stmt = $pdo->prepare("SELECT * FROM questions WHERE test_code = ?");
        $stmt->execute([$code]);
        $qs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (count($qs) > 0) echo json_encode(['success' => true, 'questions' => $qs]);
        else echo json_encode(['success' => false, 'error' => 'Cod invalid sau test gol.']);
        break;

    case 'get_student_results':
        $stmt = $pdo->prepare("SELECT * FROM results WHERE student_name = ? ORDER BY date_taken DESC");
        $stmt->execute([$_SESSION['user']]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        break;

    case 'submit_score':
        $sql = "INSERT INTO results (student_name, test_code, test_name, score, total) VALUES (?, ?, ?, ?, ?)";
        $pdo->prepare($sql)->execute([$_SESSION['user'], $input['testCode'], $input['testName'], $input['score'], $input['total']]);
        echo json_encode(['success' => true]);
        break;

    case 'save_question':
        $sql = "INSERT INTO questions (test_code, test_name, text, a, b, c, correct) VALUES (?, ?, ?, ?, ?, ?, ?)";
        $pdo->prepare($sql)->execute([$input['testCode'], $input['testName'], $input['text'], $input['a'], $input['b'], $input['c'], $input['correct']]);
        echo json_encode(['success' => true]);
        break;

    case 'get_all_results':
        $stmt = $pdo->query("SELECT * FROM results ORDER BY date_taken DESC");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        break;

    case 'get_my_tests':
        $stmt = $pdo->query("SELECT test_code, test_name, COUNT(*) as nr FROM questions GROUP BY test_code");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        break;

    case 'delete_test':
        $pdo->prepare("DELETE FROM questions WHERE test_code = ?")->execute([$input['testCode']]);
        $pdo->prepare("DELETE FROM results WHERE test_code = ?")->execute([$input['testCode']]);
        echo json_encode(['success' => true]);
        break;
}