<?php

// System-wide configuration variables

$origuserdir = "users/";
$shm = "/run/shm/wspa/";
// Location of shared memory filesystem (tmpfs in fstab). Put $shm="" if you run into troubles.

$userdir = $shm . $origuserdir;
$userlink = "users_link/";
$datadir = "data/";
$readystring = "READY\n"; // GDL sends this to announce finish of loading
$failstring = 'Execution halted';
$qout = 1; // Quickview default timeout in seconds (reload rate for launcher)
$qtout = 20; // Timeout for quickview actions
$maxw = 400; // Quickview max image size
$maxh = 400;

$help_default = false;
$sts_default = true;

function is_wspa_localdir($data_path) {
    $clean_path = str_replace('\\', '/', $data_path);
    $dir = is_dir($clean_path) ? $clean_path : dirname($clean_path);
    
    while ($dir !== '' && $dir !== '.' && $dir !== '/') {
        if (file_exists($dir . '/.wspa_localdir')) {
            return true;
        }
        $parent = dirname($dir);
        if ($parent === $dir || $parent === 'data') break;
        $dir = $parent;
    }
    return false;
}

function has_direct_wspa_localdir($data_path) {
    $clean_path = str_replace('\\', '/', $data_path);
    $dir = is_dir($clean_path) ? $clean_path : dirname($clean_path);
    return file_exists(rtrim($dir, '/') . '/.wspa_localdir');
}

/**
 * Dual-Mode Metadata Resolver
 * Mode A (In-Situ): For local folders containing .wspa_localdir marker.
 * Mode B (Shadow): For shared read-only instrument datasets (users/<user>/shadow/<data_path>/).
 */
function get_meta_dir($data_path, $user = null) {
    if ($user === null && isset($_SESSION['user'])) {
        $user = $_SESSION['user'];
    }
    if ($user === null) {
        $user = 'admin';
    }
    
    $clean_path = str_replace('\\', '/', $data_path);
    
    // Mode A: In-Situ for local data folders containing .wspa_localdir marker
    if (is_wspa_localdir($clean_path)) {
        return $clean_path;
    }
    
    // Mode B: Shadow Storage for shared read-only datasets
    $data_root = "data/";
    if (strpos($clean_path, $data_root) === 0) {
        $rel_path = substr($clean_path, strlen($data_root));
    } else {
        $rel_path = ltrim($clean_path, '/');
    }
    
    return "users/" . $user . "/shadow/" . $rel_path;
}

/**
 * Resolves metadata file path for a given data file
 */
function get_meta_path_for_file($data_file_path, $ext = '', $user = null) {
    $dir = dirname($data_file_path);
    $base = basename($data_file_path);
    $meta_dir = get_meta_dir($dir, $user);
    
    if ($ext !== '') {
        return $meta_dir . '/' . $base . '.' . $ext;
    }
    return $meta_dir . '/' . $base;
}

/**
 * Sends a socket request to the GDL Session Manager Daemon
 */
function gdl_session_request($action, $params = array()) {
    $params['action'] = $action;
    $sock_paths = array("/run/wspa/gdl_manager.sock", "/tmp/gdl_manager.sock");
    
    $sock = null;
    foreach ($sock_paths as $sp) {
        if (file_exists($sp)) {
            $sock = @fsockopen("unix://" . $sp, -1, $errno, $errstr, 2);
            if ($sock) break;
        }
    }
    
    if (!$sock) {
        return false; // Daemon socket not running, fallback to local exec
    }
    
    fwrite($sock, json_encode($params));
    $response = "";
    while (!feof($sock)) {
        $response .= fgets($sock, 1024);
    }
    fclose($sock);
    
    return json_decode($response, true);
}

/**
 * Calculates directory depth relative to data root.
 * depth 0: data/
 * depth 1: data/somedata/, data/mydata/ (sacred containers, no project assignment allowed)
 * depth 2: data/somedata/ZnPc-maps/, data/mydata/exp1/ (dataset folders, project assignment level!)
 * depth 3+: subfolders (inherit project allegiance from depth 2 anchor)
 */
function get_path_depth($data_path) {
    $clean = trim(str_replace('\\', '/', $data_path), '/');
    if ($clean === '' || $clean === 'data') return 0;
    if (strpos($clean, 'data/') === 0) {
        $clean = substr($clean, 5);
    }
    $parts = array_filter(explode('/', $clean), 'strlen');
    return count($parts);
}

/**
 * Determines the project anchor directory for any data path.
 * Both raw and local folders anchor strictly at Level 2 (e.g. data/somedata/ZnPc-maps/ or data/mydata/exp1/).
 * Returns null for depth < 2.
 */
function get_project_anchor_dir($data_path) {
    $clean = trim(str_replace('\\', '/', $data_path), '/');
    if ($clean === '' || $clean === 'data') return null;
    
    if (strpos($clean, 'data/') === 0) {
        $rel = substr($clean, 5);
    } else {
        $rel = $clean;
    }
    
    $parts = array_values(array_filter(explode('/', $rel), 'strlen'));
    $depth = count($parts);
    
    if ($depth >= 2) {
        return 'data/' . $parts[0] . '/' . $parts[1] . '/';
    }
    return null;
}

/**
 * Checks whether a directory is eligible to have .project set directly on it.
 * Strictly depth 2 for all folders (raw and local).
 */
function is_project_assignable_dir($data_path) {
    return (get_path_depth($data_path) === 2);
}

/**
 * Resolves project name for a given data path via its Level 2 anchor directory.
 * Checks local in-situ .project file first (for local data), then user shadow .project file.
 */
function get_project_for_dir($data_path, $user = null) {
    $anchor = get_project_anchor_dir($data_path);
    if ($anchor === null) {
        return null;
    }
    
    if ($user === null && isset($_SESSION['user'])) {
        $user = $_SESSION['user'];
    }
    if ($user === null) {
        $user = 'admin';
    }
    
    $clean_anchor = rtrim(str_replace('\\', '/', $anchor), '/');
    
    // 1. Check direct local in-situ directory first
    $local_proj = $clean_anchor . '/.project';
    if (file_exists($local_proj)) {
        $content = trim(@file_get_contents($local_proj));
        if ($content !== '') {
            return $content;
        }
    }
    
    // 2. Check shadow directory
    $rel_path = ltrim(substr($clean_anchor, 4), '/');
    $shadow_proj = "users/" . $user . "/shadow/" . $rel_path . '/.project';
    if (file_exists($shadow_proj)) {
        $content = trim(@file_get_contents($shadow_proj));
        if ($content !== '') {
            return $content;
        }
    }
    
    return null;
}

/**
 * Assigns a data directory to a project by writing .project into its Level 2 anchor directory.
 * Writes directly to local dataset folder if local (Mode A), falling back to shadow storage.
 */
function set_project_for_dir($data_path, $project_name, $user = null) {
    if (!is_project_assignable_dir($data_path)) {
        return false;
    }
    
    if ($user === null && isset($_SESSION['user'])) {
        $user = $_SESSION['user'];
    }
    if ($user === null) {
        $user = 'admin';
    }
    
    $project_name = trim($project_name);
    $meta_dir = get_meta_dir($data_path, $user);
    
    if (!file_exists($meta_dir)) {
        @mkdir($meta_dir, 0775, true);
        @chown($meta_dir, 'martin');
        @chgrp($meta_dir, 'www-data');
        @chmod($meta_dir, 0775);
    }
    
    $proj_file = rtrim($meta_dir, '/') . '/.project';
    if ($project_name === '') {
        if (file_exists($proj_file)) {
            @unlink($proj_file);
        }
        $shadow_dir = "users/" . $user . "/shadow/" . ltrim(substr(rtrim($data_path, '/'), 4), '/');
        $shadow_proj = $shadow_dir . '/.project';
        if (file_exists($shadow_proj)) {
            @unlink($shadow_proj);
        }
        return true;
    }
    
    $res = @file_put_contents($proj_file, $project_name . "\n");
    if ($res === false && is_wspa_localdir($data_path)) {
        $shadow_dir = "users/" . $user . "/shadow/" . ltrim(substr(rtrim($data_path, '/'), 4), '/');
        if (!file_exists($shadow_dir)) {
            @mkdir($shadow_dir, 0775, true);
            @chown($shadow_dir, 'martin');
            @chgrp($shadow_dir, 'www-data');
            @chmod($shadow_dir, 0775);
        }
        $shadow_proj = $shadow_dir . '/.project';
        $res = @file_put_contents($shadow_proj, $project_name . "\n");
        if ($res !== false) {
            @chown($shadow_proj, 'martin');
            @chgrp($shadow_proj, 'www-data');
            @chmod($shadow_proj, 0775);
            return true;
        }
    } else if ($res !== false) {
        @chown($proj_file, 'martin');
        @chgrp($proj_file, 'www-data');
        @chmod($proj_file, 0775);
        return true;
    }
    return false;
}

/**
 * Scans shadow and local directories for user and returns a list of unique named projects
 * mapped to their Level 2 anchor data directories.
 */
function list_user_projects($user = null) {
    if ($user === null && isset($_SESSION['user'])) {
        $user = $_SESSION['user'];
    }
    if ($user === null) {
        $user = 'admin';
    }
    
    $projects = array();
    $candidate_dirs = array();
    
    // 1. Scan shadow directories for Level 2 .project files
    $shadow_root = "users/" . $user . "/shadow/";
    $shadow_files = glob($shadow_root . "*/*/.project");
    if ($shadow_files) {
        foreach ($shadow_files as $sf) {
            $dir_path = dirname($sf);
            $rel = substr($dir_path, strlen($shadow_root));
            $data_path = 'data/' . ltrim($rel, '/') . '/';
            $anchor = get_project_anchor_dir($data_path);
            if ($anchor !== null) {
                $candidate_dirs[$anchor] = true;
            }
        }
    }
    
    // 2. Scan local data directories for Level 2 in-situ .project files
    $local_files = glob("data/*/*/.project");
    if ($local_files) {
        foreach ($local_files as $lf) {
            $dir_path = dirname($lf);
            $clean_dpath = rtrim(str_replace('\\', '/', $dir_path), '/') . '/';
            $anchor = get_project_anchor_dir($clean_dpath);
            if ($anchor !== null) {
                $candidate_dirs[$anchor] = true;
            }
        }
    }
    
    foreach (array_keys($candidate_dirs) as $dpath) {
        $pname = get_project_for_dir($dpath, $user);
        if (!empty($pname) && $pname !== 'DEFAULT') {
            if (!isset($projects[$pname])) {
                $projects[$pname] = array();
            }
            if (!in_array($dpath, $projects[$pname])) {
                $projects[$pname][] = $dpath;
            }
        }
    }
    
    ksort($projects);
    return $projects;
}

/**
 * Maps a project name deterministically to a distinct vibrant background color.
 */
function get_project_color($project_name, $idx = null) {
    if (empty($project_name) || strtolower($project_name) === 'default') {
        return '#666666';
    }
    $palette = array(
        '#26a69a', // Teal
        '#ab47bc', // Purple
        '#ff7043', // Deep Orange
        '#42a5f5', // Blue
        '#ec407a', // Pink
        '#5c6bc0', // Indigo
        '#ffb74d', // Amber / Warm Orange
        '#7e57c2', // Deep Purple
        '#26c6da', // Cyan
        '#8d6e63', // Brown / Maroon
        '#66bb6a', // Green
        '#ef5350'  // Red
    );
    if ($idx !== null) {
        return $palette[$idx % count($palette)];
    }
    $hash = abs(crc32($project_name));
    return $palette[$hash % count($palette)];
}

/**
 * Maps a project name deterministically to a lighter hover background color.
 */
function get_project_color_hover($project_name, $idx = null) {
    if (empty($project_name) || strtolower($project_name) === 'default') {
        return '#888888';
    }
    $palette_hover = array(
        '#80cbc4', // Lighter Teal
        '#ce93d8', // Lighter Purple
        '#ffab91', // Lighter Deep Orange
        '#90caf9', // Lighter Blue
        '#f48fb1', // Lighter Pink
        '#9fa8da', // Lighter Indigo
        '#ffe082', // Lighter Amber
        '#b39ddb', // Lighter Deep Purple
        '#80deea', // Lighter Cyan
        '#bcaaa4', // Lighter Brown / Maroon
        '#a5d6a7', // Lighter Green
        '#ef9a9a'  // Lighter Red
    );
    if ($idx !== null) {
        return $palette_hover[$idx % count($palette_hover)];
    }
    $hash = abs(crc32($project_name));
    return $palette_hover[$hash % count($palette_hover)];
}

/**
 * Determines real folder writability by the web server / PHP process.
 * Returns 'RW' if writable by PHP, otherwise 'RO'.
 */
function get_folder_rights($folder_path) {
    $clean_path = str_replace('\\', '/', $folder_path);
    $dir = is_dir($clean_path) ? $clean_path : dirname($clean_path);
    if (file_exists($dir) && is_writable($dir)) {
        return 'RW';
    }
    return 'RO';
}

/**
 * Renders HTML badge for folder rights (RO or RW).
 */
function render_rights_badge($folder_path, $user = 'admin') {
    $right = get_folder_rights($folder_path, $user);
    if ($right === 'RW') {
        return '<span class="badge-rw" title="Read-Write directory (writable)">RW</span>';
    } else {
        return '<span class="badge-ro" title="Read-Only directory">RO</span>';
    }
}

/**
 * Returns an array of file extensions that should be displayed as plain text in browser.
 */
function get_text_extensions() {
    return array(
        // SPM and Scientific data formats
        'sxm', 'def', 'par', 'dat', 'out', 'nc', 'top', 'ch0', 'ch1', 'ch2', 
        '3ds', 'matrix', 'vp', 'fws', 'spm', 'upx', 'spec', 'cur', 'iv', 'flt', 'map', 'stp',
        // Code and configuration text formats
        'txt', 'csv', 'tsv', 'log', 'ini', 'conf', 'cfg', 'json', 'xml', 
        'yaml', 'yml', 'md', 'py', 'sh', 'bash', 'c', 'h', 'cpp', 'hpp', 
        'php', 'js', 'html', 'css', 'sql', 'diff', 'patch', 'env', 'lst'
    );
}

/**
 * Checks whether a file extension should be displayed as plain text in browser.
 */
function is_text_extension($filename) {
    $base = trim(basename($filename));
    if (strpos($base, '.') === 0) {
        return true; // Any dotfile (.project, .wspa_local, .wspa_shadow, .gitignore, etc.)
    }
    $ext = strtolower(pathinfo($base, PATHINFO_EXTENSION));
    if ($ext === 'project' || strpos($ext, 'wspa_') === 0) {
        return true;
    }
    return in_array($ext, get_text_extensions());
}

/**
 * Encodes a file or directory path for use in URL query parameters while preserving slashes '/' for human readability.
 */
function urlencode_path($path) {
    if (empty($path)) return '';
    $segments = explode('/', $path);
    $encoded = array();
    foreach ($segments as $segment) {
        $encoded[] = rawurlencode($segment);
    }
    return implode('/', $encoded);
}

/**
 * Returns path to <username>.cfg file for user
 */
function get_user_config_file($user = null) {
    if ($user === null && isset($_SESSION['user'])) {
        $user = $_SESSION['user'];
    }
    if ($user === null) {
        $user = 'admin';
    }
    return "users/" . $user . "/" . $user . ".cfg";
}

/**
 * Reads user configuration from <username>.cfg into associative array
 */
function read_user_config($user = null) {
    $cfg_file = get_user_config_file($user);
    $config = array();
    if (file_exists($cfg_file)) {
        $lines = file($cfg_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        if ($lines !== false) {
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '' || strpos($line, '#') === 0 || strpos($line, ';') === 0) continue;
                $parts = explode('=', $line, 2);
                if (count($parts) === 2) {
                    $config[trim($parts[0])] = trim($parts[1]);
                }
            }
        }
    }
    return $config;
}

/**
 * Merges and saves data into <username>.cfg file for user
 */
function save_user_config($data = array(), $user = null) {
    $cfg_file = get_user_config_file($user);
    $dir = dirname($cfg_file);
    if (!is_dir($dir)) {
        @mkdir($dir, 0775, true);
    }
    $current = read_user_config($user);
    foreach ($data as $k => $v) {
        $k_clean = trim((string)$k);
        if ($k_clean !== '') {
            $current[$k_clean] = trim((string)$v);
        }
    }
    $lines = array();
    foreach ($current as $k => $v) {
        $lines[] = $k . "=" . $v;
    }
    $res = @file_put_contents($cfg_file, implode("\n", $lines) . "\n");
    if ($res !== false) {
        @chown($cfg_file, 'martin');
        @chgrp($cfg_file, 'www-data');
        @chmod($cfg_file, 0664);
        return true;
    }
    return false;
}

/**
 * Resolves process cache directory for a data path
 */
function get_process_dir($data_path, $has_custom_filter = false, $user = null) {
    if ($user === null && isset($_SESSION['user'])) $user = $_SESSION['user'];
    if ($user === null) $user = 'admin';

    $clean_path = is_dir($data_path) ? $data_path : dirname($data_path);
    $clean_path = str_replace('\\', '/', $clean_path);

    if ($has_custom_filter && !is_wspa_localdir($clean_path)) {
        return get_meta_dir($clean_path, $user) . '/process';
    }
    return rtrim($clean_path, '/') . '/process';
}

/**
 * Cleanly wipes active session state files while strictly preserving mylist.lst
 */
function wipe_user_session_dir($userdir, $user) {
    $user_ws = rtrim($userdir, '/') . '/' . $user . '/';
    if (!is_dir($user_ws)) return;

    $files_to_remove = [
        'chan.dat', 'acqchan.dat', 'imgoffs.dat',
        'tmp.dat', 'tmp.flt', 'tmp.plt', 'tmp.png', 'scl.png',
        'gdl.log', 'main_launcher.log'
    ];
    foreach ($files_to_remove as $f) {
        $file_path = $user_ws . $f;
        if (file_exists($file_path) || is_link($file_path)) @unlink($file_path);
    }

    $glob_patterns = ['tmp*.png', 'scl*.png', 'hist*.png', 'p*.png', 'p*.dat'];
    foreach ($glob_patterns as $pat) {
        $matches = glob($user_ws . $pat);
        if ($matches) {
            foreach ($matches as $m) {
                if (file_exists($m) || is_link($m)) @unlink($m);
            }
        }
    }
}

/**
 * Populates tmp<N>.png workspace symlinks from process/ cache using active workspace chan.dat
 */
function populate_workspace_tmp_links($data_path, $userdir, $user) {
    $user_ws = rtrim($userdir, '/') . '/' . $user . '/';
    $chan_path = $user_ws . 'chan.dat';
    if (!file_exists($chan_path)) return;

    $lines = file($chan_path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $idx => $line) {
        $parts = explode(';', trim($line));
        if (count($parts) >= 3 && is_numeric(trim($parts[0]))) {
            $c_idx = intval(trim($parts[0]));
            $raw_file = trim($parts[1]);
        } else {
            $c_idx = $idx;
            $raw_file = trim($line);
        }
        if (empty($raw_file)) continue;

        $png_name = basename($raw_file) . '.png';
        $full_raw = rtrim($data_path, '/') . '/' . ltrim($raw_file, '/');
        $flt_file = get_meta_path_for_file($full_raw, 'flt', $user);
        $has_custom_filter = file_exists($flt_file) && filesize($flt_file) > 0;

        $proc_dir = get_process_dir($full_raw, $has_custom_filter, $user);
        $cached_png = $proc_dir . '/' . $png_name;

        if (file_exists($cached_png)) {
            $tmp_link = $user_ws . 'tmp' . $c_idx . '.png';
            if (file_exists($tmp_link) || is_link($tmp_link)) @unlink($tmp_link);
            @symlink(realpath($cached_png), $tmp_link);
        }
    }
}

/**
 * Synchronizes qvud rendered physical PNGs to process/ directory
 */
function sync_process_preview_dir($data_path, $userdir, $user) {
    $user_ws = rtrim($userdir, '/') . '/' . $user . '/';
    $chan_path = file_exists($user_ws . 'chan.dat') ? ($user_ws . 'chan.dat') : (file_exists($user_ws . 'imgoffs.dat') ? ($user_ws . 'imgoffs.dat') : null);
    if (!$chan_path) return;

    $lines = file($chan_path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $idx => $line) {
        $parts = explode(';', trim($line));
        if (count($parts) >= 3 && is_numeric(trim($parts[0]))) {
            $c_idx = intval(trim($parts[0]));
            $raw_file = trim($parts[1]);
        } else {
            $c_idx = $idx;
            $raw_file = trim($line);
        }
        if (empty($raw_file)) continue;

        $png_name = basename($raw_file) . '.png';
        $tmp_png = $user_ws . 'tmp' . $c_idx . '.png';

        if (file_exists($tmp_png)) {
            $full_raw_file = rtrim($data_path, '/') . '/' . ltrim($raw_file, '/');
            $flt_file = get_meta_path_for_file($full_raw_file, 'flt', $user);
            $has_custom_filter = file_exists($flt_file) && filesize($flt_file) > 0;

            $target_dir = get_process_dir($full_raw_file, $has_custom_filter, $user);
            if (!is_dir($target_dir)) {
                @mkdir($target_dir, 0775, true);
                @chmod($target_dir, 0775);
            }
            $target_png = $target_dir . '/' . $png_name;

            // Only update process/ cache if tmp_png is a real physical file (NOT a symlink) or custom filter exists
            if (!is_link($tmp_png) || $has_custom_filter) {
                @unlink($target_png);
                @copy($tmp_png, $target_png);
                @chmod($target_png, 0664);
            }
        }
    }
}

?>
