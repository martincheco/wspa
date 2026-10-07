<?php
// Get the requested file
if (empty($_GET['file'])) {
    http_response_code(400);
    exit;
}
$filename = $_GET['file'];

// Check if the file exists
if (!file_exists($filename)) {
    http_response_code(404);
    echo "File not found.";
    exit;
}

$mtime = filemtime($filename);
$fsize = filesize($filename);
$hash = dechex($mtime) . '-' . dechex($fsize);

header("Content-Type: image/png");
header("Content-Length: " . $fsize);
header("Cache-Control: public, max-age=31536000, immutable");
header("Expires: " . gmdate("D, d M Y H:i:s", time() + 31536000) . " GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s", $mtime) . " GMT");
header("ETag: \"$hash\"");

// Respond with 304 Not Modified if ETag or If-Modified-Since matches
if (!empty($_SERVER['HTTP_IF_NONE_MATCH'])) {
    $inm = str_replace(array('W/', '"', ' '), '', $_SERVER['HTTP_IF_NONE_MATCH']);
    if ($inm === $hash) {
        http_response_code(304);
        exit;
    }
}
if (!empty($_SERVER['HTTP_IF_MODIFIED_SINCE']) && strtotime($_SERVER['HTTP_IF_MODIFIED_SINCE']) >= $mtime) {
    http_response_code(304);
    exit;
}

// Output the file cleanly
readfile($filename);

