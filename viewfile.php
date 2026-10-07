<?php
session_start();
require_once('globals.php');

$user = isset($_SESSION['user']) ? $_SESSION['user'] : 'admin';

if (!isset($_GET['file']) || trim($_GET['file']) === '') {
    header("HTTP/1.0 400 Bad Request");
    echo "Error: Missing file parameter.";
    exit;
}

$file_param = trim($_GET['file']);
$clean_file = str_replace('\\', '/', $file_param);

// Resolve path and check security bounds
$real_path = realpath($clean_file);
$data_root = realpath(__DIR__ . '/data');
$users_root = realpath(__DIR__ . '/users');

$allowed = false;
if ($real_path !== false) {
    if ($data_root !== false && strpos($real_path, $data_root) === 0) {
        $allowed = true;
    } else if ($users_root !== false && strpos($real_path, $users_root) === 0) {
        $allowed = true;
    }
}

if (!$allowed) {
    $rel = ltrim($clean_file, '/');
    if ((strpos($rel, 'data/') === 0 || strpos($rel, 'users/') === 0) && !preg_match('#\.\./#', $rel)) {
        $full_candidate = __DIR__ . '/' . $rel;
        if (file_exists($full_candidate)) {
            $allowed = true;
            $real_path = $full_candidate;
        }
    }
}

if (!$allowed || !file_exists($real_path) || !is_file($real_path)) {
    header("HTTP/1.0 404 Not Found");
    echo "Error: File not found or access denied.";
    exit;
}

$filename = basename($real_path);
$ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));

// Clean output buffer before sending file
if (ob_get_level()) {
    ob_end_clean();
}

// 1. Text & Scientific Data Formats (defined in globals.php) -> Display inline as text
if (is_text_extension($filename)) {
    header("Content-Type: text/plain; charset=utf-8");
    header("X-Content-Type-Options: nosniff");
    header("Content-Disposition: inline; filename=\"" . rawurlencode($filename) . "\"");
    
    $content = file_get_contents($real_path);
    if ($content !== false && strpos($content, "\0") !== false) {
        $content = str_replace("\0", " ", $content);
    }
    if ($content === false) {
        $content = "";
    }
    header("Content-Length: " . strlen($content));
    echo $content;
    exit;
}

// 2. Standard Image Formats -> Display inline as image
$img_mimes = array(
    'png'  => 'image/png',
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'gif'  => 'image/gif',
    'svg'  => 'image/svg+xml',
    'webp' => 'image/webp',
    'bmp'  => 'image/bmp',
    'ico'  => 'image/x-icon'
);

if (isset($img_mimes[$ext])) {
    header("Content-Type: " . $img_mimes[$ext]);
    header("Content-Disposition: inline; filename=\"" . rawurlencode($filename) . "\"");
    header("Content-Length: " . filesize($real_path));
    readfile($real_path);
    exit;
}

// 3. PDF Documents -> Display inline
if ($ext === 'pdf') {
    header("Content-Type: application/pdf");
    header("Content-Disposition: inline; filename=\"" . rawurlencode($filename) . "\"");
    header("Content-Length: " . filesize($real_path));
    readfile($real_path);
    exit;
}

// 4. Binary & Non-readable Formats (.docx, .odt, .xls, .xlsx, .zip, .tar.gz, etc.) -> Attachment download
header("Content-Type: application/octet-stream");
header("Content-Disposition: attachment; filename=\"" . rawurlencode($filename) . "\"");
header("Content-Length: " . filesize($real_path));
readfile($real_path);
exit;
