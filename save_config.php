<?php
require_once('auth.php');
require_once('globals.php');

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = $_POST;
    if (empty($data)) {
        $raw = file_get_contents('php://input');
        $json = json_decode($raw, true);
        if (is_array($json)) {
            $data = $json;
        }
    }
    
    $res = save_user_config($data, $user);
    echo json_encode(array('success' => $res));
    exit;
}

echo json_encode(array('success' => false, 'error' => 'Invalid request method'));
exit;
