<?php
session_start();
require_once('globals.php');

$user = isset($_SESSION['user']) ? $_SESSION['user'] : 'admin';

if (!isset($_GET['file']) || trim($_GET['file']) === '') {
    header("HTTP/1.0 400 Bad Request");
    echo "Error: Missing file parameter.";
    exit;
}

$file_param = trim($_GET['file'], "\r\n\t\0\x0B");

$wspa_root = __DIR__;
$data_root = realpath($wspa_root . '/data');
$users_root = realpath($wspa_root . '/users');

$candidate_paths = array($file_param);
$normalized_file = str_replace('\\', '/', $file_param);
if ($normalized_file !== $file_param) {
    $candidate_paths[] = $normalized_file;
}

$real_path = false;
$allowed = false;

foreach ($candidate_paths as $cand) {
    // 1. Direct path relative to wspa root under data/ or users/
    $rel = ltrim($cand, '/');
    if ((strpos($rel, 'data/') === 0 || strpos($rel, 'users/') === 0) && !preg_match('#\.\./#', $rel)) {
        $full_candidate = $wspa_root . '/' . $rel;
        if (file_exists($full_candidate) && is_file($full_candidate)) {
            $allowed = true;
            $real_path = $full_candidate;
            break;
        }
    }

    // 2. Realpath check within data_root or users_root
    $resolved = realpath($cand);
    if ($resolved !== false && is_file($resolved)) {
        if (($data_root !== false && strpos($resolved, $data_root) === 0) ||
            ($users_root !== false && strpos($resolved, $users_root) === 0)) {
            $allowed = true;
            $real_path = $resolved;
            break;
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
