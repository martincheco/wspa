<?php
if (empty($_GET['file'])) {
    http_response_code(400);
    exit;
}
$filename = $_GET['file'];

// Check if this is a transient workspace image (e.g. tmp0.png, scl1.png, hist0.png)
$is_workspace_file = (preg_match('/(tmp|scl|hist)\d*\.png$/', $filename) === 1);

// Helper to verify a PNG file is completely written (ends with PNG IEND chunk)
function is_png_complete($path) {
    if (!file_exists($path)) return false;
    $sz = @filesize($path);
    if (!$sz || $sz < 12) return false;
    $fp = @fopen($path, 'rb');
    if (!$fp) return false;
    if (fseek($fp, -12, SEEK_END) !== 0) {
        fclose($fp);
        return false;
    }
    $tail = fread($fp, 12);
    fclose($fp);
    return (strpos($tail, 'IEND') !== false);
}

// If transient workspace image, wait briefly for GDL/process completion if missing or writing
if ($is_workspace_file) {
    $waited = 0;
    while (!is_png_complete($filename) && $waited < 250) { // wait up to 5 seconds (250 * 20ms)
        clearstatcache(true, $filename);
        usleep(20000); // 20ms
        $waited++;
    }
}

if (!file_exists($filename) || ($is_workspace_file && !is_png_complete($filename))) {
    header("Cache-Control: no-store, no-cache, must-revalidate");
    header("Pragma: no-cache");
    http_response_code(404);
    exit;
}

clearstatcache(true, $filename);
$mtime = filemtime($filename);
$fsize = filesize($filename);

require_once('globals.php');
$real_path = realpath($filename);

$target_user = null;
if (preg_match('#(?:users|users_link)/([^/]+)/#', $filename, $um)) {
    $target_user = $um[1];
}
$ds_token = get_dataset_token($target_user);
$etag = md5(($real_path ?: $filename) . '|' . $fsize . '|' . $mtime . '|' . $ds_token);

header("Content-Type: image/png");
header("Last-Modified: " . gmdate("D, d M Y H:i:s", $mtime) . " GMT");

if ($is_workspace_file) {
    // Transient workspace images must NEVER be stored by browser across reloads or dataset switches
    header("Cache-Control: private, no-cache, no-store, must-revalidate");
    header("Pragma: no-cache");
    header("Expires: 0");
} elseif (!empty($_GET['v'])) {
    // Immutable pre-rendered process images can be cached long-term
    header("Cache-Control: private, max-age=86400");
    header("ETag: \"$etag\"");

    $inm = !empty($_SERVER['HTTP_IF_NONE_MATCH']) ? str_replace(array('W/', '"', ' '), '', $_SERVER['HTTP_IF_NONE_MATCH']) : '';
    if ($inm !== '' && $inm === $etag) {
        http_response_code(304);
        header_remove('Content-Type');
        exit;
    }

    if (!empty($_SERVER['HTTP_IF_MODIFIED_SINCE']) && strtotime($_SERVER['HTTP_IF_MODIFIED_SINCE']) >= $mtime) {
        http_response_code(304);
        header_remove('Content-Type');
        exit;
    }
} else {
    header("Cache-Control: no-cache, must-revalidate");
    header("Pragma: no-cache");
}

// Cleanly discard all active output buffers before binary streaming
while (ob_get_level()) {
    ob_end_clean();
}

readfile($filename);
exit;
