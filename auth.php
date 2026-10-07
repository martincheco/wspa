<?php

/**
 * Clean and normalize POSIX paths for WSPA
 * Prevents duplicated data/data/ paths and handles spaces, tildes (~), and special characters.
 */
function normalize_wspa_path($raw_path) {
    $path = str_replace('\\', '/', $raw_path);
    $parts = explode('/', $path);
    $clean_parts = array();
    
    foreach ($parts as $part) {
        if ($part === '' || $part === '.') {
            continue;
        }
        if ($part === '..') {
            array_pop($clean_parts);
        } else {
            if ($part === 'data' && !empty($clean_parts) && $clean_parts[0] === 'data') {
                continue;
            }
            $clean_parts[] = $part;
        }
    }
    
    if (empty($clean_parts) || (count($clean_parts) === 1 && $clean_parts[0] === 'data')) {
        return 'data/';
    }
    
    if ($clean_parts[0] !== 'data') {
        array_unshift($clean_parts, 'data');
    }
    
    return implode('/', $clean_parts);
}

session_start();
session_regenerate_id();

if (!isset($_SESSION['user'])) {
    session_write_close();
    header("Location: cred.php");
    exit;
} else {
    $user = $_SESSION['user'];
}

$datadir = isset($datadir) ? $datadir : "data/";

if (isset($_GET['path'])) {
    $req_path = normalize_wspa_path($_GET['path']);
    
    while (!is_dir($req_path) && $req_path !== 'data/' && $req_path !== '' && $req_path !== '.') {
        $parent = dirname($req_path);
        if ($parent === $req_path) break;
        $req_path = $parent;
    }
    
    if (!is_dir($req_path)) {
        $req_path = $datadir;
    }
    
    $path = $req_path;
    $_SESSION['path'] = $path;
} else if (isset($_SESSION['path'])) {
    $path = normalize_wspa_path($_SESSION['path']);
} else {
    $path = $datadir;
}

if ($path === '' || $path === '.') {
    $path = $datadir;
}

$rights = "w";
$_SESSION['rights'] = $rights;

session_write_close();

?>
