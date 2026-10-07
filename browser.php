<?php

require('globals.php');
require('auth.php');

function spc2nbsp($whatever) { 
    return str_replace(' ', '&nbsp;', $whatever); 
}

function multiexplode($delimiters, $string) {
    $ready = str_replace($delimiters, $delimiters[0], $string);
    $launch = explode($delimiters[0], $ready);
    return $launch;
}

function myfnmatch($mask, $file) {
    if (trim($mask) === '') return false;
    $mmask = multiexplode(array(';', ",", "|", ":"), $mask);
    foreach ($mmask as $pmask) {
        $pmask = trim($pmask);
        if ($pmask !== '' && fnmatch($pmask, $file)) {
            return true;
        }
    }
    return false;
}

function linkseq($path, $mode, $project = '', $user = null) {
    if ($user === null && isset($_SESSION['user'])) {
        $user = $_SESSION['user'];
    }
    if ($user === null) {
        $user = 'admin';
    }
    
    $clean_path = rtrim(str_replace('\\', '/', $path), '/');
    $proj_param = ($project !== '') ? '&project=' . urlencode($project) : '';
    
    if ($clean_path === 'data' || $clean_path === '') {
        return '<a href="browser.php?view_mode=normal&path=data/&mode=' . urlencode($mode) . $proj_param . '">data</a>/';
    }
    
    $parts = explode('/', $clean_path);
    $built_path = '';
    $res = '';
    
    foreach ($parts as $part) {
        if ($part === '') continue;
        $built_path = ($built_path === '') ? $part : $built_path . '/' . $part;
        $folder_url = 'browser.php?view_mode=normal&path=' . urlencode_path($built_path . '/') . '&mode=' . urlencode($mode) . $proj_param;
        
        $badge = '';
        if ($part !== 'data') {
            $built_dpath = $built_path . '/';
            if (has_direct_wspa_localdir($built_dpath)) {
                $badge .= '<span class="badge-matrix" title="Local in-situ data folder (writable)">LOCAL</span>';
            }
            
            $anchor = get_project_anchor_dir($built_dpath);
            if ($anchor !== null && rtrim($anchor, '/') === rtrim($built_dpath, '/')) {
                $meta_dir = get_meta_dir($built_dpath, $user);
                $proj_file = rtrim($meta_dir, '/') . '/.project';
                if (file_exists($proj_file)) {
                    $pname = trim(@file_get_contents($proj_file));
                    if ($pname !== '') {
                        $badge .= '<span class="badge-project" style="background:#111;color:' . get_project_color($pname) . ';border:1px solid ' . get_project_color($pname) . ';" title="Project: ' . htmlspecialchars($pname) . '">' . htmlspecialchars($pname) . '</span>';
                    }
                }
            }
        }
        
        $res .= '<a href="' . $folder_url . '">' . htmlspecialchars($part) . '</a>' . $badge . '/';
    }
    
    return $res;
}

function render_breadcrumb($path, $mode, $view_mode, $selected_project, $user) {
    if ($view_mode === 'project') {
        $proj_url = 'browser.php?view_mode=project&project=&path=data/&mode=' . urlencode($mode);
        $res = '<a href="' . $proj_url . '">projects</a>/';
        
        if ($selected_project !== '') {
            $p_url = 'browser.php?view_mode=project&project=' . urlencode($selected_project) . '&path=data/&mode=' . urlencode($mode);
            $bg_color = get_project_color($selected_project);
            $p_style = 'background:' . $bg_color . ';color:#fff;padding:0 6px;font-weight:bold;display:inline-block;height:20px;line-height:20px;vertical-align:top;margin:0;';
            $res .= '<a style="' . $p_style . '" href="' . $p_url . '">' . htmlspecialchars($selected_project) . '</a>/';
            
            $clean_path = rtrim(str_replace('\\', '/', $path), '/');
            if ($clean_path !== '' && $clean_path !== 'data') {
                $folder_url = 'browser.php?view_mode=project&project=' . urlencode($selected_project) . '&path=' . urlencode_path($clean_path . '/') . '&mode=' . urlencode($mode);
                $res .= '<a href="' . $folder_url . '">' . htmlspecialchars($clean_path) . '</a>/';
            }
        }
        return $res;
    } else {
        return linkseq($path, $mode, $selected_project, $user);
    }
}

function sortbykey($data, $which, $ascend) {
    if (empty($data)) return array();
    foreach ($data as $key => $row) {
        $mid[$key] = isset($row[$which]) ? $row[$which] : '';
        $src[$key] = isset($row['source']) ? $row['source'] : '';
    }
    if (isset($mid)) {
        if ($ascend) {
            array_multisort($mid, SORT_ASC, $src, SORT_ASC, $data);
        } else {
            array_multisort($mid, SORT_DESC, $src, SORT_ASC, $data);
        }
    }
    return $data;
}

function extractzip($what, $where) {
    if (!class_exists('ZipArchive')) return -1;
    $zip = new ZipArchive;
    if ($zip->open($what) === TRUE) {
        $zip->extractTo($where);
        $zip->close();
        return 1;
    } else {
        return -1;
    }
}

/**
 * Unified Directory Scanner (Data Files + Shadow Files)
 */
function list_dir($dir, $user) {
    if (!is_dir($dir)) return false;
    
    $list = array();
    $existing_dirs = array();
    $dir_indices = array();
    
    // 1. Scan Raw Data Directory
    if ($handle = opendir($dir)) {
        while (false !== ($file = readdir($handle))) {
            if ($file === '.' || $file === '..') continue;
            $full_path = rtrim($dir, '/') . '/' . $file;
            $is_directory = is_dir($full_path);
            
            $entry = array(
                'filename' => $file,
                'path' => $full_path,
                'modtime' => @filemtime($full_path),
                'source' => 'raw',
                'type' => $is_directory ? 'dir' : 'file',
                'is_shadowed' => false
            );
            
            $idx = count($list);
            $list[] = $entry;
            
            if ($is_directory) {
                $existing_dirs[$file] = true;
                $dir_indices[$file] = $idx;
            }
        }
        closedir($handle);
    }
    
    // 2. Scan Shadow Metadata Directory ONLY in Mode B (when meta_dir != dir)
    $meta_dir = get_meta_dir($dir, $user);
    if ($meta_dir !== $dir && is_dir($meta_dir)) {
        if ($mhandle = opendir($meta_dir)) {
            while (false !== ($mfile = readdir($mhandle))) {
                if ($mfile === '.' || $mfile === '..') continue;
                $mfull_path = rtrim($meta_dir, '/') . '/' . $mfile;
                
                if ($mfile === 'cache' || $mfile === 'exports') continue;
                $is_directory = is_dir($mfull_path);
                
                if ($is_directory) {
                    // Deduplicate directory entries in the left column
                    if (isset($existing_dirs[$mfile])) {
                        $orig_idx = $dir_indices[$mfile];
                        $list[$orig_idx]['is_shadowed'] = true;
                    } else {
                        $entry = array(
                            'filename' => $mfile,
                            'path' => $mfull_path,
                            'modtime' => @filemtime($mfull_path),
                            'source' => 'meta',
                            'type' => 'dir',
                            'is_shadowed' => true
                        );
                        $list[] = $entry;
                        $existing_dirs[$mfile] = true;
                    }
                } else {
                    // DO NOT deduplicate files in the right column
                    $entry = array(
                        'filename' => $mfile,
                        'path' => $mfull_path,
                        'modtime' => @filemtime($mfull_path),
                        'source' => 'meta',
                        'type' => 'file',
                        'is_shadowed' => true
                    );
                    $list[] = $entry;
                }
            }
            closedir($mhandle);
        }
    }
    
    return $list;
}

/**
 * Resolves adjacent (Prev / Next) directory paths relative to current $path
 */
function get_adjacent_directories($path, $view_mode, $selected_project, $user, $user_projects) {
    $clean_path = rtrim(str_replace('\\', '/', $path), '/') . '/';
    
    // In Projects View at top level of a project dataset folder
    if ($view_mode === 'project' && $selected_project !== '' && isset($user_projects[$selected_project])) {
        $anchor_p = get_project_anchor_dir($path);
        $clean_anchor = ($anchor_p !== null) ? rtrim(str_replace('\\', '/', $anchor_p), '/') . '/' : '';
        
        if ($clean_anchor !== '' && $clean_path === $clean_anchor) {
            $proj_dirs = array();
            foreach ($user_projects[$selected_project] as $pd) {
                $proj_dirs[] = rtrim(str_replace('\\', '/', $pd), '/') . '/';
            }
            if (in_array($clean_path, $proj_dirs)) {
                return array(
                    'siblings' => $proj_dirs,
                    'curr_index' => array_search($clean_path, $proj_dirs)
                );
            }
        }
    }
    
    // Standard Parent Directory Siblings (Directory View OR subfolder in Projects View)
    $parent_dir = dirname(rtrim($path, '/'));
    if ($parent_dir === '.' || $parent_dir === '' || $parent_dir === 'data') {
        $parent_dir = 'data/';
    } else {
        $parent_dir = rtrim(str_replace('\\', '/', $parent_dir), '/') . '/';
    }
    
    $parent_items = list_dir($parent_dir, $user);
    if ($parent_items === false) $parent_items = array();
    
    $parent_dirs = array();
    foreach ($parent_items as $item) {
        if ($item['type'] === 'dir') {
            $parent_dirs[] = $item;
        }
    }
    
    $sorted_dirs = sortbykey($parent_dirs, 'filename', false);
    $sibling_paths = array();
    foreach ($sorted_dirs as $sdir) {
        $sibling_paths[] = rtrim($parent_dir, '/') . '/' . $sdir['filename'] . '/';
    }
    
    $curr_idx = array_search($clean_path, $sibling_paths);
    return array(
        'siblings' => $sibling_paths,
        'curr_index' => $curr_idx
    );
}

// Session & GET/POST Handling
$msg = array();
$msg[0] = "Logged in as " . $user;

if ($user === 'admin' && isset($_POST['add_user_submit'])) {
    $new_u = isset($_POST['new_user_name']) ? trim($_POST['new_user_name']) : '';
    $new_p = isset($_POST['new_user_pass']) ? $_POST['new_user_pass'] : '';
    
    if ($new_u === '' || $new_p === '') {
        $msg[0] = "Error: Username and password are required.";
    } else if (!preg_match('/^[a-zA-Z0-9_\-]+$/', $new_u)) {
        $msg[0] = "Error: Username can only contain letters, numbers, _, and -.";
    } else if (strlen($new_p) < 4) {
        $msg[0] = "Error: Password must be at least 4 characters long.";
    } else {
        $target_user_dir = "users/" . $new_u;
        $target_shadow_dir = $target_user_dir . "/shadow";
        $target_profile = $target_user_dir . "/profile.php";
        
        if (file_exists($target_profile)) {
            $msg[0] = "Error: User '" . htmlspecialchars($new_u, ENT_QUOTES, 'UTF-8') . "' already exists!";
        } else {
            if (!is_dir($target_user_dir)) {
                @mkdir($target_user_dir, 0775, true);
            }
            if (!is_dir($target_shadow_dir)) {
                @mkdir($target_shadow_dir, 0775, true);
            }
            
            $hash = password_hash($new_p, PASSWORD_BCRYPT);
            $profile_content = "<? header('HTTP/1.0 404 Not found');die(); ?>\n" . $hash . "\n";
            
            if (@file_put_contents($target_profile, $profile_content) !== false) {
                @chmod($target_profile, 0664);
                $msg[0] = "User '" . htmlspecialchars($new_u, ENT_QUOTES, 'UTF-8') . "' created successfully!";
            } else {
                $msg[0] = "Error: Failed to create user profile.";
            }
        }
    }
}

if (isset($_GET['msg'])) {
    $msg[0] = $_GET['msg'];
}

$oldpath = isset($_GET['oldpath']) ? $_GET['oldpath'] : "";
$mode = isset($_POST['mode']) ? $_POST['mode'] : (isset($_GET['mode']) ? $_GET['mode'] : "File");

$mask = isset($_POST['mask']) ? $_POST['mask'] : "";
$open = isset($_POST['open']) ? $_POST['open'] : "";
$selected_project = isset($_GET['project']) ? trim($_GET['project']) : (isset($_POST['project']) ? trim($_POST['project']) : '');

if (isset($_POST['vmode_folder']) || isset($_GET['vmode_folder'])) {
    $view_mode = 'normal';
    $selected_project = '';
} else if (isset($_POST['vmode_project']) || isset($_GET['vmode_project'])) {
    $view_mode = 'project';
    $proj_for_path = get_project_for_dir($path, $user);
    if ($proj_for_path !== null && $proj_for_path !== '') {
        $selected_project = $proj_for_path;
    } else {
        $selected_project = '';
        $path = 'data/';
        $_SESSION['path'] = 'data/';
    }
} else if (isset($_GET['view_mode'])) {
    $view_mode = trim($_GET['view_mode']);
} else if (isset($_POST['view_mode'])) {
    $view_mode = trim($_POST['view_mode']);
} else {
    $view_mode = ($selected_project !== '') ? 'project' : 'normal';
}

if ($view_mode === 'project' && $selected_project === '') {
    $path = 'data/';
    $_SESSION['path'] = 'data/';
}

// Handle Project Assignment
if (isset($_POST['assign_project'])) {
    $p_name = (isset($_POST['new_project_name']) && trim($_POST['new_project_name']) !== '') 
            ? trim($_POST['new_project_name']) 
            : (isset($_POST['project_name']) ? trim($_POST['project_name']) : '');
            
    if (isset($_POST['assign_chk']) && is_array($_POST['assign_chk']) && count($_POST['assign_chk']) > 0) {
        $assigned_count = 0;
        foreach ($_POST['assign_chk'] as $chk_path) {
            $chk_path = trim(urldecode($chk_path));
            if ($chk_path !== '' && is_project_assignable_dir($chk_path)) {
                if (set_project_for_dir($chk_path, $p_name, $user)) {
                    $assigned_count++;
                }
            }
        }
        if ($assigned_count > 0) {
            $msg[0] = ($p_name !== '') 
                ? "Assigned $assigned_count selected folder(s) to project: " . $p_name 
                : "Cleared project allegiance for $assigned_count selected folder(s).";
            if ($p_name !== '') {
                $selected_project = $p_name;
            }
        } else {
            $msg[0] = "Failed to update project allegiance for selected folders.";
        }
    } else if (is_project_assignable_dir($path)) {
        if (set_project_for_dir($path, $p_name, $user)) {
            $msg[0] = ($p_name !== '') 
                ? "Updated directory project allegiance to: " . $p_name 
                : "Cleared project allegiance (set to Default).";
            if ($p_name !== '') {
                $selected_project = $p_name;
            }
        } else {
            $msg[0] = "Failed to update project allegiance.";
        }
    } else {
        $msg[0] = "Please select folder(s) via checkbox to assign them to a project.";
    }
}

$selected_checked_files = array();
if (isset($_POST['checkr']) && is_array($_POST['checkr'])) {
    foreach ($_POST['checkr'] as $chk_f) {
        $selected_checked_files[$chk_f] = true;
    }
}

if (isset($_POST['mask_add']) || isset($_POST['mask_remove'])) {
    $resultx_files = list_dir($path, $user);
    if ($resultx_files) {
        $effective_mask = ($mask !== '') ? $mask : '*';
        foreach ($resultx_files as $entry) {
            if ($entry['type'] === 'file') {
                $fname = $entry['filename'];
                if (myfnmatch($effective_mask, $fname)) {
                    if (isset($_POST['mask_add'])) {
                        $selected_checked_files[$fname] = true;
                    } else if (isset($_POST['mask_remove'])) {
                        unset($selected_checked_files[$fname]);
                    }
                }
            }
        }
    }
}

if (isset($_POST['load_sxm'])) {
    $resultx_files = list_dir($path, $user);
    $sxm_files = array();
    $meta_dir_for_path = get_meta_dir($path, $user);
    if ($resultx_files) {
        foreach ($resultx_files as $entry) {
            if ($entry['type'] === 'file' && strtolower(pathinfo($entry['filename'], PATHINFO_EXTENSION)) === 'sxm') {
                $raw_file = getcwd() . '/' . rtrim($path, '/') . '/' . $entry['filename'];
                $meta_file = getcwd() . '/' . rtrim($meta_dir_for_path, '/') . '/' . $entry['filename'];
                if (!file_exists($raw_file) && file_exists($meta_file)) {
                    $sxm_files[] = $meta_file;
                } else {
                    $sxm_files[] = $raw_file;
                }
            }
        }
    }
    if (!empty($sxm_files)) {
        @unlink($userdir . $user . "/mylist.lst");
        file_put_contents($userdir . $user . "/mylist.lst", implode("\n", $sxm_files));
        
        session_start();
        $_SESSION['rights'] = "w";
        session_write_close();
        
        header('Location: launcher.php?path=' . urlencode($path));
        exit;
    } else {
        $msg[0] = "No .sxm files found in current directory.";
    }
}

if ($open === "Open") {
    if (!empty($selected_checked_files)) {
        @unlink($userdir . $user . "/mylist.lst");
        $fullcheckr = array();
        $meta_dir_for_path = get_meta_dir($path, $user);
        foreach (array_keys($selected_checked_files) as $elem) {
            $raw_file = getcwd() . '/' . rtrim($path, '/') . '/' . $elem;
            $meta_file = getcwd() . '/' . rtrim($meta_dir_for_path, '/') . '/' . $elem;
            if (!file_exists($raw_file) && file_exists($meta_file)) {
                $fullcheckr[] = $meta_file;
            } else {
                $fullcheckr[] = $raw_file;
            }
        }
        file_put_contents($userdir . $user . "/mylist.lst", implode("\n", $fullcheckr));
        
        session_start();
        $_SESSION['rights'] = "w";
        session_write_close();
        
        header('Location: launcher.php?path=' . urlencode($path));
        exit;
    } else {
        $msg[0] = "No files selected. Please select file(s) to open.";
    }
}

$user_projects = list_user_projects($user);

// Render Page Header
require('head.php');

if ($view_mode === 'project') {
    $clean_p = rtrim(str_replace('\\', '/', $path), '/');
    if ($selected_project === '' || $clean_p === 'data' || $clean_p === '') {
        $resultx = array();
    } else {
        $resultx = list_dir($path, $user);
        if ($resultx === false) $resultx = array();
    }
} else {
    $resultx = list_dir($path, $user);
    if ($resultx === false) $resultx = array();
}

$result = sortbykey($resultx, 'filename', false);

echo "<div class=\"fill\"><TABLE style=\"width:100%;height:20px;background:#400;\"><TR style=\"height:20px;background:#400;\">";
echo "<TD style=\"height:20px;line-height:20px;vertical-align:middle;padding-left:5px;background:#400;\">" . (isset($msg[0]) ? htmlspecialchars($msg[0], ENT_QUOTES, 'UTF-8') : '') . "</TD>";

if ($user === 'admin') {
    echo "<TD align=\"right\" style=\"height:20px;line-height:20px;vertical-align:middle;padding:0;white-space:nowrap;background:#400;\">";
    echo "<form method=\"post\" action=\"browser.php?path=" . urlencode_path($path) . "&mode=" . urlencode($mode) . "&view_mode=" . urlencode($view_mode) . (($selected_project !== '') ? '&project=' . urlencode($selected_project) : '') . "\" style=\"display:inline-flex;align-items:center;height:20px;margin:0;vertical-align:middle;\">";
    echo "<span style=\"font-family:monospace;padding-right:4px;line-height:20px;\">Add new user: </span>";
    echo "<input type=\"text\" name=\"new_user_name\" size=\"8\" placeholder=\"username\" style=\"font-family:Arial,sans-serif;background:#222;color:#fff;padding:0 4px;height:20px;line-height:20px;border:none;border-left:1px solid #444;outline:none;border-radius:0;box-shadow:none;vertical-align:top;margin:0;box-sizing:border-box;\">";
    echo "<span style=\"font-family:monospace;padding:0 4px;line-height:20px;\"> password: </span>";
    echo "<input type=\"password\" name=\"new_user_pass\" size=\"8\" placeholder=\"password\" style=\"font-family:Arial,sans-serif;background:#222;color:#fff;padding:0 4px;height:20px;line-height:20px;border:none;border-left:1px solid #444;outline:none;border-radius:0;box-shadow:none;vertical-align:top;margin:0;box-sizing:border-box;\">";
    echo "<input type=\"submit\" name=\"add_user_submit\" value=\"Add\" style=\"background:#bff;\">";
    echo "</form>";
    echo "</TD>";
}

echo "</TR></TABLE>";

$is_root = ($path === 'data/' || $path === 'data' || $path === '');
$curr_folder_name = basename(rtrim($path, '/'));
$curr_is_local = is_wspa_localdir($path);
$curr_has_direct_local = has_direct_wspa_localdir($path);
$curr_proj = get_project_for_dir($path, $user);

$curr_meta_dir = get_meta_dir($path, $user);
$curr_has_direct_shadow_files = false;
if (is_dir($curr_meta_dir)) {
    $s_files = @glob(rtrim($curr_meta_dir, '/') . '/*');
    if ($s_files) {
        foreach ($s_files as $sf) {
            if (is_file($sf) && basename($sf) !== '.project') {
                $curr_has_direct_shadow_files = true;
                break;
            }
        }
    }
}

$has_assignable_folders_in_list = false;
if ($view_mode === 'project' && $selected_project !== '' && ($path === 'data/' || $path === 'data' || $path === '')) {
    if (isset($user_projects[$selected_project])) {
        foreach ($user_projects[$selected_project] as $linked_dpath) {
            if (is_project_assignable_dir($linked_dpath)) {
                $has_assignable_folders_in_list = true;
                break;
            }
        }
    }
} else {
    foreach ($result as $entry) {
        if ($entry['type'] === 'dir') {
            $fpath = rtrim($path, '/') . '/' . $entry['filename'] . '/';
            if (is_project_assignable_dir($fpath)) {
                $has_assignable_folders_in_list = true;
                break;
            }
        }
    }
}
$is_inside_dataset = (get_path_depth($path) >= 2);
$show_project_selector = $is_inside_dataset || is_project_assignable_dir($path) || $has_assignable_folders_in_list;

// Top Control Bar: Location & Project Allegiance Form
echo '<div class="loc"><TABLE style="width:100%;height:20px;"><TR><TD style="vertical-align:top;padding-left:5px;">' 
   . render_breadcrumb($path, $mode, $view_mode, $selected_project, $user) 
   . '</TD><TD align="right" style="vertical-align:top;padding:0;">';

// Project Allegiance Control Form (appears by default in Level 3+, but ONLY when checkboxes are selected in Level 2 view)
if ($show_project_selector) {
    $sel_bg_color = ($curr_proj !== null && $curr_proj !== '') ? get_project_color($curr_proj) : '#222';
    $form_display = $is_inside_dataset ? 'inline-flex' : 'none';
    $require_chk = $is_inside_dataset ? '0' : '1';

    echo '<form id="project_assign_form" data-require-checkbox="' . $require_chk . '" method="post" action="browser.php?path=' . urlencode_path($path) . '&mode=' . urlencode($mode) . '&view_mode=' . urlencode($view_mode) . (($selected_project !== '') ? '&project=' . urlencode($selected_project) : '') . '" style="display:' . $form_display . ';align-items:stretch;height:20px;margin:0;vertical-align:top;">';
    echo '<input type="hidden" name="mode" value="' . htmlspecialchars($mode) . '">';
    echo '<span style="color:#fff;font-weight:bold;line-height:20px;padding:0 5px 0 8px;">Project: </span>';
    echo '<select name="project_name" onchange="this.style.backgroundColor = (this.options[this.selectedIndex].getAttribute(\'data-color\') || \'#222\');" style="background:' . $sel_bg_color . ';color:#fff;font-weight:bold;padding:0 6px;height:20px;line-height:20px;border:none;outline:none;border-radius:0;box-shadow:none;vertical-align:top;margin:0;box-sizing:border-box;">';
    
    $sel_none = ($curr_proj === null || $curr_proj === '') ? 'SELECTED' : '';
    echo '<option value="" ' . $sel_none . ' data-color="#222" style="background:#222;color:#fff;">-- unassigned --</option>';
    
    foreach (array_keys($user_projects) as $upname) {
        if ($upname === 'DEFAULT') continue;
        $sel = ($curr_proj === $upname) ? 'SELECTED' : '';
        $opt_color = get_project_color($upname);
        echo '<option value="' . htmlspecialchars($upname) . '" ' . $sel . ' data-color="' . htmlspecialchars($opt_color) . '" style="background:' . htmlspecialchars($opt_color) . ';color:#fff;">' . htmlspecialchars($upname) . '</option>';
    }
    echo '</select>';
    
    echo '<input type="text" name="new_project_name" size="10" placeholder="..or add new" style="background:#222;color:#fff;padding:0 4px;height:20px;line-height:20px;border:none;border-left:1px solid #444;vertical-align:top;margin:0;box-sizing:border-box;">';
    echo '<input type="submit" name="assign_project" value="Set">';
    echo '</form>';
    
    echo '<script>
    function updateProjectAssignFormVisibility() {
        var form = document.getElementById("project_assign_form");
        if (!form) return;
        if (form.getAttribute("data-require-checkbox") === "0") {
            form.style.display = "inline-flex";
            return;
        }
        var checkedBoxes = document.querySelectorAll("input[name=\'assign_chk[]\']:checked");
        if (checkedBoxes.length > 0) {
            form.style.display = "inline-flex";
        } else {
            form.style.display = "none";
        }
    }
    document.addEventListener("change", function(e) {
        if (e.target && e.target.name === "assign_chk[]") {
            updateProjectAssignFormVisibility();
        }
    });
    document.addEventListener("DOMContentLoaded", updateProjectAssignFormVisibility);
    updateProjectAssignFormVisibility();
    </script>';
}

echo '</TD></TR></TABLE></div>';

echo '<TABLE class="twocolumn"><TR><TD>';
echo '<div class="dlist"><TABLE><TR><TH colspan=3>';

echo '<form id="dirs" method="get" action="browser.php">';
echo '<input type="hidden" name="path" value="' . htmlspecialchars($path) . '">';
if ($selected_project !== '') {
    echo '<input type="hidden" name="project" value="' . htmlspecialchars($selected_project) . '">';
}
echo '<input type="hidden" name="mode" value="' . htmlspecialchars($mode) . '">';
$folder_btn_style = ($view_mode === 'normal') ? 'style="background:#bff"' : '';
$project_btn_style = ($view_mode === 'project') ? 'style="background:#bff"' : '';
echo '<input type="submit" name="vmode_folder" value="Directory view" ' . $folder_btn_style . '>';
echo '<input type="submit" name="vmode_project" value="Projects view" ' . $project_btn_style . '>';
echo '<input type="submit" name="refresh" value="Refresh" style="float:right;">';

$clean_path_check = rtrim(str_replace('\\', '/', $path), '/');
$is_not_data_root = ($clean_path_check !== '' && $clean_path_check !== 'data');
$show_prev_next = false;
if ($view_mode === 'normal') {
    $show_prev_next = $is_not_data_root;
} else if ($view_mode === 'project') {
    $show_prev_next = ($selected_project !== '' && $is_not_data_root);
}

if ($show_prev_next) {
    $adj_res = get_adjacent_directories($path, $view_mode, $selected_project, $user, $user_projects);
    $siblings = $adj_res['siblings'];
    $curr_idx = $adj_res['curr_index'];
    
    $prev_url = null;
    $next_url = null;
    
    if ($curr_idx !== false && $curr_idx > 0) {
        $prev_target = $siblings[$curr_idx - 1];
        $prev_url = 'browser.php?view_mode=' . urlencode($view_mode) 
                  . (($selected_project !== '') ? '&project=' . urlencode($selected_project) : '')
                  . '&path=' . urlencode_path($prev_target) 
                  . '&mode=' . urlencode($mode);
    }
    
    if ($curr_idx !== false && $curr_idx < count($siblings) - 1) {
        $next_target = $siblings[$curr_idx + 1];
        $next_url = 'browser.php?view_mode=' . urlencode($view_mode) 
                  . (($selected_project !== '') ? '&project=' . urlencode($selected_project) : '')
                  . '&path=' . urlencode_path($next_target) 
                  . '&mode=' . urlencode($mode);
    }
    
    if ($next_url !== null) {
        echo '<input type="button" value="Next" onclick="window.location.href=\'' . htmlspecialchars($next_url, ENT_QUOTES, 'UTF-8') . '\';" style="float:right;margin-right:2px;">';
    } else {
        echo '<input type="submit" value="Next" disabled style="float:right;margin-right:2px;">';
    }
    
    if ($prev_url !== null) {
        echo '<input type="button" value="Prev" onclick="window.location.href=\'' . htmlspecialchars($prev_url, ENT_QUOTES, 'UTF-8') . '\';" style="float:right;margin-right:2px;">';
    } else {
        echo '<input type="submit" value="Prev" disabled style="float:right;margin-right:2px;">';
    }
}

echo '</FORM><TABLE><TR><TD style="border:1px solid #888;background-color:#888;height:0px"></TR></TABLE></TR>';

if ($view_mode === 'project') {
    if ($selected_project === '') {
        // Project View Level 1: List Projects as Virtual Folders (styled with project background color)
        $parent_chk = '<input class="checkbox" type="checkbox" style="visibility:hidden;">';
        echo '<TR><TD>' . $parent_chk . '</TD><TD></TD><TD></TD></TR>';
        
        $pidx = 0;
        foreach ($user_projects as $pname => $pdirs) {
            if ($pname === 'DEFAULT') continue;
            $bg_color = get_project_color($pname, $pidx);
            $hover_color = get_project_color_hover($pname, $pidx);
            $link_url = 'browser.php?view_mode=project&project=' . urlencode($pname) . '&path=data/&mode=' . urlencode($mode);
            
            $is_match = ($oldpath !== '' && (strtolower($oldpath) === strtolower($pname) || $selected_project === $pname));
            $is_initial = $is_match ? ' data-initial-focus="1"' : '';

            echo '<TR class="dlist-row"' . $is_initial . ' onclick="if(event.target.tagName!==\'INPUT\')window.location.href=\'' . htmlspecialchars($link_url) . '\';" onmouseover="this.style.backgroundColor=\'' . htmlspecialchars($hover_color) . '\';" onmouseout="this.style.backgroundColor=\'' . htmlspecialchars($bg_color) . '\';" style="background:' . htmlspecialchars($bg_color) . ';color:#fff;height:20px;line-height:20px;cursor:pointer;">'
               . '<TD style="padding-left:0;vertical-align:middle;color:#fff;font-weight:normal;">' . $parent_chk . '<a style="color:#fff;font-weight:normal;text-decoration:none;" href="' . $link_url . '">' . spc2nbsp(htmlspecialchars($pname)) . '</a></TD>'
               . '<TD style="vertical-align:middle;"></TD>'
               . '<TD align="right" style="padding-right:4px;vertical-align:middle;color:#fff;font-weight:normal;">' . count($pdirs) . ' folders&nbsp;</TD>'
               . '</TR>';
            $pidx++;
        }
    } else if ($path === 'data/' || $path === 'data' || $path === '') {
        // Project View Level 2: List folders pertaining to this project
        $parent_url = 'browser.php?view_mode=project&project=&path=data/&mode=' . urlencode($mode);
        $parent_link = '<a href="' . htmlspecialchars($parent_url) . '">ALL PROJECTS</a>';
        $parent_chk = '<input class="checkbox" type="checkbox" style="visibility:hidden;">';
        echo '<TR class="dlist-row" onclick="if(event.target.tagName!==\'INPUT\')window.location.href=\'' . htmlspecialchars($parent_url) . '\';" style="cursor:pointer;"><TD colspan=2>' . $parent_chk . $parent_link . '</TD><TD></TD></TR>';
        
        if (isset($user_projects[$selected_project])) {
            foreach ($user_projects[$selected_project] as $linked_dpath) {
                $folder_is_local = is_wspa_localdir($linked_dpath);
                $folder_has_direct_local = has_direct_wspa_localdir($linked_dpath);
                $color_style = $folder_is_local ? 'color:#00ff41;' : 'color:#bff;';
                
                $clean_old = rtrim(str_replace('\\', '/', $oldpath), '/');
                $clean_link = rtrim(str_replace('\\', '/', $linked_dpath), '/');
                $is_match = ($clean_old !== '' && ($clean_old === $clean_link || basename($clean_old) === basename($clean_link)));
                $is_initial = $is_match ? ' data-initial-focus="1"' : '';
                
                $badges = render_rights_badge($linked_dpath, $user);
                if ($folder_has_direct_local) {
                    $badges .= '<span class="badge-matrix" title="Local in-situ data folder (writable)">LOCAL</span>';
                }
                
                $link_url = 'browser.php?view_mode=project&project=' . urlencode($selected_project) . '&path=' . urlencode_path($linked_dpath) . '&mode=' . urlencode($mode);
                $folder_chk = is_project_assignable_dir($linked_dpath) 
                    ? '<input class="checkbox" type="checkbox" form="project_assign_form" name="assign_chk[]" value="' . htmlspecialchars($linked_dpath) . '">' 
                    : '<input class="checkbox" type="checkbox" style="visibility:hidden;">';
                
                echo '<TR class="dlist-row"' . $is_initial . ' onclick="if(event.target.tagName!==\'INPUT\')window.location.href=\'' . htmlspecialchars($link_url) . '\';" style="cursor:pointer;"><TD>' . $folder_chk . '<a style="' . $color_style . '" href="' . $link_url . '">' . spc2nbsp(htmlspecialchars($linked_dpath)) . '</a></TD><TD>' . $badges . '</TD><TD align="right">&nbsp;</TD></TR>';
            }
        }
    } else {
        // Project View Level 3+: Directory tree inside selected dataset folder
        $clean_p = rtrim(str_replace('\\', '/', $path), '/');
        $anchor_p = get_project_anchor_dir($path);
        $clean_anchor = ($anchor_p !== null) ? rtrim(str_replace('\\', '/', $anchor_p), '/') : '';
        
        if ($clean_anchor !== '' && $clean_p === $clean_anchor) {
            // At top level of dataset folder: PARENT DIRECTORY returns to Level 2 with oldpath set to current $path
            $parent_url = 'browser.php?view_mode=project&project=' . urlencode($selected_project) . '&path=data/&oldpath=' . urlencode($path) . '&mode=' . urlencode($mode);
        } else {
            // Inside subfolder: PARENT DIRECTORY returns to parent directory in Project View
            $parent_dir = dirname($clean_p);
            if ($parent_dir === '.' || $parent_dir === '' || $parent_dir === 'data') $parent_dir = 'data/';
            $parent_url = 'browser.php?view_mode=project&project=' . urlencode($selected_project) . '&path=' . urlencode_path($parent_dir . '/') . '&oldpath=' . urlencode(basename($clean_p)) . '&mode=' . urlencode($mode);
        }
        $parent_link = '<a href="' . htmlspecialchars($parent_url) . '">PARENT DIRECTORY</a>';
        
        $parent_chk = '<input class="checkbox" type="checkbox" style="visibility:hidden;">';
        echo '<TR class="dlist-row" onclick="if(event.target.tagName!==\'INPUT\')window.location.href=\'' . htmlspecialchars($parent_url) . '\';" style="cursor:pointer;"><TD colspan=2>' . $parent_chk . $parent_link . '</TD><TD></TD></TR>';
        
        foreach ($result as $entry) {
            if ($entry['type'] === "dir") {
                $folder_name = $entry['filename'];
                $folder_path = rtrim($path, '/') . '/' . $folder_name . '/';
                
                $folder_is_local = is_wspa_localdir($folder_path);
                $folder_has_direct_local = has_direct_wspa_localdir($folder_path);
                
                $clean_old = rtrim(str_replace('\\', '/', $oldpath), '/');
                $is_match = ($clean_old !== '' && ($clean_old === $folder_name || $clean_old === rtrim($folder_path, '/')));
                $is_initial = $is_match ? ' data-initial-focus="1"' : '';
                
                $color_style = $folder_is_local ? 'color:#00ff41;' : 'color:#bff;';
                
                $badges = render_rights_badge($folder_path, $user);
                if ($folder_has_direct_local) {
                    $badges .= '<span class="badge-matrix" title="Local in-situ data folder (writable)">LOCAL</span>';
                }
                
                $link_url = 'browser.php?view_mode=project&project=' . urlencode($selected_project) . '&path=' . urlencode_path($folder_path) . '&mode=' . urlencode($mode);
                $folder_chk = is_project_assignable_dir($folder_path) 
                    ? '<input class="checkbox" type="checkbox" form="project_assign_form" name="assign_chk[]" value="' . htmlspecialchars($folder_path) . '">' 
                    : '<input class="checkbox" type="checkbox" style="visibility:hidden;">';
                
                echo '<TR class="dlist-row"' . $is_initial . ' onclick="if(event.target.tagName!==\'INPUT\')window.location.href=\'' . htmlspecialchars($link_url) . '\';" style="cursor:pointer;"><TD>' . $folder_chk . '<a style="' . $color_style . '" href="' . $link_url . '">' . spc2nbsp(htmlspecialchars($folder_name)) . '</a></TD><TD>' . $badges . '</TD><TD align="right">' . date('Y-m-d', $entry['modtime']) . '&nbsp;</TD></TR>';
            }
        }
    }
} else {
    // Normal View: Render standard directory tree
    if (get_path_depth($path) == 0) {
        $parent_link = '';
    } else {
        $parent_dir = dirname(rtrim($path, '/'));
        if ($parent_dir === '.' || $parent_dir === '') $parent_dir = 'data/';
        $parent_url = 'browser.php?view_mode=normal&path=' . urlencode_path($parent_dir) . '&mode=' . urlencode($mode) . '&oldpath=' . urlencode(basename(rtrim($path, '/')));
        $parent_link = '<a href="' . htmlspecialchars($parent_url) . '">PARENT DIRECTORY</a>';
    }
    $parent_chk = '<input class="checkbox" type="checkbox" style="visibility:hidden;">';
    if ($parent_link !== '') {
        echo '<TR class="dlist-row" onclick="if(event.target.tagName!==\'INPUT\')window.location.href=\'' . htmlspecialchars($parent_url) . '\';" style="cursor:pointer;"><TD colspan=2>' . $parent_chk . $parent_link . '</TD><TD></TD></TR>';
    }
    
    foreach ($result as $entry) {
        if ($entry['type'] === "dir") {
            $folder_name = $entry['filename'];
            $folder_path = rtrim($path, '/') . '/' . $folder_name . '/';
            
            $folder_is_local = is_wspa_localdir($folder_path);
            $folder_has_direct_local = has_direct_wspa_localdir($folder_path);
            
            $clean_old = rtrim(str_replace('\\', '/', $oldpath), '/');
            $is_match = ($clean_old !== '' && ($clean_old === $folder_name || $clean_old === rtrim($folder_path, '/')));
            $is_initial = $is_match ? ' data-initial-focus="1"' : '';
            
            $color_style = $folder_is_local ? 'color:#00ff41;' : 'color:#bff;';
            
            $badges = render_rights_badge($folder_path, $user);
            if ($folder_has_direct_local) {
                $badges .= '<span class="badge-matrix" title="Local in-situ data folder (writable)">LOCAL</span>';
            }
            
            $f_anchor = get_project_anchor_dir($folder_path);
            if (get_path_depth($path) == 0 && !$folder_is_local && !empty($entry['is_shadowed'])) {
                $badges .= '<span class="badge-projects" title="Contains user project/shadow data">PROJECTS</span>';
            } else if ($f_anchor !== null && rtrim($f_anchor, '/') === rtrim($folder_path, '/')) {
                $f_proj = get_project_for_dir($folder_path, $user);
                if ($f_proj !== null) {
                    $badges .= '<span class="badge-project" style="background:#111;color:' . get_project_color($f_proj) . ';border:1px solid ' . get_project_color($f_proj) . ';" title="Project: ' . htmlspecialchars($f_proj) . '">' . htmlspecialchars($f_proj) . '</span>';
                } else if (!$folder_is_local) {
                    $meta_dir_for_folder = get_meta_dir($folder_path, $user);
                    $has_direct_shadow_files = false;
                    if (is_dir($meta_dir_for_folder)) {
                        $s_files = @glob(rtrim($meta_dir_for_folder, '/') . '/*');
                        if ($s_files) {
                            foreach ($s_files as $sf) {
                                if (is_file($sf) && basename($sf) !== '.project') {
                                    $has_direct_shadow_files = true;
                                    break;
                                }
                            }
                        }
                    }
                    if ($has_direct_shadow_files) {
                        $badges .= '<span class="badge-default" title="Default (unassigned project)">DEFAULT</span>';
                    }
                }
            }
            
            $link_url = 'browser.php?view_mode=normal&path=' . urlencode_path($folder_path) . '&mode=' . urlencode($mode);
            $folder_chk = is_project_assignable_dir($folder_path) 
                ? '<input class="checkbox" type="checkbox" form="project_assign_form" name="assign_chk[]" value="' . htmlspecialchars($folder_path) . '">' 
                : '<input class="checkbox" type="checkbox" style="visibility:hidden;">';
            
            echo '<TR class="dlist-row"' . $is_initial . ' onclick="if(event.target.tagName!==\'INPUT\')window.location.href=\'' . htmlspecialchars($link_url) . '\';" style="cursor:pointer;"><TD>' . $folder_chk . '<a style="' . $color_style . '" href="' . $link_url . '">' . spc2nbsp(htmlspecialchars($folder_name)) . '</a></TD><TD>' . $badges . '</TD><TD align="right">' . date('Y-m-d', $entry['modtime']) . '&nbsp;</TD></TR>';
        }
    }
}

echo '</TABLE></div>';

// Midnight Commander style keyboard navigation script
echo '<script>
(function() {
    var prevUrl = ' . json_encode(isset($prev_url) ? $prev_url : null) . ';
    var nextUrl = ' . json_encode(isset($next_url) ? $next_url : null) . ';
    var dlist = document.querySelector(".dlist");
    if (!dlist) return;

    var rows = Array.prototype.slice.call(dlist.querySelectorAll("tr.dlist-row"));
    if (rows.length === 0) return;

    var currentIndex = 0;
    var initialFocusRow = dlist.querySelector("tr.dlist-row[data-initial-focus=\"1\"]");
    if (initialFocusRow) {
        var idx = rows.indexOf(initialFocusRow);
        if (idx !== -1) currentIndex = idx;
    }

    function scrollToRow(row, center) {
        if (!row || !dlist) return;
        if (center) {
            var targetScroll = row.offsetTop - (dlist.clientHeight / 2) + (row.offsetHeight / 2);
            dlist.scrollTop = Math.max(0, targetScroll);
        } else {
            var stickyHeaderHeight = 30;
            var rowTop = row.offsetTop;
            var rowBottom = rowTop + row.offsetHeight;
            var containerTop = dlist.scrollTop;
            var containerBottom = containerTop + dlist.clientHeight;

            if (rowTop < containerTop + stickyHeaderHeight) {
                dlist.scrollTop = rowTop - stickyHeaderHeight;
            } else if (rowBottom > containerBottom) {
                dlist.scrollTop = rowBottom - dlist.clientHeight;
            }
        }
    }

    function updateSelection(isInitial) {
        for (var i = 0; i < rows.length; i++) {
            if (i === currentIndex) {
                rows[i].classList.add("mc-selected");
            } else {
                rows[i].classList.remove("mc-selected");
            }
        }
        if (rows[currentIndex]) {
            scrollToRow(rows[currentIndex], isInitial && initialFocusRow !== null);
        }
    }

    rows.forEach(function(row, index) {
        row.addEventListener("click", function(e) {
            if (e.target && (e.target.tagName === "INPUT" || e.target.tagName === "SELECT")) {
                return;
            }
            currentIndex = index;
            updateSelection(false);
        });
    });

    document.addEventListener("keydown", function(e) {
        var active = document.activeElement;
        if (active && (active.tagName === "TEXTAREA" || active.tagName === "SELECT" || (active.tagName === "INPUT" && active.type !== "checkbox"))) {
            return;
        }

        if (e.key === "Insert" || e.keyCode === 45) {
            e.preventDefault();
            var currentRow = rows[currentIndex];
            if (currentRow) {
                var linkText = "";
                var linkEl = currentRow.querySelector("a");
                if (linkEl) {
                    linkText = (linkEl.textContent || linkEl.innerText || "").trim();
                }
                if (linkText !== "PARENT DIRECTORY" && linkText !== "ALL PROJECTS") {
                    var chk = currentRow.querySelector("input[type=\"checkbox\"]");
                    if (chk && window.getComputedStyle(chk).visibility !== "hidden" && !chk.disabled) {
                        chk.checked = !chk.checked;
                        chk.dispatchEvent(new Event("change", { bubbles: true }));
                    }
                }
            }
            if (currentIndex < rows.length - 1) {
                currentIndex++;
                updateSelection(false);
            }
            return;
        }

        switch (e.key) {
            case "ArrowUp":
                e.preventDefault();
                if (currentIndex > 0) {
                    currentIndex--;
                    updateSelection(false);
                }
                break;
            case "ArrowDown":
                e.preventDefault();
                if (currentIndex < rows.length - 1) {
                    currentIndex++;
                    updateSelection(false);
                }
                break;
            case "PageUp":
                e.preventDefault();
                currentIndex = Math.max(0, currentIndex - 8);
                updateSelection(false);
                break;
            case "PageDown":
                e.preventDefault();
                currentIndex = Math.min(rows.length - 1, currentIndex + 8);
                updateSelection(false);
                break;
            case "Home":
                e.preventDefault();
                currentIndex = 0;
                updateSelection(false);
                break;
            case "End":
                e.preventDefault();
                currentIndex = rows.length - 1;
                updateSelection(false);
                break;
            case "Enter":
                if (rows[currentIndex]) {
                    var link = rows[currentIndex].querySelector("a");
                    if (link && link.href) {
                        e.preventDefault();
                        window.location.href = link.href;
                    }
                }
                break;
            case "ArrowLeft":
                if (prevUrl) {
                    e.preventDefault();
                    window.location.href = prevUrl;
                }
                break;
            case "ArrowRight":
                if (nextUrl) {
                    e.preventDefault();
                    window.location.href = nextUrl;
                }
                break;
        }
    });

    updateSelection(true);
})();
</script>';

echo '</TD><TD style="border:1px solid #888;background-color:#888;width:0px"></TD><TD>';

if ($mode !== 'Img') {
?>
<div class="flist"><TABLE><TR><TH colspan=2>
<form id="basic" enctype="multipart/form-data" method="post" action="browser.php?path=<?php echo urlencode_path($path); ?>&view_mode=<?php echo urlencode($view_mode); ?><?php echo ($selected_project !== '') ? '&project=' . urlencode($selected_project) : ''; ?>">
<input type="submit" name="mode" value="File" style="background:#bff"><input type="submit" name="mode" value="Img">
<input list="masks" id="mask_input" name="mask" size=5 value="<?php echo htmlspecialchars($mask);?>" placeholder="Mask"><input type="submit" name="mask_add" value=" + " style="width:24px;" onclick="filterMaskSelection('+'); return false;"><input type="submit" name="mask_remove" value=" - " style="width:24px;" onclick="filterMaskSelection('-'); return false;">

<datalist id="masks">
  <option value="*.par">Omicron</option>
  <option value="*.sxm">Nanonis</option>
  <option value="*.nc">GSXM</option>
  <option value="*.top,*.ch0,*.ch1,*.ch2">WSXM</option>
  <option value="*.dat">Createk</option>
  <option value="*.out">Fireball</option>
</datalist><input type="submit" name="open" value="Open"><input type="submit" name="load_sxm" value="LOAD SXM" style="background:#bff" onclick="selectAndLoadSxm(event)">

<TABLE><TR><TD style="border:1px solid #888; background-color:#888;height:0px;"></TR></TABLE></TR>

<?php
    $result_files = sortbykey($resultx, 'filename', true);

    foreach ($result_files as $entry) {
        if ($entry['type'] === "file") {
            $fname = $entry['filename'];
            $chked = isset($selected_checked_files[$fname]) ? "CHECKED" : "";
            
            if ($entry['source'] === 'meta') {
                $tag = ' <span class="badge-shadow">SHADOW</span>';
                $link_attr = 'class="file-shadow"';
            } else {
                $tag = '';
                $link_attr = '';
            }
            
            $file_link = 'viewfile.php?file=' . urlencode_path($entry['path']);
            
            echo '<TR><TD><input class="checkbox" type="checkbox" name="checkr[]" value="' . htmlspecialchars($fname) . '" ' . $chked . '><a ' . $link_attr . ' href="' . htmlspecialchars($file_link) . '" target="_blank">' . htmlspecialchars($fname) . '</a>' . $tag . '<TD align="right">' . date('Y-m-d H:i', $entry['modtime']) . '</TR>';
        }
    }

    echo '</TABLE></form></div>';

} else {
    
    echo '<div class="flist"><TABLE><TR><TD><FORM id="basic" method="post" action="browser.php?path=' . urlencode_path($path) . '&view_mode=' . urlencode($view_mode) . (($selected_project !== '') ? '&project=' . urlencode($selected_project) : '') . '">';
    echo '<input type="submit" name="mode" value="File"><input type="submit" name="mode" value="Img" style="background:#bff">';
    echo '</FORM></TABLE>';
    echo '<TABLE><TR><TD style="border:1px solid #888; background-color:#888;height:0px;"></TR></TABLE>';

    $pics = array();
    foreach ($resultx as $entry) {
        if ($entry['type'] === 'file') {
            $file = $entry['filename'];
            $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
            if (in_array($ext, array('jpg', 'jpeg', 'gif', 'png'))) {
                $pics[] = $entry;
            }
        }
    }

    $pics = sortbykey($pics, 'filename', true);

    foreach ($pics as $pic_entry) {
        $pic = $pic_entry['filename'];
        $pic_url = 'viewfile.php?file=' . urlencode_path($pic_entry['path']);
        echo '<div style="display: inline-block;width:200px;padding:2px;overflow:hidden;text-align:center;position:relative;font-size:inherit;">';
        echo '<a class="decor" href="' . htmlspecialchars($pic_url) . '" target="_blank"><img src="' . htmlspecialchars($pic_url) . '" style="max-height:200px;max-width:200px;">';
        echo '<div style="font-size:10pt">' . htmlspecialchars($pic) . '</div></a></div>';
    }
    echo "</div>";
}

echo '</TD></TR></TABLE></div>';

?>
<script>
function fnmatchJS(pattern, filename) {
    if (!pattern || pattern.trim() === '') return false;
    var parts = pattern.split(',');
    for (var i = 0; i < parts.length; i++) {
        var p = parts[i].trim();
        if (!p) continue;
        var regexStr = '^' + p.replace(/([.+^${}()|[\]\\])/g, '\\$1').replace(/\*/g, '.*').replace(/\?/g, '.') + '$';
        var rx = new RegExp(regexStr, 'i');
        if (rx.test(filename)) return true;
    }
    return false;
}

function filterMaskSelection(action) {
    var maskInput = document.getElementById('mask_input');
    var pattern = maskInput ? maskInput.value.trim() : '';
    if (!pattern) pattern = '*';
    
    var checkboxes = document.querySelectorAll('input.checkbox[name="checkr[]"]');
    checkboxes.forEach(function(cb) {
        var filename = cb.value;
        if (fnmatchJS(pattern, filename)) {
            if (action === '+') {
                cb.checked = true;
            } else if (action === '-') {
                cb.checked = false;
            }
        }
    });
}

function selectAndLoadSxm(evt) {
    var checkboxes = document.querySelectorAll('input.checkbox[name="checkr[]"]');
    checkboxes.forEach(function(cb) {
        if (cb.value.toLowerCase().endsWith('.sxm')) {
            cb.checked = true;
        }
    });
}
</script>
</body>
</html>
<?php exit; ?>
