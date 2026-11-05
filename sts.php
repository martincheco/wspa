<?php
if (!in_array('ob_gzhandler', ob_list_handlers()) && extension_loaded('zlib')) {
	@ob_start('ob_gzhandler');
}
/**
 * WSPA Spectroscopy Analysis Workstation (sts.php)
 *
 * Layout (3 columns):
 * - Column 1 (Left): Scan image with overlaid STS (.map) points, nearest-neighbor scaling, flush rim.
 * - Column 2 (Center): 1-4 vertically distributed graph windows with X/Y selectors, toggleable Fwd/Bwd,
 *                     toggleable AutoX/AutoY, engineering notation ticks, Sync X, and None/eV/meV/cm^-1 conversions.
 * - Column 3 (Right): Channel thumbnails, navigation buttons, collapsible tmp.dat info (qvud),
 *                     mask selection (+, -), and alphabetical curve list with 64-level continuous color scale.
 */

define('WSPA', true);
require('globals.php');
require('auth.php');
require('head.php');
require('loadnanonis_sts.php');

// ============================================================================
// MODULE 1: CONFIGURATION, LIMITS & HEURISTICS
// ============================================================================

// Global limit for simultaneously plottable curves (defined in globals.php)
if (!isset($sts_max_curves)) {
	$sts_max_curves = 16;
}

/**
 * Load External STS Channel Configuration (sts_channels.cfg)
 */
function load_sts_channel_config($user = null) {
	$candidates = array();
	if ($user !== null) {
		$candidates[] = "users/" . $user . "/sts_channels.cfg";
		$candidates[] = "users/" . $user . "/sts.cfg";
	}
	$candidates[] = __DIR__ . "/sts_channels.cfg";
	$candidates[] = __DIR__ . "/sts.cfg";

	$cfg_file = null;
	foreach ($candidates as $c) {
		if (file_exists($c)) {
			$cfg_file = $c;
			break;
		}
	}
	if ($cfg_file === null) return array();

	$lines = file($cfg_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
	if ($lines === false) return array();

	$rules = array();
	foreach ($lines as $line) {
		$line = trim($line);
		if ($line === '' || strpos($line, '#') === 0 || strpos($line, ';') === 0) continue;

		preg_match_all('/"([^"]*)"|\'([^\']*)\'|(\S+)/', $line, $matches);
		$tokens = array();
		for ($i = 0; $i < count($matches[0]); $i++) {
			if ($matches[1][$i] !== '') $tokens[] = $matches[1][$i];
			elseif ($matches[2][$i] !== '') $tokens[] = $matches[2][$i];
			else $tokens[] = $matches[3][$i];
		}
		if (count($tokens) < 3) continue;

		$patterns = array_map('trim', explode(',', $tokens[0]));
		$windows = array();
		for ($ti = 1; $ti < count($tokens); $ti += 2) {
			if ($ti + 1 < count($tokens)) {
				$windows[] = array('x' => trim($tokens[$ti]), 'y' => trim($tokens[$ti + 1]));
			} else {
				$windows[] = array('x' => trim($tokens[$ti]), 'y' => trim($tokens[$ti]));
			}
		}

		if (!empty($windows)) {
			$rules[] = array(
				'patterns' => $patterns,
				'windows'  => $windows
			);
		}
	}
	return $rules;
}

$SPECTROSCOPY_HEURISTICS = load_sts_channel_config($user);
if (empty($SPECTROSCOPY_HEURISTICS)) {
	$SPECTROSCOPY_HEURISTICS = array(
		array(
			'patterns' => array('*.dat'),
			'windows'  => array(
				array('x' => '0', 'y' => '1'),
				array('x' => '0', 'y' => '2')
			)
		)
	);
}

// Read user configuration (persistent layout & button states)
$user_cfg = read_user_config($user);
$saved_show_info   = isset($user_cfg['sts_show_info']) ? ($user_cfg['sts_show_info'] === '1') : false;
$saved_show_spec   = isset($user_cfg['sts_show_spec']) ? ($user_cfg['sts_show_spec'] === '1') : false;
$saved_img_w       = isset($user_cfg['sts_img_width']) ? max(200, min(2400, intval($user_cfg['sts_img_width']))) : 400;
$saved_info_h      = isset($user_cfg['sts_info_height']) ? max(50, min(800, intval($user_cfg['sts_info_height']))) : 140;
$saved_spec_h      = isset($user_cfg['sts_spec_height']) ? max(50, min(800, intval($user_cfg['sts_spec_height']))) : 140;
$saved_color_link  = isset($user_cfg['sts_color_link']) ? ($user_cfg['sts_color_link'] === '1') : false;
$saved_conv_mode   = isset($user_cfg['sts_conv_mode']) ? $user_cfg['sts_conv_mode'] : 'none';
if ($saved_conv_mode === 'mev') $saved_conv_mode = 'ev';
$saved_lambda      = isset($user_cfg['sts_lambda']) ? floatval($user_cfg['sts_lambda']) : 532.0;

// Session-level memory & clean load defaults (Rule 20)
// Defaults: 2 graphs, lines on, points off, Sync X on, Fwd on, Bwd off, AutoX on, AutoY on
$saved_num_graphs  = isset($_SESSION['sts_num_graphs']) ? max(1, min(4, intval($_SESSION['sts_num_graphs']))) : 2;
$saved_plot_lines  = isset($_SESSION['sts_plot_lines']) ? ($_SESSION['sts_plot_lines'] !== '0') : true;
$saved_plot_points = isset($_SESSION['sts_plot_points']) ? ($_SESSION['sts_plot_points'] === '1') : false;
if (!$saved_plot_lines && !$saved_plot_points) {
	$saved_plot_lines = true;
}
$saved_sync_x      = isset($_SESSION['sts_sync_x']) ? ($_SESSION['sts_sync_x'] === '1') : true;

// Save configuration if passed via navigation form submit (Rule 16: No AJAX)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_cfg_flag'])) {
	$cfg_to_save = array();
	if (isset($_POST['cfg_show_info'])) $cfg_to_save['sts_show_info'] = ($_POST['cfg_show_info'] === '1') ? '1' : '0';
	if (isset($_POST['cfg_show_spec'])) $cfg_to_save['sts_show_spec'] = ($_POST['cfg_show_spec'] === '1') ? '1' : '0';
	if (isset($_POST['cfg_img_width'])) $cfg_to_save['sts_img_width'] = max(200, min(2400, intval($_POST['cfg_img_width'])));
	if (isset($_POST['cfg_info_height'])) $cfg_to_save['sts_info_height'] = max(50, min(800, intval($_POST['cfg_info_height'])));
	if (isset($_POST['cfg_spec_height'])) $cfg_to_save['sts_spec_height'] = max(50, min(800, intval($_POST['cfg_spec_height'])));
	if (isset($_POST['cfg_color_link'])) $cfg_to_save['sts_color_link'] = ($_POST['cfg_color_link'] === '1') ? '1' : '0';
	if (isset($_POST['cfg_conv_mode'])) {
		$cm = trim($_POST['cfg_conv_mode']);
		if ($cm === 'mev') $cm = 'ev';
		$cfg_to_save['sts_conv_mode'] = $cm;
	}
	if (isset($_POST['cfg_lambda'])) $cfg_to_save['sts_lambda'] = floatval($_POST['cfg_lambda']);

	// Save persistent interface settings to user.cfg
	save_user_config($cfg_to_save, $user);
	$user_cfg = array_merge($user_cfg, $cfg_to_save);

	// Save session-bound settings to $_SESSION (Rule 20)
	if (isset($_POST['cfg_num_graphs'])) $_SESSION['sts_num_graphs'] = max(1, min(4, intval($_POST['cfg_num_graphs'])));
	if (isset($_POST['cfg_plot_lines'])) $_SESSION['sts_plot_lines'] = ($_POST['cfg_plot_lines'] === '1') ? '1' : '0';
	if (isset($_POST['cfg_plot_points'])) $_SESSION['sts_plot_points'] = ($_POST['cfg_plot_points'] === '1') ? '1' : '0';
	if (isset($_POST['cfg_sync_x'])) $_SESSION['sts_sync_x'] = ($_POST['cfg_sync_x'] === '1') ? '1' : '0';
	for ($w = 1; $w <= 4; $w++) {
		if (isset($_POST['cfg_g' . $w . '_x'])) $_SESSION['sts_g' . $w . '_x'] = trim($_POST['cfg_g' . $w . '_x']);
		if (isset($_POST['cfg_g' . $w . '_y'])) $_SESSION['sts_g' . $w . '_y'] = trim($_POST['cfg_g' . $w . '_y']);
		if (isset($_POST['cfg_g' . $w . '_fwd'])) $_SESSION['sts_g' . $w . '_fwd'] = trim($_POST['cfg_g' . $w . '_fwd']);
		if (isset($_POST['cfg_g' . $w . '_bwd'])) $_SESSION['sts_g' . $w . '_bwd'] = trim($_POST['cfg_g' . $w . '_bwd']);
	}

	// Immediately reflect in current render variables
	if (isset($cfg_to_save['sts_img_width'])) $saved_img_w = $cfg_to_save['sts_img_width'];
	if (isset($cfg_to_save['sts_info_height'])) $saved_info_h = $cfg_to_save['sts_info_height'];
	if (isset($cfg_to_save['sts_spec_height'])) $saved_spec_h = $cfg_to_save['sts_spec_height'];
	if (isset($cfg_to_save['sts_color_link'])) $saved_color_link = ($cfg_to_save['sts_color_link'] === '1');
	if (isset($cfg_to_save['sts_show_info'])) $saved_show_info = ($cfg_to_save['sts_show_info'] === '1');
	if (isset($cfg_to_save['sts_show_spec'])) $saved_show_spec = ($cfg_to_save['sts_show_spec'] === '1');
	if (isset($_SESSION['sts_num_graphs'])) $saved_num_graphs = $_SESSION['sts_num_graphs'];
	if (isset($_SESSION['sts_plot_lines'])) $saved_plot_lines = ($_SESSION['sts_plot_lines'] === '1');
	if (isset($_SESSION['sts_plot_points'])) $saved_plot_points = ($_SESSION['sts_plot_points'] === '1');
	if (!$saved_plot_lines && !$saved_plot_points) {
		$saved_plot_lines = true;
	}
	if (isset($_SESSION['sts_sync_x'])) $saved_sync_x = ($_SESSION['sts_sync_x'] === '1');
	if (isset($cfg_to_save['sts_conv_mode'])) $saved_conv_mode = $cfg_to_save['sts_conv_mode'];
	if (isset($cfg_to_save['sts_lambda'])) $saved_lambda = $cfg_to_save['sts_lambda'];
}

$session_window_configs = array();
for ($w = 1; $w <= 4; $w++) {
	$session_window_configs[$w] = array(
		'x'   => isset($_SESSION['sts_g' . $w . '_x']) ? trim($_SESSION['sts_g' . $w . '_x']) : '',
		'y'   => isset($_SESSION['sts_g' . $w . '_y']) ? trim($_SESSION['sts_g' . $w . '_y']) : '',
		'fwd' => isset($_SESSION['sts_g' . $w . '_fwd']) ? trim($_SESSION['sts_g' . $w . '_fwd']) : '1',
		'bwd' => isset($_SESSION['sts_g' . $w . '_bwd']) ? trim($_SESSION['sts_g' . $w . '_bwd']) : '0'
	);
}

// ============================================================================
// MODULE 2: SCAN STATE & DUAL-MODE MAP RESOLUTION
// ============================================================================

// Build index of scans that have STS (.map file)
$sts_scans = array();
$chan_file = $userdir . $user . '/chan.dat';
$acqchan_file = $userdir . $user . '/acqchan.dat';
$raw_chans = file_exists($chan_file) ? file($chan_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) : array();
$acqchans = file_exists($acqchan_file) ? file($acqchan_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) : array();

$scan_channels = array();
if (!empty($raw_chans)) {
	foreach ($raw_chans as $ch_idx => $ch_path) {
		$ch_path = trim($ch_path);
		if ($ch_path === '') continue;
		$scan_base = preg_replace('/\.(f|b)\d+$/i', '', stripslashes($ch_path));
		if (!isset($scan_channels[$scan_base])) {
			$scan_channels[$scan_base] = array();
		}
		$scan_channels[$scan_base][] = $ch_idx;
	}
	foreach ($scan_channels as $scan_base => $ch_indices) {
		$s_dir = pathinfo($scan_base, PATHINFO_DIRNAME);
		$s_bi = pathinfo(pathinfo($scan_base, PATHINFO_FILENAME), PATHINFO_FILENAME);
		$s_clean = $s_dir . '/' . $s_bi;
		$s_map = get_meta_path_for_file($s_clean, 'map', $user);
		if (file_exists($s_map) || file_exists($s_dir . '/' . $s_bi . '.map') || file_exists(stripslashes($s_dir) . '/' . stripslashes($s_bi) . '.map')) {
			$sts_scans[] = array(
				'file'     => $scan_base,
				'ch_idx'   => $ch_indices[0],
				'channels' => $ch_indices
			);
		}
	}
}

// Current channel index before command
$cur_idx = isset($_POST['index']) ? intval($_POST['index']) : -1;
if ($cur_idx < 0 && file_exists($userdir . $user . '/tmp.dat')) {
	$tmp_lines = @file($userdir . $user . '/tmp.dat');
	if (!empty($tmp_lines[1])) {
		$t_parts = preg_split('/\s+/', $tmp_lines[1]);
		if (isset($t_parts[1])) $cur_idx = intval($t_parts[1]) - 1;
	}
}

$calc_sts_targets = function($target_idx) use ($sts_scans, $raw_chans, $acqchans, $scan_channels) {
	$prev_sts_ch = null;
	$next_sts_ch = null;
	$prev_sts_name = '';
	$next_sts_name = '';
	$num_sts = count($sts_scans);
	if ($num_sts === 0) {
		return array($prev_sts_ch, $next_sts_ch, $prev_sts_name, $next_sts_name);
	}

	$target_acqchan = (isset($acqchans[$target_idx])) ? trim($acqchans[$target_idx]) : '';
	$target_scan_base = (isset($raw_chans[$target_idx])) ? preg_replace('/\.(f|b)\d+$/i', '', stripslashes(trim($raw_chans[$target_idx]))) : '';
	$target_plusch = 0;
	if ($target_scan_base !== '' && isset($scan_channels[$target_scan_base])) {
		$pos_in_scan = array_search($target_idx, $scan_channels[$target_scan_base]);
		if ($pos_in_scan !== false) {
			$target_plusch = $pos_in_scan;
		}
	}

	$pick_channel = function($target_si) use ($sts_scans, $acqchans, $target_acqchan, $target_plusch) {
		if (!isset($sts_scans[$target_si])) return null;
		$tgt_channels = $sts_scans[$target_si]['channels'];
		if (empty($tgt_channels)) return $sts_scans[$target_si]['ch_idx'];

		// 1. Try to find matching acquisition channel name and direction
		if ($target_acqchan !== '' && !empty($acqchans)) {
			foreach ($tgt_channels as $tc) {
				if (isset($acqchans[$tc]) && trim($acqchans[$tc]) === $target_acqchan) {
					return $tc;
				}
			}
		}

		// 2. Fallback to plusch channel offset within row (same as prevs / nexts in qvud.pro)
		$offset = min($target_plusch, count($tgt_channels) - 1);
		return $tgt_channels[max(0, $offset)];
	};

	$cur_sts_pos = -1;
	foreach ($sts_scans as $si => $s_info) {
		if (($target_scan_base !== '' && $s_info['file'] === $target_scan_base) || in_array($target_idx, $s_info['channels'])) {
			$cur_sts_pos = $si;
			break;
		}
	}

	if ($cur_sts_pos !== -1) {
		$prev_pos = ($cur_sts_pos > 0) ? ($cur_sts_pos - 1) : null;
		$next_pos = ($cur_sts_pos + 1 < $num_sts) ? ($cur_sts_pos + 1) : null;
	} else {
		$target_prev_si = null;
		for ($si = $num_sts - 1; $si >= 0; $si--) {
			if ($sts_scans[$si]['ch_idx'] < $target_idx) {
				$target_prev_si = $si;
				break;
			}
		}
		$target_next_si = null;
		for ($si = 0; $si < $num_sts; $si++) {
			if ($sts_scans[$si]['ch_idx'] > $target_idx) {
				$target_next_si = $si;
				break;
			}
		}
		$prev_pos = $target_prev_si;
		$next_pos = $target_next_si;
	}

	if ($prev_pos !== null) {
		$prev_sts_ch = $pick_channel($prev_pos);
		$prev_sts_name = basename($sts_scans[$prev_pos]['file']);
	}
	if ($next_pos !== null) {
		$next_sts_ch = $pick_channel($next_pos);
		$next_sts_name = basename($sts_scans[$next_pos]['file']);
	}

	return array($prev_sts_ch, $next_sts_ch, $prev_sts_name, $next_sts_name);
};

list($prev_sts_ch, $next_sts_ch, $prev_sts_name, $next_sts_name) = $calc_sts_targets($cur_idx);

$command = "none";
$nav_cmd = isset($_POST['nav_cmd']) ? trim($_POST['nav_cmd']) : '';
if (strpos($nav_cmd, 'goto ') === 0) { $command = $nav_cmd; }
if ((isset($_POST['prev_sts']) || $nav_cmd === 'prev_sts') && $prev_sts_ch !== null) { $command = "goto " . ($prev_sts_ch + 1); }
if ((isset($_POST['next_sts']) || $nav_cmd === 'next_sts') && $next_sts_ch !== null) { $command = "goto " . ($next_sts_ch + 1); }
if (isset($_POST['prev']) || $nav_cmd === 'prev') { if (!isset($_POST['prev']) || $_POST['prev'] == ' < ') $command = "prev"; }
if (isset($_POST['next']) || $nav_cmd === 'next') { if (!isset($_POST['next']) || $_POST['next'] == ' > ') $command = "next"; }
if (isset($_POST['prevs']) || $nav_cmd === 'prevs') { if (!isset($_POST['prevs']) || $_POST['prevs'] == '<<') $command = "prevs"; }
if (isset($_POST['nexts']) || $nav_cmd === 'nexts') { if (!isset($_POST['nexts']) || $_POST['nexts'] == '>>') $command = "nexts"; }
if (isset($_POST['index'])) { $oldindex = intval($_POST["index"]); } else { $oldindex = -1; }
if (isset($_GET['command'])) { $command = $_GET['command']; }

$command = stripslashes($command);
if (preg_match('/[^A-Za-z0-9+\-\s.,$]/', $command)) {
	$command = "none";
}

if (!empty($command) && $command !== "none") {
	@file_put_contents($userdir . $user . '/comm', $command . "\n");
}

$tmpdat = $userdir . $user . "/tmp.dat";
$c = 0;
while (!file_exists($tmpdat) && $c < (100 * $qtout)) {
	usleep(10000);
	$c++;
}

if ($c > (100 * $qtout - 1)) {
	header('Location: err.php');
	exit;
} else {
	$PrevSize = -1;
	while (($Size = @filesize($tmpdat)) != $PrevSize) {
		$PrevSize = $Size;
		usleep(10000);
	}
}

// Read scan metadata from tmp.dat
$msg = file($tmpdat);
$parts = preg_split('/\s+/', $msg[1]);
$index = intval($parts[1]) - 1;
// Recalculate STS navigation targets for newly active scan/channel
list($prev_sts_ch, $next_sts_ch, $prev_sts_name, $next_sts_name) = $calc_sts_targets($index);
$parts = preg_split('/\s+/', $msg[5]);
$xscale = isset($parts[1]) ? $parts[1] : '';
$runit = isset($parts[4]) ? $parts[4] : '';
$parts2 = preg_split('/\s\s/', $msg[3]);
$parts3 = isset($parts2[1]) ? preg_split('/-/', $parts2[1]) : array('', '');
$yscandir = trim($parts3[0]);
$xscandir = isset($parts3[1]) ? trim($parts3[1]) : '';
$raw_file = trim(stripslashes($msg[0]));

require('over.php');

$userlnk = ($shm != '') ? $userlink : $userdir;

// Resolve .map file location (Dual-Mode: Local in-situ vs Read-only shadow)
$mapdir = pathinfo($raw_file, PATHINFO_DIRNAME);
$bi = pathinfo(pathinfo($raw_file, PATHINFO_FILENAME), PATHINFO_FILENAME);
$clean_base_file = $mapdir . '/' . $bi;

$mapfile = get_meta_path_for_file($clean_base_file, 'map', $user);
if (!file_exists($mapfile)) {
	if (file_exists($mapdir . '/' . $bi . '.map')) {
		$mapfile = $mapdir . '/' . $bi . '.map';
	} else {
		$mapfile = "";
	}
}

// Parse .map file points
$map_curves = array();
if ($mapfile !== "" && file_exists($mapfile)) {
	$maplines = file($mapfile);
	$c = 1;
	$pt_coords = array(0, 0, 1);
	foreach ($maplines as $mapln) {
		$mapln = trim($mapln);
		if ($mapln === '') continue;
		if ($c == 0) {
			$fn = basename($mapln);
			$map_curves[] = array(
				'filename' => $fn,
				'x'        => $pt_coords[0],
				'y'        => $pt_coords[1],
				'dim'      => $pt_coords[2]
			);
			$c = 1;
		} else {
			$mapc = preg_split('/\s+/', $mapln);
			$pt_coords = array(
				(isset($mapc[0]) && is_numeric($mapc[0])) ? floatval($mapc[0]) : NAN,
				(isset($mapc[1]) && is_numeric($mapc[1])) ? floatval($mapc[1]) : NAN,
				(isset($mapc[2]) && is_numeric($mapc[2])) ? floatval($mapc[2]) : 1.0
			);
			$c = 0;
		}
	}
}

// Natural alphabetical sorting of curve files
usort($map_curves, function($a, $b) {
	return strnatcasecmp($a['filename'], $b['filename']);
});

$has_explicit_graph = (isset($_GET['graph']) && trim($_GET['graph']) !== '') || (isset($_POST['graphsel']) && trim($_POST['graphsel']) !== '');
$initial_target_graph = '';
if (isset($_GET['graph']) && trim($_GET['graph']) !== '') {
	$initial_target_graph = basename(trim($_GET['graph']));
} elseif (isset($_POST['graphsel']) && trim($_POST['graphsel']) !== '') {
	$initial_target_graph = basename(trim($_POST['graphsel']));
}

// Detect presence of primary optical/spectroscopy spectra vs auxiliary companion files
$has_aals = false;
foreach ($map_curves as $mc) {
	if (stripos($mc['filename'], 'AALS') === 0) {
		$has_aals = true;
		break;
	}
}

// ============================================================================
// MODULE 3: SYNCHRONOUS DATA PARSER (NO AJAX - RULE 16)
// ============================================================================

// Synchronously parse active curves belonging to the active scan
// For datasets with > 1024 curves, selectively preload the active window around the target
// to prevent memory exhaustion while preserving strict Rule 16 synchronous embedding.
$curves_to_load = array();
$total_map_curves = count($map_curves);

$target_idx = -1;
if ($initial_target_graph !== '') {
	foreach ($map_curves as $k => $mc) {
		if ($mc['filename'] === $initial_target_graph) {
			$target_idx = $k;
			break;
		}
	}
}

$sts_max_cache_curves = 1024;
if ($total_map_curves <= $sts_max_cache_curves) {
	foreach ($map_curves as $mc) {
		$curves_to_load[$mc['filename']] = true;
	}
} else {
	$center_idx = ($target_idx >= 0) ? $target_idx : 0;
	$half_win = intval($sts_max_cache_curves / 2);
	$start_k = max(0, min($total_map_curves - $sts_max_cache_curves, $center_idx - $half_win));
	$end_k = min($total_map_curves, $start_k + $sts_max_cache_curves);
	for ($k = $start_k; $k < $end_k; $k++) {
		$curves_to_load[$map_curves[$k]['filename']] = true;
	}
}

// Unconditionally guarantee that initial_target_graph and companion curve are loaded
if ($initial_target_graph !== '') {
	$curves_to_load[$initial_target_graph] = true;
	$companion_fn = '';
	if (stripos($initial_target_graph, 'AALS') === 0) {
		$companion_fn = preg_replace('/^AALS/i', 'LS', $initial_target_graph);
	} elseif (stripos($initial_target_graph, 'LS') === 0) {
		$companion_fn = preg_replace('/^LS/i', 'AALS', $initial_target_graph);
	}
	if ($companion_fn !== '') {
		$curves_to_load[$companion_fn] = true;
	}
}

$sts_cache_key = $clean_base_file . '|' . (@file_exists($mapfile) ? @filemtime($mapfile) : '');
if (!isset($_SESSION['sts_curves_cache']) || !is_array($_SESSION['sts_curves_cache'])) {
	$_SESSION['sts_curves_cache'] = array();
}

$all_curves_data = array();
$needed_files = array_keys($curves_to_load);
$can_use_cache = isset($_SESSION['sts_curves_cache'][$sts_cache_key]) && is_array($_SESSION['sts_curves_cache'][$sts_cache_key]);

if ($can_use_cache) {
	$cached_set = $_SESSION['sts_curves_cache'][$sts_cache_key];
	$missing = false;
	foreach ($needed_files as $pfile) {
		if (isset($cached_set[$pfile])) {
			$all_curves_data[$pfile] = $cached_set[$pfile];
		} else {
			$missing = true;
			break;
		}
	}
	if ($missing) {
		$all_curves_data = array();
		$can_use_cache = false;
	}
}

if (!$can_use_cache) {
	foreach ($needed_files as $pfile) {
		$fpath = $mapdir . '/' . $pfile;
		if (!file_exists($fpath)) {
			$meta_path = get_meta_path_for_file($mapdir . '/' . $pfile, '', $user);
			if (file_exists($meta_path)) $fpath = $meta_path;
		}
		$parsed = loadnanonis_sts($fpath);
		if ($parsed) {
			$all_curves_data[$pfile] = $parsed;
		}
	}
	// Bound cache to last 5 scans
	if (count($_SESSION['sts_curves_cache']) >= 5) {
		array_shift($_SESSION['sts_curves_cache']);
	}
	$_SESSION['sts_curves_cache'][$sts_cache_key] = $all_curves_data;
}


// ============================================================================
// MODULE 4: SPARTAN HTML LAYOUT (THREE COLUMNS)
// ============================================================================
?>
<style>
/* Prevent text selection when clicking/dragging in curve list */
#curves_container, .curve_row, .curve_name, #curves_tbody, .curve_row td {
	user-select: none;
	-webkit-user-select: none;
	-moz-user-select: none;
	-ms-user-select: none;
}
.interactive-mode .curve_checkbox_cell {
	display: none !important;
}
.curve_row.is-highlighted {
	background-color: #b22222 !important; /* Brick red */
	color: #fff !important;
}
.curve_row.is-highlighted .curve_name, .curve_row.is-highlighted a {
	color: #fff !important;
	font-weight: bold;
}
.curve_row.is-selected {
	background-color: rgba(0, 150, 255, 0.25) !important;
}
.curve_row.is-selected.is-highlighted {
	background-color: #b22222 !important; /* Brick red override */
	color: #fff !important;
}
.curve_row.is-selected.is-highlighted .curve_name, .curve_row.is-selected.is-highlighted a {
	color: #fff !important;
	font-weight: bold;
}
/* Neutral hover for standard buttons; do not interfere with active yellow buttons */
input[type=button]:hover, input[type=submit]:hover {
	background-color: #ddd !important;
	color: #000 !important;
}
.btn-yellow, .btn-yellow:hover, input.btn-yellow:hover, input[type=button].btn-yellow:hover, input[type=submit].btn-yellow:hover {
	background-color: #ff0 !important;
	color: #000 !important;
}
/* Vector STS Point Crosses: Green (selected), Turquoise (unselected), Thicker White (highlighted) */
.sts_dot {
	position: absolute;
	width: 9px;
	height: 9px;
	cursor: pointer;
	margin: 0;
	padding: 0;
	border: 0;
	display: block;
	pointer-events: auto;
	filter: drop-shadow(0px 0px 1px #000);
}
.sts_dot line {
	stroke-linecap: square;
}
.sts_dot.is-unselected line {
	stroke: #00e5ff; /* Turquoise */
	stroke-width: 1.2;
}
.sts_dot.is-selected line {
	stroke: #00ff41; /* Green */
	stroke-width: 1.2;
}
.sts_dot.is-highlighted line {
	stroke: #ffffff !important; /* White */
	stroke-width: 2.4 !important; /* Thicker */
}
/* Custom Horizontal Resizer for Info & Specs (Single 1px line with 7px hit-area, green on hover) */
.textarea_resizer {
	height: 1px;
	width: 100%;
	background: #444;
	border-bottom: 1px solid #444;
	box-sizing: border-box;
	cursor: default;
	position: relative;
	user-select: none;
	-webkit-user-select: none;
}
.textarea_resizer::before {
	content: '';
	position: absolute;
	top: -3px;
	left: 0;
	right: 0;
	height: 7px;
	background: transparent;
	z-index: 10;
}
.textarea_resizer:hover, .textarea_resizer.is-dragging {
	background: #00ff41 !important;
	border-bottom-color: #00ff41 !important;
}

/* Vertical Splitter Divider for Column 1 (Single 1px line with 7px hit-area, green on hover) */
#col_splitter {
	width: 1px;
	min-width: 1px;
	max-width: 1px;
	background: #444;
	cursor: default;
	position: relative;
	user-select: none;
	-webkit-user-select: none;
	flex-shrink: 0;
}
#col_splitter::before {
	content: '';
	position: absolute;
	top: 0;
	bottom: 0;
	left: -3px;
	width: 7px;
	background: transparent;
	z-index: 10;
}
#col_splitter:hover, #col_splitter.is-dragging {
	background: #00ff41 !important;
}
</style>

<div class="fill" style="padding-top:20px; box-sizing:border-box; height:100vh; overflow:hidden;">

<div style="display:flex; flex-direction:row; width:100%; height:calc(100vh - 20px); margin:0; padding:0; border:0; overflow:hidden;">

	<!-- ====================================================================== -->
	<!-- COLUMN 1: SCAN IMAGE WITH STS POINTS OVERLAY (LEFT)                   -->
	<!-- ====================================================================== -->
	<?php
	$display_w = $saved_img_w;
	$img_c = $index;
	$img_file = $userlnk . $user . '/tmp' . $img_c . '.png';
	$img_exists = file_exists($img_file);
	$hh = $img_exists ? @getimagesize($img_file) : array(400, 400);
	$img_w = ($hh && !empty($hh[0])) ? $hh[0] : 400;
	$img_h = ($hh && !empty($hh[1])) ? $hh[1] : 400;
	$display_h = max(1, round($display_w * ($img_h / $img_w)));
	$img_hash = function_exists('get_image_cache_hash') ? get_image_cache_hash($img_file, $user) : @filemtime($img_file);
	$img_src = $img_exists ? ('serve_image.php?file=' . urlencode($img_file) . '&v=' . $img_hash) : ('showimage.php?image=tmp' . $img_c . '.png&t=' . microtime(true));
	?>
	<div id="col_left" style="width:<?php echo $display_w; ?>px; min-width:200px; flex-shrink:0; flex-grow:0; overflow:hidden; position:relative; margin:0; padding:0;">
		<div id="image_container" style="position:relative; width:<?php echo $display_w; ?>px; height:<?php echo $display_h; ?>px; max-width:100%; overflow:hidden; margin:0; padding:0; border:0; cursor:crosshair; display:block;">
			<img id="scan_img" src="<?php echo $img_src; ?>" 
			     width="<?php echo $display_w; ?>" height="<?php echo $display_h; ?>" 
			     style="display:block; width:100%; height:auto; max-width:100%; aspect-ratio:<?php echo $img_w . ' / ' . $img_h; ?>; image-rendering:pixelated; image-rendering:-moz-crisp-edges; image-rendering:crisp-edges; margin:0; padding:0; border:0;">

			<!-- Overlaid STS Points: Primary curves on top (base z-index 2000 + k), companion LS curves below (base z-index 10 + k) -->
			<?php
			if (!empty($map_curves)) {
				foreach ($map_curves as $k => $pt) {
					// Skip non-finite (NaN) coordinates
					if (!is_finite($pt['x']) || !is_finite($pt['y']) || !is_finite($pt['dim']) || $pt['dim'] <= 0) {
						continue;
					}
					$px_left = round(($pt['x'] * $display_h / $pt['dim']) - 4);
					$px_top  = round(($display_h - ($pt['y'] * $display_h / $pt['dim'])) - 4);
					$fn      = $pt['filename'];
					$is_ls   = ($has_aals && (stripos($fn, 'LS') === 0 || stripos($fn, 'MLS') === 0));
					$is_init = $has_explicit_graph ? ($fn === $initial_target_graph) : (($total_map_curves <= $sts_max_curves) && (!$is_ls && $k < $sts_max_curves));

					$dot_cls = $is_init ? 'is-selected' : 'is-unselected';
					$base_z  = $is_ls ? (10 + $k) : (2000 + $k);
					$dot_title = $fn;

					$frac_x = ($pt['dim'] > 0) ? ($pt['x'] / $pt['dim']) : 0;
					$frac_y = ($pt['dim'] > 0) ? ($pt['y'] / $pt['dim']) : 0;

					echo '<a href="javascript:void(0)" onclick="onPointClick(\'' . htmlspecialchars($fn) . '\', event)" title="' . htmlspecialchars($dot_title) . '">';
					echo '<svg class="sts_dot ' . $dot_cls . '" id="dot_' . $k . '" width="9" height="9" viewBox="0 0 9 9" ';
					echo 'style="position:absolute; left:' . $px_left . 'px; top:' . $px_top . 'px; z-index:' . $base_z . '; cursor:pointer; margin:0; padding:0; border:0;" ';
					echo 'data-file="' . htmlspecialchars($fn) . '" data-idx="' . $k . '" data-base-z="' . $base_z . '" ';
					echo 'data-frac-x="' . $frac_x . '" data-frac-y="' . $frac_y . '" ';
					echo 'onmouseover="highlightCurve(\'' . htmlspecialchars($fn) . '\', true)" onmouseout="highlightCurve(\'' . htmlspecialchars($fn) . '\', false)">';
					echo '<line x1="0" y1="4.5" x2="9" y2="4.5"/>';
					echo '<line x1="4.5" y1="0" x2="4.5" y2="9"/>';
					echo '</svg>';
					echo '</a>';
				}
			}
			?>
			?>

			<!-- Scan Direction Indicator -->
			<?php
			if (strtolower($yscandir) === 'up') {
				echo '<img id="scan_dir_img" data-dir="up" src="up.png" style="position:absolute; left:0px; top:' . ($display_h - 17) . 'px; z-index:101;" title="Up scan">';
			} elseif (strtolower($yscandir) === 'down') {
				echo '<img id="scan_dir_img" data-dir="down" src="down.png" style="position:absolute; left:0px; top:0px; z-index:101;" title="Down scan">';
			}
			?>
		</div>
	</div>

	<!-- ====================================================================== -->
	<!-- VERTICAL SPLITTER DIVIDER (RESIZE COLUMN 1)                            -->
	<!-- ====================================================================== -->
	<div id="col_splitter" title="Drag to resize Image column (double-click to reset)"></div>

	<!-- ====================================================================== -->
	<!-- COLUMN 2: SPECTROSCOPY PLOTTING WORKSTATION (CENTER)                   -->
	<!-- ====================================================================== -->
	<div id="col_center" style="flex:1; min-width:0; overflow:hidden; padding:0; margin:0; border:0; border-right:1px solid #444;">
		
		<!-- Graphs Top Toolbar (Flush, 24px width, auto text width, zero gap, Sync X, Conversions) -->
		<div id="graphs_toolbar" style="margin:0; padding:0; white-space:nowrap; line-height:21.6px; border-bottom:1px solid #444;">
			<span style="font-weight:bold; color:#bff;">Graphs:</span><input type="button" id="btn_win_1" value="1" onclick="setNumGraphs(1)" style="width:24px;" class="<?php if ($saved_num_graphs == 1) echo 'btn-yellow'; ?>"><input type="button" id="btn_win_2" value="2" onclick="setNumGraphs(2)" style="width:24px;" class="<?php if ($saved_num_graphs == 2) echo 'btn-yellow'; ?>"><input type="button" id="btn_win_3" value="3" onclick="setNumGraphs(3)" style="width:24px;" class="<?php if ($saved_num_graphs == 3) echo 'btn-yellow'; ?>"><input type="button" id="btn_win_4" value="4" onclick="setNumGraphs(4)" style="width:24px;" class="<?php if ($saved_num_graphs == 4) echo 'btn-yellow'; ?>">
			&nbsp;
			<span style="font-weight:bold; color:#bff;">Style:</span><input type="button" id="btn_style_lines" value="Lines" onclick="togglePlotStyle('lines')" class="<?php if ($saved_plot_lines) echo 'btn-yellow'; ?>"><input type="button" id="btn_style_points" value="Points" onclick="togglePlotStyle('points')" class="<?php if ($saved_plot_points) echo 'btn-yellow'; ?>">
			&nbsp;
			<input type="button" id="btn_sync_x" value="Sync X" onclick="toggleSyncX()" class="<?php if ($saved_sync_x) echo 'btn-yellow'; ?>">
			&nbsp;
			<span id="conv_controls_container" style="display:none;">
				&nbsp;
				<span style="font-weight:bold; color:#bff;">Conv:</span><input type="button" id="btn_conv_none" value="None" onclick="setConversion('none')" class="<?php if ($saved_conv_mode === 'none') echo 'btn-yellow'; ?>"><input type="button" id="btn_conv_ev" value="eV" onclick="setConversion('ev')" class="<?php if ($saved_conv_mode === 'ev') echo 'btn-yellow'; ?>"><input type="button" id="btn_conv_cm1" value="cm&#x207B;&#x00B9;" onclick="setConversion('cm1')" class="<?php if ($saved_conv_mode === 'cm1') echo 'btn-yellow'; ?>">
				&lambda;<sub>0</sub>:<input type="text" id="input_lambda" size=4 value="<?php echo htmlspecialchars($saved_lambda); ?>" title="Center wavelength in nm" onchange="onLambdaChange(this.value)">nm
			</span>
		</div>

		<!-- Plot Windows Stack -->
		<div id="plots_container" style="height:calc(100vh - 43px); display:flex; flex-direction:column; overflow-y:auto; margin:0; padding:0; border:0;">
			<?php for ($w = 1; $w <= 4; $w++): 
				$disp = ($w <= $saved_num_graphs) ? 'flex' : 'none';
				$saved_fwd = $session_window_configs[$w]['fwd'];
				$saved_bwd = $session_window_configs[$w]['bwd'];
			?>
			<div id="plot_window_<?php echo $w; ?>" class="plot_window" style="display:<?php echo $disp; ?>; flex-direction:column; margin:0; padding:0; border:0; border-bottom:1px solid #333; flex:1; min-height:160px; max-height:33.3vh; box-sizing:border-box;">
				
				<!-- Single Flush Controls Row -->
				<div style="margin:0; padding:0; white-space:nowrap; display:flex; align-items:center; line-height:21.6px; border-bottom:1px solid #222;">
					<span>X:</span><select id="sel_x_<?php echo $w; ?>" class="channel_select" onchange="onChannelChange(<?php echo $w; ?>)"></select>&nbsp;<span>Y:</span><select id="sel_y_<?php echo $w; ?>" class="channel_select" onchange="onChannelChange(<?php echo $w; ?>)"></select>
					<input type="button" id="btn_fwd_<?php echo $w; ?>" value="Fwd" onclick="toggleSweep(<?php echo $w; ?>, 'fwd')" class="<?php if ($saved_fwd !== '0') echo 'btn-yellow'; ?>"><input type="button" id="btn_bwd_<?php echo $w; ?>" value="Bwd" onclick="toggleSweep(<?php echo $w; ?>, 'bwd')" class="<?php if ($saved_bwd !== '0') echo 'btn-yellow'; ?>"><input type="button" id="btn_autox_<?php echo $w; ?>" value="AutoX" onclick="toggleAuto(<?php echo $w; ?>, 'x')" class="btn-yellow"><input type="button" id="btn_autoy_<?php echo $w; ?>" value="AutoY" onclick="toggleAuto(<?php echo $w; ?>, 'y')" class="btn-yellow">
					<span id="readout_<?php echo $w; ?>" style="font-family:monospace; color:#0f0; margin-left:auto; padding-right:4px;"></span>
				</div>

				<!-- Plot Canvas Wrapper (Relative with Absolute Canvas for robust flexbox layout) -->
				<div class="canvas_wrapper" style="flex:1; width:100%; min-height:100px; position:relative; overflow:hidden; margin:0; padding:0; border:0;">
					<canvas id="canvas_<?php echo $w; ?>" style="position:absolute; left:0; top:0; width:100%; height:100%; background:#111; cursor:crosshair; margin:0; padding:0; border:0;"></canvas>
				</div>
			</div>
			<?php endfor; ?>
		</div>

	</div>

	<!-- ====================================================================== -->
	<!-- COLUMN 3: CHANNEL CONTROLS, QVUD INFO & CURVE LIST (RIGHT)             -->
	<!-- ====================================================================== -->
	<div id="col_right" style="width:40em; min-width:40em; max-width:40em; flex-shrink:0; flex-grow:0; padding:0; margin:0; overflow:hidden;">
		
		<!-- Scan Channel Thumbnails Row (No horizontal slider overlap) -->
		<div id="channel_thumbnails" style="height:<?php echo $mxh + 2; ?>px; overflow:hidden; white-space:nowrap; margin:0; padding:0; border:0;">
			<?php require('over_imgs.php'); ?>
		</div>

		<!-- Native Navigation Controls & Collapsible Info -->
		<form id="sts_nav_form" method="post" action="sts.php" onsubmit="persistConfig();" style="margin:0; padding:0; display:block;">
			<input type="hidden" name="index" value="<?php echo $index; ?>">
			<input type="hidden" name="nav_cmd" id="nav_cmd" value="">
			<input type="hidden" name="save_cfg_flag" value="1">
			<input type="hidden" name="cfg_num_graphs" value="<?php echo $saved_num_graphs; ?>">
			<input type="hidden" name="cfg_plot_lines" value="<?php echo $saved_plot_lines ? '1' : '0'; ?>">
			<input type="hidden" name="cfg_plot_points" value="<?php echo $saved_plot_points ? '1' : '0'; ?>">
			<input type="hidden" name="cfg_show_info" value="<?php echo $saved_show_info ? '1' : '0'; ?>">
			<input type="hidden" name="cfg_show_spec" value="<?php echo $saved_show_spec ? '1' : '0'; ?>">
			<input type="hidden" name="cfg_sync_x" value="<?php echo $saved_sync_x ? '1' : '0'; ?>">
			<input type="hidden" name="cfg_conv_mode" value="<?php echo htmlspecialchars($saved_conv_mode); ?>">
			<input type="hidden" name="cfg_lambda" value="<?php echo htmlspecialchars($saved_lambda); ?>">
			<input type="hidden" name="cfg_img_width" value="<?php echo $saved_img_w; ?>">
			<input type="hidden" name="cfg_info_height" value="<?php echo $saved_info_h; ?>">
			<input type="hidden" name="cfg_spec_height" value="<?php echo $saved_spec_h; ?>">
			<input type="hidden" name="cfg_color_link" value="<?php echo $saved_color_link ? '1' : '0'; ?>">
			<?php for ($w = 1; $w <= 4; $w++): ?>
			<input type="hidden" name="cfg_g<?php echo $w; ?>_x" value="<?php echo htmlspecialchars($session_window_configs[$w]['x']); ?>">
			<input type="hidden" name="cfg_g<?php echo $w; ?>_y" value="<?php echo htmlspecialchars($session_window_configs[$w]['y']); ?>">
			<input type="hidden" name="cfg_g<?php echo $w; ?>_fwd" value="<?php echo htmlspecialchars($session_window_configs[$w]['fwd']); ?>">
			<input type="hidden" name="cfg_g<?php echo $w; ?>_bwd" value="<?php echo htmlspecialchars($session_window_configs[$w]['bwd']); ?>">
			<?php endfor; ?>
			<div style="margin:0; padding:0; white-space:nowrap; line-height:21.6px;">
				<input tabindex=-1 type="submit" name="prev_sts" id="prev_sts" value="<<<" title="<?php echo ($prev_sts_ch !== null) ? ('Previous STS map: ' . htmlspecialchars($prev_sts_name) . ' (PageUp)') : 'Previous STS map (PageUp)'; ?>"><input tabindex=-1 type="submit" name="prevs" id="prevs" value="<<"><input tabindex=-1 type="submit" name="prev"  id="prev"  value=" < "><input tabindex=-1 type="submit" name="next"  id="next"  value=" > "><input tabindex=-1 type="submit" name="nexts" id="nexts" value=">>"><input tabindex=-1 type="submit" name="next_sts" id="next_sts" value=">>>" title="<?php echo ($next_sts_ch !== null) ? ('Next STS map: ' . htmlspecialchars($next_sts_name) . ' (PageDown)') : 'Next STS map (PageDown)'; ?>"><input type="button" id="btn_info_toggle" value="Info" onclick="toggleInfo(); return false;" class="<?php if ($saved_show_info) echo 'btn-yellow'; ?>"><input type="button" id="btn_sts_info_toggle" value="Spec" onclick="toggleStsInfo(); return false;" class="<?php if ($saved_show_spec) echo 'btn-yellow'; ?>">
			</div>
		</form>

		<!-- Collapsible Info Textarea (qvud style from quickview) -->
		<div id="info_container" style="display:<?php echo $saved_show_info ? 'block' : 'none'; ?>; margin:0; padding:0;">
			<textarea readonly id="qvud" style="width:100%; box-sizing:border-box; height:<?php echo $saved_info_h; ?>px; margin:0; padding:2px; font-family:monospace; font-size:11pt; resize:none; overflow-x:hidden; overflow-y:scroll; background:#f93; color:#000; border:1px solid #444; border-bottom:0; cursor:default;" title="Scan info"><?php foreach($msg as $msgentry) echo htmlspecialchars($msgentry); ?></textarea>
			<div id="qvud_resizer" class="textarea_resizer" title="Drag to resize Info window (double-click to reset)"></div>
		</div>

		<!-- Collapsible Spectroscopy Header Info Textarea -->
		<div id="sts_info_container" style="display:<?php echo $saved_show_spec ? 'block' : 'none'; ?>; margin:0; padding:0;">
			<textarea readonly id="sts_qvud" style="width:100%; box-sizing:border-box; height:<?php echo $saved_spec_h; ?>px; margin:0; padding:2px; font-family:monospace; font-size:11pt; resize:none; overflow-x:hidden; overflow-y:scroll; background:#6cf; color:#000; border:1px solid #444; border-bottom:0; cursor:default;" title="Spectroscopy dat header"></textarea>
			<div id="sts_qvud_resizer" class="textarea_resizer" title="Drag to resize Spec window (double-click to reset)"></div>
		</div>

		<!-- Mask Selection Toolbar (+ and -, akin to browser) -->
		<div id="sts_mask_toolbar" style="margin:0; padding:0; white-space:nowrap; line-height:21.6px;">
			<input type="button" value="All" onclick="selectAllCurves(true)"><input type="button" value="None" onclick="selectAllCurves(false)"><input list="sts_masks" id="mask_input" name="mask" size=5 placeholder="Mask"><input type="button" value=" + " style="width:24px;" onclick="filterMaskSelection('+')"><input type="button" value=" - " style="width:24px;" onclick="filterMaskSelection('-')"><input type="button" id="btn_interactive" value="Interactive" onclick="toggleInteractive();" class="<?php if ($total_map_curves > $sts_max_curves) echo 'btn-yellow'; ?>" title="Toggle Interactive single-curve inspection mode"><input type="button" id="btn_color_link" value="ColorLnk" onclick="toggleColorLink();" class="<?php if ($saved_color_link) echo 'btn-yellow'; ?>" title="Color crosses according to dat file colors">
			<datalist id="sts_masks">
				<option value="BS*">Bias Spectroscopy</option>
				<option value="Bias*">Bias Spectroscopy</option>
				<option value="ZS*">Z Spectroscopy</option>
				<option value="Z-*">Z Spectroscopy</option>
				<option value="AALS*">AALS Spectroscopy</option>
				<option value="LS*">LS Companion Data</option>
				<option value="DL*">Datalogger</option>
			</datalist>
		</div>

		<!-- Curve List Container (Full height, no framing, Explorer multi-select) -->
		<?php $extra_info_h = ($saved_show_info ? ($saved_info_h + 6) : 0) + ($saved_show_spec ? ($saved_spec_h + 6) : 0); ?>
		<div id="curves_container" class="<?php if ($total_map_curves > $sts_max_curves) echo 'interactive-mode'; ?>" onmouseenter="curvesListActive = true;" tabindex="0" onclick="onCurvesContainerClick(event)" style="height:calc(100vh - 20px - <?php echo $mxh + 2; ?>px - <?php echo 43.2 + $extra_info_h; ?>px); overflow-y:auto; margin:0; padding:0; border:0; outline:none; background:#000;">
			<table style="width:100%; border-collapse:collapse; margin:0; padding:0; border:0; table-layout:auto;">
				<tbody id="curves_tbody">
				<?php
				foreach ($map_curves as $k => $mc):
					$fn = $mc['filename'];
					$is_ls = ($has_aals && (stripos($fn, 'LS') === 0 || stripos($fn, 'MLS') === 0));
					$is_checked = $has_explicit_graph ? ($fn === $initial_target_graph) : (($total_map_curves <= $sts_max_curves) && (!$is_ls && $k < $sts_max_curves));
					$file_url = './' . dirname($raw_file) . '/' . $fn;
				?>
				<tr class="curve_row dlist-row" id="row_<?php echo $k; ?>" data-file="<?php echo htmlspecialchars($fn); ?>" data-idx="<?php echo $k; ?>" 
				    onclick="onRowClick(<?php echo $k; ?>, event)" 
				    onmouseover="highlightCurve('<?php echo htmlspecialchars($fn); ?>', true)" 
				    onmousemove="onRowMouseMove('<?php echo htmlspecialchars($fn); ?>', <?php echo $k; ?>)" 
				    onmouseout="highlightCurve('<?php echo htmlspecialchars($fn); ?>', false)"
				    style="margin:0; padding:0; cursor:pointer;">
					<td class="curve_checkbox_cell" style="width:20px; padding:0; margin:0; border:0; text-align:center; vertical-align:middle;">
						<input type="checkbox" id="cb_<?php echo $k; ?>" class="curve_checkbox" value="<?php echo htmlspecialchars($fn); ?>" data-idx="<?php echo $k; ?>" <?php if ($is_checked) echo 'checked'; ?> onclick="onCheckboxClick(<?php echo $k; ?>, event)" style="margin:0; padding:0; vertical-align:middle; cursor:pointer;">
					</td>
					<td style="padding:0 2px; margin:0; border:0; vertical-align:middle; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
						<span class="curve_name" style="font-family:monospace; font-size:11pt; color:#eee;"><?php echo htmlspecialchars($fn); ?></span>
					</td>
					<td style="width:36px; padding:0 2px; margin:0; border:0; text-align:right; vertical-align:middle; white-space:nowrap;">
						<a target="_blank" href="<?php echo htmlspecialchars($file_url); ?>" style="color:#888; font-size:10pt;" onclick="event.stopPropagation();">Open</a>
					</td>
				</tr>
				<?php endforeach; ?>
				</tbody>
			</table>
		</div>
	</div>
</div>

</div>

<!-- ========================================================================== -->
<!-- MODULE 5: JAVASCRIPT ENGINE & INTERACTIONS                                -->
<!-- ========================================================================== -->
<script>
var maxCurvesLimit = <?php echo intval($sts_max_curves); ?>;
var numGraphs = <?php echo $saved_num_graphs; ?>;
var showLines = <?php echo $saved_plot_lines ? 'true' : 'false'; ?>;
var showPoints = <?php echo $saved_plot_points ? 'true' : 'false'; ?>;
var showInfo = <?php echo $saved_show_info ? 'true' : 'false'; ?>;
var showSpec = <?php echo $saved_show_spec ? 'true' : 'false'; ?>;
var syncX = <?php echo $saved_sync_x ? 'true' : 'false'; ?>;
var conversionMode = "<?php echo htmlspecialchars($saved_conv_mode); ?>";
if (conversionMode === 'mev') conversionMode = 'ev';
var centerLambda = <?php echo $saved_lambda; ?>;
var heuristicsTable = <?php echo json_encode($SPECTROSCOPY_HEURISTICS); ?>;
<?php @ini_set('serialize_precision', 8); ?>
var curveCache = <?php echo json_encode($all_curves_data); ?>;
var allCurveFiles = <?php echo json_encode(array_column($map_curves, 'filename')); ?>;
var initialTargetIndex = <?php echo ($target_idx >= 0) ? $target_idx : '-1'; ?>;
var interactiveMode = (allCurveFiles.length > maxCurvesLimit);
var lastKeyNavTime = 0;
var fileIndexMap = {};
for (var fi = 0; fi < allCurveFiles.length; fi++) {
	fileIndexMap[allCurveFiles[fi]] = fi;
}
var prevSelectedSet = new Set();

var savedWindowConfigs = {
<?php for ($w = 1; $w <= 4; $w++): 
	$w_fwd = ($session_window_configs[$w]['fwd'] !== '0');
	$w_bwd = ($session_window_configs[$w]['bwd'] === '1');
?>
	<?php echo $w; ?>: { x: "<?php echo addslashes($session_window_configs[$w]['x']); ?>", y: "<?php echo addslashes($session_window_configs[$w]['y']); ?>", fwd: <?php echo $w_fwd ? 'true' : 'false'; ?>, bwd: <?php echo $w_bwd ? 'true' : 'false'; ?> }<?php echo ($w < 4) ? ',' : ''; ?>
<?php endfor; ?>
};

var selectedCurveFiles = []; // ordered list of selected filenames
var lastAnchorIndex = 0;
var focusedRowIndex = 0;
var curvesListActive = false;
var hoveredCurveFile = null;

// Track focus between scan channel navigation and spectroscopy workstation
document.addEventListener('mousedown', function(e) {
	if (e.target.closest('#curves_container')) {
		// Handled by curves container click or row click
		curvesListActive = true;
	} else if (e.target.closest('#plots_container') || 
	           e.target.closest('#graphs_toolbar') || 
	           e.target.closest('#sts_mask_toolbar') || 
	           e.target.closest('#sts_info_container') || 
	           e.target.closest('#image_container') || 
	           e.target.closest('.sts_dot')) {
		curvesListActive = true;
		if (focusedRowIndex < 0 || focusedRowIndex >= allCurveFiles.length) {
			setHighlightRow(0);
		} else {
			updateRowFocusVisual();
		}
	} else if (e.target.closest('#channel_thumbnails') || 
	           e.target.closest('#sts_nav_form')) {
		curvesListActive = false;
		updateRowFocusVisual();
		updateStsDotHighlight(null);
		if (hoveredCurveFile) {
			hoveredCurveFile = null;
			renderAllPlots();
		}
	}
});

// Unified global sync X bounds and crosshair cursor
var globalCursorValX = null;

// Per-window state: sweeps, autoscale toggles, view bounds, mouse drag
var windowStates = {
<?php for ($w = 1; $w <= 4; $w++): 
	$w_fwd = ($session_window_configs[$w]['fwd'] !== '0');
	$w_bwd = ($session_window_configs[$w]['bwd'] === '1');
?>
	<?php echo $w; ?>: { fwd: <?php echo $w_fwd ? 'true' : 'false'; ?>, bwd: <?php echo $w_bwd ? 'true' : 'false'; ?>, autoX: true, autoY: true, xMin: null, xMax: null, yMin: null, yMax: null, boxZoom: null, measureBox: null }<?php echo ($w < 4) ? ',' : ''; ?>
<?php endfor; ?>
};

// Group-based static colormap engine (rainbow per file group, persistent on select/deselect)
var fileColorMap = {};

function getCurveFileGroup(fn) {
	if (!fn) return '';
	var base = fn.replace(/^.*[\/\\]/, '').trim();
	base = base.replace(/\.[^.]+$/, '');
	var group = base.replace(/\d+$/, '');
	return group;
}

function initCurveColors() {
	fileColorMap = {};
	var groups = {};
	var groupOrder = [];

	allCurveFiles.forEach(function(fn) {
		var g = getCurveFileGroup(fn);
		if (!groups[g]) {
			groups[g] = [];
			groupOrder.push(g);
		}
		groups[g].push(fn);
	});

	groupOrder.forEach(function(g) {
		var files = groups[g];
		var n = files.length;
		files.forEach(function(fn, k) {
			if (n <= 1) {
				fileColorMap[fn] = '#00ff41';
			} else {
				var hue = Math.round((k / n) * 360);
				fileColorMap[fn] = 'hsl(' + hue + ', 100%, 55%)';
			}
		});
	});
}

function getCurveColor(fn) {
	if (typeof fn === 'string') {
		return fileColorMap[fn] || '#00ff41';
	}
	return '#00ff41';
}

function getCurveColorMap() {
	return fileColorMap;
}

// Pre-index channel keys for all curves to eliminate regex searching during redraws
function initCurveChannelLookups() {
	allCurveFiles.forEach(function(fn) {
		var curve = curveCache[fn];
		if (!curve || !curve.data) return;
		curve._keyMapFwd = {};
		curve._keyMapBwd = {};
		var rawKeys = Object.keys(curve.data);
		rawKeys.forEach(function(k) {
			var isBwd = (k.indexOf('[bwd]') !== -1 || k.indexOf('[backward]') !== -1 || k.indexOf('(bwd)') !== -1);
			var base = k.replace(/\s*\[(bwd|backward|fwd|forward)\]/i, '').replace(/\s*\((bwd|backward|fwd|forward)\)/i, '').trim();
			var baseLower = base.toLowerCase();
			if (isBwd) {
				curve._keyMapBwd[base] = k;
				curve._keyMapBwd[baseLower] = k;
			} else {
				curve._keyMapFwd[base] = k;
				curve._keyMapFwd[baseLower] = k;
			}
		});
	});
}

// Generate slightly darker solid color variant for backward sweeps
function darkenColor(col, factor) {
	if (!col) return '#008820';
	if (factor === undefined) factor = 0.65;
	if (col.startsWith('hsl')) {
		var m = col.match(/hsl\(\s*([\d\.]+)\s*,\s*([\d\.]+)%\s*,\s*([\d\.]+)%\s*\)/i);
		if (m) {
			var h = m[1];
			var s = m[2];
			var l = parseFloat(m[3]);
			var newL = Math.max(10, Math.round(l * factor));
			return 'hsl(' + h + ', ' + s + '%, ' + newL + '%)';
		}
	} else if (col.startsWith('#')) {
		var hex = col.replace('#', '');
		if (hex.length === 3) hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
		var num = parseInt(hex, 16);
		if (!isNaN(num)) {
			var r = Math.max(0, Math.min(255, Math.round(((num >> 16) & 255) * factor)));
			var g = Math.max(0, Math.min(255, Math.round(((num >> 8) & 255) * factor)));
			var b = Math.max(0, Math.min(255, Math.round((num & 255) * factor)));
			return 'rgb(' + r + ',' + g + ',' + b + ')';
		}
	}
	return col;
}

// Update list checkbox background colors dynamically & highlight selected rows
function updateListColors() {
	var colorMap = getCurveColorMap();
	var selSet = new Set(selectedCurveFiles);
	var affectedFiles = new Set([...prevSelectedSet, ...selSet]);

	affectedFiles.forEach(function(fn) {
		var idx = fileIndexMap[fn];
		if (idx !== undefined && idx !== -1) {
			var cb = document.getElementById('cb_' + idx);
			var row = document.getElementById('row_' + idx);
			var isSel = selSet.has(fn);
			if (cb && isSel && colorMap[fn]) {
				var col = colorMap[fn];
				cb.style.backgroundColor = col;
				cb.style.accentColor = col;
				if (row) row.classList.add('is-selected');
			} else {
				if (cb) {
					cb.style.backgroundColor = '';
					cb.style.accentColor = '';
				}
				if (row) row.classList.remove('is-selected');
			}
		}
	});

	prevSelectedSet = selSet;

	// Synchronize STS point highlights on image: default order is curve file order (earliest bottommost)
	document.querySelectorAll('.sts_dot').forEach(function(dot) {
		var df = dot.getAttribute('data-file');
		var isSel = selSet.has(df);
		if (isSel) {
			dot.classList.add('is-selected');
			dot.classList.remove('is-unselected');
		} else {
			dot.classList.remove('is-selected');
			dot.classList.add('is-unselected');
		}

		var isHl = dot.classList.contains('is-highlighted');
		if (!isHl) {
			var idx = parseInt(dot.getAttribute('data-idx') || '0', 10);
			dot.style.zIndex = 10 + idx;
		}

		if (colorLink) {
			var col = fileColorMap[df] || '#00ff41';
			dot.querySelectorAll('line').forEach(function(l) {
				l.style.stroke = col;
			});
			dot.style.opacity = isSel ? '1.0' : '0.4';
		} else {
			dot.querySelectorAll('line').forEach(function(l) {
				l.style.stroke = '';
			});
			dot.style.opacity = '1.0';
		}
	});
}

var colorLink = <?php echo $saved_color_link ? 'true' : 'false'; ?>;

function toggleColorLink() {
	colorLink = !colorLink;
	updateColorLinkVisual();
	updateListColors();
	persistConfig();
}

function updateColorLinkVisual() {
	var btn = document.getElementById('btn_color_link');
	if (btn) {
		if (colorLink) btn.classList.add('btn-yellow');
		else btn.classList.remove('btn-yellow');
	}
}

function toggleInteractive() {
	setInteractiveMode(!interactiveMode);
}

function setInteractiveMode(enabled) {
	interactiveMode = enabled;
	try {
		sessionStorage.setItem('wspa_sts_interactive', interactiveMode ? '1' : '0');
	} catch (e) {}
	var btn = document.getElementById('btn_interactive');
	var cont = document.getElementById('curves_container');
	if (btn) {
		if (interactiveMode) btn.classList.add('btn-yellow');
		else btn.classList.remove('btn-yellow');
	}
	if (cont) {
		if (interactiveMode) cont.classList.add('interactive-mode');
		else cont.classList.remove('interactive-mode');
	}
	updateRowFocusVisual();
	onSelectionModified();
}

function getActiveCurvesToPlot() {
	if (interactiveMode) {
		var activeFn = (allCurveFiles.length > 0 && focusedRowIndex >= 0 && focusedRowIndex < allCurveFiles.length) ? allCurveFiles[focusedRowIndex] : (hoveredCurveFile || (allCurveFiles.length > 0 ? allCurveFiles[0] : null));
		return activeFn ? [activeFn] : [];
	}
	return selectedCurveFiles;
}

var scanImgW = <?php echo $img_w; ?>;
var scanImgH = <?php echo $img_h; ?>;
var currentImgWidth = <?php echo $display_w; ?>;

function setImageColumnWidth(newW) {
	var minW = 200;
	var maxW = Math.max(minW, window.innerWidth - 650);
	newW = Math.max(minW, Math.min(maxW, Math.round(newW)));
	currentImgWidth = newW;

	var colSpec = document.getElementById('col_left_spec');
	var colLeft = document.getElementById('col_left');
	var imgCont = document.getElementById('image_container');
	var scanImg = document.getElementById('scan_img');

	var newH = Math.max(1, Math.round(newW * (scanImgH / scanImgW)));

	if (colSpec) {
		colSpec.style.width = newW + 'px';
	}
	if (colLeft) {
		colLeft.style.width = newW + 'px';
		colLeft.style.maxWidth = newW + 'px';
	}
	if (imgCont) {
		imgCont.style.width = newW + 'px';
		imgCont.style.height = newH + 'px';
	}
	if (scanImg) {
		scanImg.style.width = '100%';
		scanImg.style.height = 'auto';
		scanImg.width = newW;
		scanImg.height = newH;
	}

	updateStsDotPositions(newH);
	requestRenderAll();
}

var stsPointsCache = [];

function initStsPointsCache() {
	stsPointsCache = [];
	document.querySelectorAll('.sts_dot').forEach(function(dot) {
		var fx = parseFloat(dot.getAttribute('data-frac-x'));
		var fy = parseFloat(dot.getAttribute('data-frac-y'));
		var fn = dot.getAttribute('data-file');
		var idx = parseInt(dot.getAttribute('data-idx') || '0', 10);
		var baseZ = parseInt(dot.getAttribute('data-base-z') || '10', 10);
		var isAux = (baseZ < 2000);
		if (!isNaN(fx) && !isNaN(fy) && fn) {
			stsPointsCache.push({
				fn: fn,
				idx: idx,
				fx: fx,
				fy: fy,
				isAux: isAux
			});
		}
	});
}

function getNearestStsPoint(mx, my, curH) {
	if (!stsPointsCache || stsPointsCache.length === 0) initStsPointsCache();
	if (!stsPointsCache || stsPointsCache.length === 0) return null;
	var bestItem = null;
	var bestDistSq = Infinity;

	for (var i = 0; i < stsPointsCache.length; i++) {
		var pt = stsPointsCache[i];
		var px = pt.fx * curH;
		var py = curH - (pt.fy * curH);
		var dx = mx - px;
		var dy = my - py;
		var d2 = dx * dx + dy * dy;

		if (d2 < bestDistSq) {
			bestDistSq = d2;
			bestItem = pt;
		} else if (d2 === bestDistSq && bestItem && bestItem.isAux && !pt.isAux) {
			// Primary curves take precedence over companion auxiliary curves at identical coordinates
			bestItem = pt;
		}
	}
	return bestItem;
}

function updateStsDotPositions(curH) {
	document.querySelectorAll('.sts_dot').forEach(function(dot) {
		var fx = parseFloat(dot.getAttribute('data-frac-x'));
		var fy = parseFloat(dot.getAttribute('data-frac-y'));
		if (!isNaN(fx) && !isNaN(fy)) {
			var pxLeft = Math.round(fx * curH - 4);
			var pxTop  = Math.round(curH - (fy * curH) - 4);
			dot.style.left = pxLeft + 'px';
			dot.style.top  = pxTop + 'px';
		}
	});
	var scanDirImg = document.getElementById('scan_dir_img');
	if (scanDirImg && scanDirImg.getAttribute('data-dir') === 'up') {
		scanDirImg.style.top = (curH - 17) + 'px';
	}
}

function setupImageColumnResizer() {
	var splitter = document.getElementById('col_splitter');
	if (!splitter) return;

	var startX = 0;
	var startW = 0;

	function onMouseMove(e) {
		var dx = e.clientX - startX;
		setImageColumnWidth(startW + dx);
	}

	function onMouseUp(e) {
		splitter.classList.remove('is-dragging');
		document.removeEventListener('mousemove', onMouseMove);
		document.removeEventListener('mouseup', onMouseUp);
		persistConfig();
	}

	splitter.addEventListener('mousedown', function(e) {
		if (e.button !== 0) return;
		e.preventDefault();
		startX = e.clientX;
		var colLeft = document.getElementById('col_left');
		startW = colLeft ? colLeft.getBoundingClientRect().width : currentImgWidth;
		currentImgWidth = Math.round(startW);
		splitter.classList.add('is-dragging');
		document.addEventListener('mousemove', onMouseMove);
		document.addEventListener('mouseup', onMouseUp);
	});

	splitter.addEventListener('dblclick', function(e) {
		e.preventDefault();
		setImageColumnWidth(400);
		persistConfig();
	});
}

function setupTextareaResizer(resizerId, textareaId) {
	var resizer = document.getElementById(resizerId);
	var ta = document.getElementById(textareaId);
	if (!resizer || !ta) return;

	var startY = 0;
	var startH = 0;

	function onMouseMove(e) {
		var dy = e.clientY - startY;
		var newH = Math.max(50, Math.min(window.innerHeight - 200, startH + dy));
		ta.style.height = newH + 'px';
		updateCurvesContainerHeight();
	}

	function onMouseUp(e) {
		resizer.classList.remove('is-dragging');
		document.removeEventListener('mousemove', onMouseMove);
		document.removeEventListener('mouseup', onMouseUp);
		updateCurvesContainerHeight();
		persistConfig();
	}

	resizer.addEventListener('mousedown', function(e) {
		if (e.button !== 0) return;
		e.preventDefault();
		startY = e.clientY;
		startH = ta.offsetHeight;
		resizer.classList.add('is-dragging');
		document.addEventListener('mousemove', onMouseMove);
		document.addEventListener('mouseup', onMouseUp);
	});

	resizer.addEventListener('dblclick', function(e) {
		e.preventDefault();
		ta.style.height = '140px';
		updateCurvesContainerHeight();
		persistConfig();
	});
}

function updateCurvesContainerHeight() {
	var cont = document.getElementById('curves_container');
	if (!cont) return;
	var baseH = <?php echo $mxh + 2; ?> + 43.2 + 20;
	var info1 = document.getElementById('info_container');
	var info2 = document.getElementById('sts_info_container');
	var extra = 0;
	if (info1 && info1.style.display !== 'none') extra += (info1.offsetHeight || 144);
	if (info2 && info2.style.display !== 'none') extra += (info2.offsetHeight || 144);
	cont.style.height = 'calc(100vh - ' + (baseH + extra) + 'px)';
}

// Toggle collapsible info textarea (qvud)
function toggleInfo() {
	var container = document.getElementById('info_container');
	var btn = document.getElementById('btn_info_toggle');
	if (!container) return;
	if (container.style.display === 'none' || container.style.display === '') {
		container.style.display = 'block';
		showInfo = true;
		if (btn) btn.classList.add('btn-yellow');
	} else {
		container.style.display = 'none';
		showInfo = false;
		if (btn) btn.classList.remove('btn-yellow');
	}
	updateCurvesContainerHeight();
	persistConfig();
}

// Toggle collapsible spectroscopy header info textarea (sts_qvud)
function toggleStsInfo() {
	var container = document.getElementById('sts_info_container');
	var btn = document.getElementById('btn_sts_info_toggle');
	if (!container) return;
	if (container.style.display === 'none' || container.style.display === '') {
		container.style.display = 'block';
		showSpec = true;
		if (btn) btn.classList.add('btn-yellow');
		var curFn = (allCurveFiles.length > 0) ? (allCurveFiles[focusedRowIndex] || selectedCurveFiles[0] || allCurveFiles[0]) : '';
		if (curFn) updateStsInfo(curFn);
	} else {
		container.style.display = 'none';
		showSpec = false;
		if (btn) btn.classList.remove('btn-yellow');
	}
	updateCurvesContainerHeight();
	persistConfig();
}

// Update spectroscopy info textarea with .dat header synchronously (No AJAX - Rule 16)
function updateStsInfo(fn) {
	var ta = document.getElementById('sts_qvud');
	if (!ta) return;
	if (!fn) {
		ta.value = '';
		return;
	}
	var curve = curveCache[fn];
	if (curve && curve.header) {
		var hdrText = Array.isArray(curve.header) ? curve.header.join('') : curve.header;
		ta.value = fn + "\n" + hdrText;
	} else {
		ta.value = fn + "\n(No header available)";
	}
}

// Row click with Explorer-like selection (Ctrl, Shift, Normal toggle)
function onRowClick(idx, evt) {
	if (evt.target.tagName === 'INPUT' || evt.target.tagName === 'A') return;
	var fn = allCurveFiles[idx];
	if (!fn) return;

	if (interactiveMode) {
		setHighlightRow(idx);
		return;
	}

	if (!curveCache[fn]) {
		try {
			var cont = document.getElementById('curves_container');
			if (cont) sessionStorage.setItem('wspa_sts_scroll_top', cont.scrollTop);
		} catch (e) {}
		window.location.href = 'sts.php?graph=' + encodeURIComponent(fn);
		return;
	}

	if (evt.shiftKey) {
		selectRange(lastAnchorIndex, idx);
	} else {
		toggleFileSelection(fn);
	}
	setHighlightRow(idx);
}

// Checkbox click handler
function onCheckboxClick(idx, evt) {
	evt.stopPropagation();
	if (interactiveMode) {
		evt.preventDefault();
		return;
	}
	var fn = allCurveFiles[idx];
	if (!fn) return;

	var isCurrentlySelected = (selectedCurveFiles.indexOf(fn) !== -1);
	if (!isCurrentlySelected && selectedCurveFiles.length >= maxCurvesLimit) {
		evt.preventDefault();
		setCheckboxDOM(fn, false);
		return;
	}

	toggleFileSelection(fn);
	setHighlightRow(idx);
}

// Point click on left image
function onPointClick(fn, evt) {
	if (interactiveMode) return;
	var idx = (fileIndexMap && fileIndexMap[fn] !== undefined) ? fileIndexMap[fn] : allCurveFiles.indexOf(fn);
	toggleFileSelection(fn);
	if (idx !== -1) {
		setHighlightRow(idx);
	}
}

// Toggle individual file selection
function toggleFileSelection(fn) {
	if (interactiveMode) return;
	var pos = selectedCurveFiles.indexOf(fn);
	if (pos !== -1) {
		selectedCurveFiles.splice(pos, 1);
		setCheckboxDOM(fn, false);
	} else {
		if (selectedCurveFiles.length >= maxCurvesLimit) return; // Silently cap at maxCurvesLimit (16)
		selectedCurveFiles.push(fn);
		setCheckboxDOM(fn, true);
	}
	onSelectionModified();
}

// Exclusive single selection
function setExclusiveSelection(fn) {
	selectedCurveFiles.forEach(function(f) { setCheckboxDOM(f, false); });
	selectedCurveFiles = [fn];
	setCheckboxDOM(fn, true);
	onSelectionModified();
}

// Select range between two indices
function selectRange(fromIdx, toIdx) {
	if (interactiveMode) return;
	var start = Math.min(fromIdx, toIdx);
	var end = Math.max(fromIdx, toIdx);

	for (var i = start; i <= end; i++) {
		var fn = allCurveFiles[i];
		if (selectedCurveFiles.indexOf(fn) === -1) {
			if (selectedCurveFiles.length >= maxCurvesLimit) break;
			selectedCurveFiles.push(fn);
			setCheckboxDOM(fn, true);
		}
	}
	onSelectionModified();
}

function setCheckboxDOM(fn, checked) {
	var idx = allCurveFiles.indexOf(fn);
	if (idx !== -1) {
		var cb = document.getElementById('cb_' + idx);
		if (cb) cb.checked = checked;
	}
}

// Select All / None
function selectAllCurves(enable) {
	if (interactiveMode) return;
	if (enable) {
		selectedCurveFiles = [];
		for (var i = 0; i < allCurveFiles.length; i++) {
			if (selectedCurveFiles.length >= maxCurvesLimit) break;
			var fn = allCurveFiles[i];
			selectedCurveFiles.push(fn);
			setCheckboxDOM(fn, true);
		}
	} else {
		selectedCurveFiles.forEach(function(f) { setCheckboxDOM(f, false); });
		selectedCurveFiles = [];
	}
	onSelectionModified();
}

// Wildcard mask selection (+ / -)
function filterMaskSelection(action) {
	if (interactiveMode) return;
	var input = document.getElementById('mask_input');
	var pattern = input ? input.value.trim() : '';
	if (!pattern) pattern = '*';

	allCurveFiles.forEach(function(fn) {
		if (fnmatchWildcard(pattern, fn)) {
			if (action === '+') {
				if (selectedCurveFiles.indexOf(fn) === -1) {
					if (selectedCurveFiles.length >= maxCurvesLimit) return;
					selectedCurveFiles.push(fn);
					setCheckboxDOM(fn, true);
				}
			} else if (action === '-' || action === '0') {
				var pos = selectedCurveFiles.indexOf(fn);
				if (pos !== -1) {
					selectedCurveFiles.splice(pos, 1);
					setCheckboxDOM(fn, false);
				}
			}
		}
	});
	onSelectionModified();
}

function fnmatchWildcard(pattern, str) {
	var parts = pattern.split(/[,|;]/);
	for (var p = 0; p < parts.length; p++) {
		var pt = parts[p].trim();
		if (!pt) continue;
		var regStr = '^' + pt.replace(/([.+^${}()|[\]\\])/g, '\\$1').replace(/\*/g, '.*').replace(/\?/g, '.') + '$';
		if (new RegExp(regStr, 'i').test(str)) return true;
	}
	return false;
}

function updateRowFocusVisual() {
	var rows = document.querySelectorAll('.curve_row');
	rows.forEach(function(r) {
		r.classList.remove('is-highlighted');
		r.style.outline = '';
	});
	if (curvesListActive && focusedRowIndex >= 0 && focusedRowIndex < allCurveFiles.length) {
		var curRow = document.getElementById('row_' + focusedRowIndex);
		if (curRow) {
			curRow.classList.add('is-highlighted');
			curRow.style.outline = '1px dotted #ffcccc';
			curRow.style.outlineOffset = '-1px';
		}
	}
}

function updateStsDotHighlight(activeFn) {
	document.querySelectorAll('.sts_dot').forEach(function(dot) {
		var df = dot.getAttribute('data-file');
		var isMatch = (df === activeFn);
		if (isMatch) {
			dot.classList.add('is-highlighted');
			dot.style.zIndex = 10000;
			dot.style.opacity = '1.0';
		} else {
			dot.classList.remove('is-highlighted');
			var baseZ = parseInt(dot.getAttribute('data-base-z') || '10', 10);
			dot.style.zIndex = baseZ;
			if (colorLink) {
				var isSelected = dot.classList.contains('is-selected');
				dot.style.opacity = isSelected ? '1.0' : '0.4';
			} else {
				dot.style.opacity = '1.0';
			}
		}
	});
}

var lastActiveChannelsSig = '';

function checkChannelSignatureChange() {
	var avail = getAvailableChannels();
	var sig = avail.join('|');
	if (sig !== lastActiveChannelsSig) {
		lastActiveChannelsSig = sig;
		updateChannelDropdowns();
		return true;
	}
	return false;
}

function setHighlightRow(idx) {
	if (allCurveFiles.length === 0) return;
	idx = Math.max(0, Math.min(allCurveFiles.length - 1, idx));
	focusedRowIndex = idx;
	lastAnchorIndex = idx;
	curvesListActive = true;

	updateRowFocusVisual();
	scrollRowIntoView(idx);

	var fn = allCurveFiles[idx];
	if (fn) {
		updateStsInfo(fn);
		updateStsDotHighlight(fn);
		hoveredCurveFile = fn;
		checkChannelSignatureChange();
		renderAllPlots();
	}

	var cont = document.getElementById('curves_container');
	if (cont && document.activeElement !== cont) {
		cont.focus();
	}
}

function onCurvesContainerClick(evt) {
	if (evt.target.closest('.curve_row')) return;
	setHighlightRow(0);
}

function onRowMouseMove(fn, idx) {
	curvesListActive = true;
	if (Date.now() - lastKeyNavTime < 150) return;
	if (focusedRowIndex !== idx) {
		focusedRowIndex = idx;
		lastAnchorIndex = idx;
		updateRowFocusVisual();
	}
	if (hoveredCurveFile !== fn) {
		highlightCurve(fn, true);
	}
}

function highlightCurve(fn, active) {
	if (active) {
		var idx = (fileIndexMap && fileIndexMap[fn] !== undefined) ? fileIndexMap[fn] : allCurveFiles.indexOf(fn);
		if (idx !== -1) {
			focusedRowIndex = idx;
			lastAnchorIndex = idx;
			updateRowFocusVisual();
			if (Date.now() - lastKeyNavTime >= 150) {
				scrollRowIntoView(idx);
			}
		}
		document.querySelectorAll('.curve_row').forEach(function(row) {
			if (row.getAttribute('data-file') === fn) {
				row.classList.add('is-highlighted');
			} else if (!interactiveMode || row.getAttribute('data-idx') != focusedRowIndex) {
				row.classList.remove('is-highlighted');
			}
		});
		updateStsDotHighlight(fn);
		hoveredCurveFile = fn;
		updateStsInfo(fn);
		checkChannelSignatureChange();
		renderAllPlots();
	} else {
		// If mouseout is from a dot moving within the image container, do not clear hover
		if (window.event && window.event.relatedTarget && window.event.relatedTarget.closest && window.event.relatedTarget.closest('#image_container')) {
			return;
		}
		// Mouseout: when mouse moves away from crosses or files, in interactive mode retain the last curve on which the mouse was
		if (hoveredCurveFile === fn || hoveredCurveFile !== null) {
			hoveredCurveFile = null;
			updateRowFocusVisual();
			if (allCurveFiles[focusedRowIndex]) {
				updateStsDotHighlight(interactiveMode ? allCurveFiles[focusedRowIndex] : null);
				updateStsInfo(allCurveFiles[focusedRowIndex]);
				checkChannelSignatureChange();
			} else {
				updateStsDotHighlight(null);
			}
			renderAllPlots();
		}
	}
}

function clearHoverHighlights() {
	hoveredCurveFile = null;
	updateRowFocusVisual();
	if (interactiveMode && allCurveFiles[focusedRowIndex]) {
		updateStsDotHighlight(allCurveFiles[focusedRowIndex]);
		checkChannelSignatureChange();
	} else {
		updateStsDotHighlight(null);
	}
	renderAllPlots();
}

// Selection modified: synchronous update (No AJAX - Rule 16)
function onSelectionModified() {
	lastActiveChannelsSig = getAvailableChannels().join('|');
	updateListColors();
	updateChannelDropdowns();
	renderAllPlots();
}

function getAvailableChannels() {
	var set = new Set();
	var activeCurves = getActiveCurvesToPlot();
	if (activeCurves.length > 0) {
		activeCurves.forEach(function(fn) {
			var c = curveCache[fn];
			if (c && c.chan) {
				c.chan.forEach(function(ch) {
					var base = ch.replace(/\s*\[(bwd|backward|fwd|forward)\]/i, '').trim();
					if (base !== '') set.add(base);
				});
			}
		});
	}
	if (set.size === 0 && allCurveFiles.length > 0) {
		var c0 = curveCache[allCurveFiles[0]];
		if (c0 && c0.chan) {
			c0.chan.forEach(function(ch) {
				var base = ch.replace(/\s*\[(bwd|backward|fwd|forward)\]/i, '').trim();
				if (base !== '') set.add(base);
			});
		}
	}
	return Array.from(set);
}

function matchChannelWildcard(str, pattern) {
	if (!str || !pattern) return false;
	str = String(str).trim();
	pattern = String(pattern).trim();
	if (pattern === '*' || pattern === '') return true;
	if (pattern.indexOf('*') === -1 && pattern.indexOf('?') === -1) {
		return str.toLowerCase().indexOf(pattern.toLowerCase()) !== -1;
	}
	var reStr = '^' + pattern.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*').replace(/\?/g, '.') + '$';
	return new RegExp(reStr, 'i').test(str);
}

function getActiveRuleKey() {
	var activeCurves = getActiveCurvesToPlot();
	var sample = (activeCurves.length > 0) ? activeCurves[0] : (allCurveFiles.length > 0 ? allCurveFiles[0] : '');
	if (!sample) return 'default';
	for (var i = 0; i < heuristicsTable.length; i++) {
		var rule = heuristicsTable[i];
		if (rule.patterns && rule.patterns.length > 0) {
			for (var pi = 0; pi < rule.patterns.length; pi++) {
				if (matchChannelWildcard(sample, rule.patterns[pi])) {
					return rule.patterns.join('|');
				}
			}
		} else if (rule.mask) {
			var re = new RegExp(rule.mask.replace(/^\/|\/[a-z]*$/gi, ''), 'i');
			if (re.test(sample)) return rule.mask;
		}
	}
	return 'default';
}

function saveUserTypeChannel(winIdx, axis, val) {
	try {
		var rk = getActiveRuleKey();
		var mem = JSON.parse(sessionStorage.getItem('wspa_sts_type_channels') || '{}');
		if (!mem[rk]) mem[rk] = {};
		if (!mem[rk]['g' + winIdx]) mem[rk]['g' + winIdx] = {};
		mem[rk]['g' + winIdx][axis] = val;
		sessionStorage.setItem('wspa_sts_type_channels', JSON.stringify(mem));
	} catch (e) {}
}

function getUserTypeChannel(winIdx, axis) {
	try {
		var rk = getActiveRuleKey();
		var mem = JSON.parse(sessionStorage.getItem('wspa_sts_type_channels') || '{}');
		if (mem[rk] && mem[rk]['g' + winIdx] && mem[rk]['g' + winIdx][axis]) {
			return mem[rk]['g' + winIdx][axis];
		}
	} catch (e) {}
	return null;
}

function getHeuristicChannel(winIdx, axis) {
	var activeCurves = getActiveCurvesToPlot();
	if (activeCurves.length === 0 && allCurveFiles.length === 0) return '';
	var sample = (activeCurves.length > 0) ? activeCurves[0] : allCurveFiles[0];
	var avail = getAvailableChannels();
	if (avail.length === 0) return '';

	// Channels already chosen by preceding windows for the same axis (for Y deduplication)
	var usedChannels = [];
	if (axis === 'y') {
		for (var prevW = 1; prevW < winIdx; prevW++) {
			var prevSel = document.getElementById('sel_y_' + prevW);
			if (prevSel && prevSel.value) {
				usedChannels.push(prevSel.value);
			}
		}
	}

	for (var i = 0; i < heuristicsTable.length; i++) {
		var rule = heuristicsTable[i];
		var matchedFile = false;
		if (rule.patterns && rule.patterns.length > 0) {
			for (var pi = 0; pi < rule.patterns.length; pi++) {
				if (matchChannelWildcard(sample, rule.patterns[pi])) {
					matchedFile = true;
					break;
				}
			}
		} else if (rule.mask) {
			var re = new RegExp(rule.mask.replace(/^\/|\/[a-z]*$/gi, ''), 'i');
			if (re.test(sample)) matchedFile = true;
		}

		if (matchedFile) {
			var winRule = (rule.windows && rule.windows[winIdx - 1]) ? rule.windows[winIdx - 1] : ((rule.windows && rule.windows[0]) ? rule.windows[0] : null);
			if (!winRule) continue;
			var target = (axis === 'x') ? winRule.x : winRule.y;
			if (target === undefined || target === null) continue;

			// Direct integer index (e.g. "0", "1", 2)
			if (typeof target === 'number' || (/^\d+$/.test(String(target).trim()) && parseInt(target, 10) < avail.length)) {
				var idx = parseInt(target, 10);
				return avail[idx] || avail[0];
			}

			var targetStr = String(target).trim();
			var parts = targetStr.split('|');

			for (var p = 0; p < parts.length; p++) {
				var cand = parts[p].trim();
				if (!cand) continue;

				// Check for occurrence index, e.g. *Input*#2 or *Counter*#1
				var occMatch = cand.match(/#(\d+)$/);
				var occurrence = occMatch ? parseInt(occMatch[1], 10) : 0;
				var cleanCand = occMatch ? cand.replace(/#\d+$/, '').trim() : cand;

				// 1. Find all matching channels with specificity scoring
				var exactMatches = [];
				var prefixMatches = [];
				var wildcardMatches = [];

				for (var a = 0; a < avail.length; a++) {
					var ch = avail[a];
					var chBase = ch.replace(/\s*\([^)]*\)\s*$/, '').trim();
					var patBase = cleanCand.replace(/^\*+|\*+$/g, '').trim();

					if (patBase && chBase.toLowerCase() === patBase.toLowerCase()) {
						exactMatches.push(ch);
					} else if (patBase && chBase.toLowerCase().indexOf(patBase.toLowerCase()) === 0) {
						prefixMatches.push(ch);
					} else if (matchChannelWildcard(ch, cleanCand)) {
						wildcardMatches.push(ch);
					}
				}

				// Combined matches ordered by specificity: exact, prefix, wildcard
				var allMatches = [];
				[exactMatches, prefixMatches, wildcardMatches].forEach(function(list) {
					list.forEach(function(item) {
						if (allMatches.indexOf(item) === -1) allMatches.push(item);
					});
				});

				// Fallback to normalized alphanumeric matching if no direct wildcard match
				if (allMatches.length === 0) {
					var candNorm = cleanCand.toLowerCase().replace(/[^a-z0-9]/g, '');
					if (candNorm !== '') {
						for (var a = 0; a < avail.length; a++) {
							var availNorm = avail[a].toLowerCase().replace(/[^a-z0-9]/g, '');
							if (availNorm.indexOf(candNorm) !== -1 || candNorm.indexOf(availNorm) !== -1) {
								allMatches.push(avail[a]);
							}
						}
					}
				}

				if (allMatches.length > 0) {
					// If explicit occurrence #N was requested:
					if (occurrence > 0) {
						if (occurrence <= allMatches.length) return allMatches[occurrence - 1];
						return allMatches[allMatches.length - 1];
					}

					// Cross-window deduplication for Y: pick the first match not already taken by preceding windows
					if (axis === 'y') {
						for (var m = 0; m < allMatches.length; m++) {
							if (usedChannels.indexOf(allMatches[m]) === -1) {
								return allMatches[m];
							}
						}
					}
					// If all are already taken or axis is X, return the primary match
					return allMatches[0];
				}
			}
		}
	}

	// Global fallback if no rule matched
	return (axis === 'x') ? avail[0] : (avail[1] || avail[0]);
}

function updateChannelDropdowns() {
	var avail = getAvailableChannels();
	for (var w = 1; w <= 4; w++) {
		var selX = document.getElementById('sel_x_' + w);
		var selY = document.getElementById('sel_y_' + w);
		if (!selX || !selY) continue;

		var prevX = selX.value;
		var prevY = selY.value;

		selX.innerHTML = '';
		selY.innerHTML = '';

		avail.forEach(function(ch) {
			var oX = document.createElement('option');
			oX.value = ch; oX.text = ch;
			selX.appendChild(oX);

			var oY = document.createElement('option');
			oY.value = ch; oY.text = ch;
			selY.appendChild(oY);
		});

		var userX = getUserTypeChannel(w, 'x');
		var userY = getUserTypeChannel(w, 'y');

		// Channel Preservation First:
		// 1. If user previously chose a channel for this specific curve type and it exists in avail, use it
		// 2. Otherwise, if current dropdown selection (prevX/prevY) exists in avail, preserve it
		// 3. Otherwise, fall back to declarative heuristic from sts_channels.cfg
		if (userX && avail.indexOf(userX) !== -1) {
			selX.value = userX;
		} else if (prevX && avail.indexOf(prevX) !== -1) {
			selX.value = prevX;
		} else {
			selX.value = getHeuristicChannel(w, 'x');
		}

		if (userY && avail.indexOf(userY) !== -1) {
			selY.value = userY;
		} else if (prevY && avail.indexOf(prevY) !== -1) {
			selY.value = prevY;
		} else {
			selY.value = getHeuristicChannel(w, 'y');
		}

		updateSweepButtonsVisual(w);
	}
	updateConversionVisibility();
}

// Switch number of graphs (1-4)
function setNumGraphs(count) {
	numGraphs = count;
	for (var w = 1; w <= 4; w++) {
		var winEl = document.getElementById('plot_window_' + w);
		var btn = document.getElementById('btn_win_' + w);
		if (winEl) winEl.style.display = (w <= count) ? 'flex' : 'none';
		if (btn) {
			if (w === count) btn.classList.add('btn-yellow');
			else btn.classList.remove('btn-yellow');
		}
	}
	updateConversionVisibility();
	persistConfig();
	requestRenderAll();
}

// Toggle plot style (Additive: Lines and Points)
function togglePlotStyle(st) {
	if (st === 'lines') {
		showLines = !showLines;
		if (!showLines && !showPoints) showPoints = true;
	} else if (st === 'points') {
		showPoints = !showPoints;
		if (!showLines && !showPoints) showLines = true;
	}
	try {
		sessionStorage.setItem('wspa_sts_plot_lines', showLines ? '1' : '0');
		sessionStorage.setItem('wspa_sts_plot_points', showPoints ? '1' : '0');
	} catch (e) {}
	updateStyleButtonsVisual();
	persistConfig();
	renderAllPlots();
}

function updateStyleButtonsVisual() {
	var bLines = document.getElementById('btn_style_lines');
	var bPoints = document.getElementById('btn_style_points');
	if (bLines) {
		if (showLines) bLines.classList.add('btn-yellow');
		else bLines.classList.remove('btn-yellow');
	}
	if (bPoints) {
		if (showPoints) bPoints.classList.add('btn-yellow');
		else bPoints.classList.remove('btn-yellow');
	}
}

// Sync X Toggle
function toggleSyncX() {
	syncX = !syncX;
	updateSyncXVisual();
	if (syncX) {
		var src = windowStates[1];
		for (var w = 2; w <= numGraphs; w++) {
			windowStates[w].fwd = src.fwd;
			windowStates[w].bwd = src.bwd;
			windowStates[w].autoX = src.autoX;
			if (!src.autoX && src.xMin !== null && src.xMax !== null) {
				windowStates[w].xMin = src.xMin;
				windowStates[w].xMax = src.xMax;
			} else if (src.autoX) {
				windowStates[w].xMin = null;
				windowStates[w].xMax = null;
			}
			updateSweepButtonsVisual(w);
			updateAutoButtonsVisual(w);
			renderPlot(w);
		}
		if (!src.autoX && src.xMin !== null && src.xMax !== null) {
			syncAllGraphsX(1);
		}
	}
	persistConfig();
}

function updateSyncXVisual() {
	var b = document.getElementById('btn_sync_x');
	if (b) {
		if (syncX) b.classList.add('btn-yellow');
		else b.classList.remove('btn-yellow');
	}
}

function syncAllGraphsX(sourceWinIdx) {
	if (!syncX) return;
	var src = windowStates[sourceWinIdx];
	if (src.xMin === null || src.xMax === null) return;
	for (var w = 1; w <= numGraphs; w++) {
		if (w !== sourceWinIdx) {
			windowStates[w].xMin = src.xMin;
			windowStates[w].xMax = src.xMax;
			windowStates[w].autoX = false;
			updateAutoButtonsVisual(w);
			renderPlot(w);
		}
	}
}

// Unit Conversion Modes (Mutually exclusive: 'none', 'ev', 'cm1')
function setConversion(mode) {
	if (conversionMode === mode && mode !== 'none') {
		conversionMode = 'none';
	} else {
		conversionMode = mode;
	}
	['none', 'ev', 'cm1'].forEach(function(m) {
		var b = document.getElementById('btn_conv_' + m);
		if (b) {
			if (m === conversionMode) b.classList.add('btn-yellow');
			else b.classList.remove('btn-yellow');
		}
	});
	// Reset bounds across windows to recalculate converted ranges
	for (var w = 1; w <= 4; w++) {
		windowStates[w].autoX = true;
		windowStates[w].xMin = null;
		windowStates[w].xMax = null;
		updateAutoButtonsVisual(w);
	}
	persistConfig();
	requestRenderAll();
}

function onLambdaChange(val) {
	var parsed = parseFloat(val);
	if (!isNaN(parsed) && parsed > 0) {
		centerLambda = parsed;
		if (conversionMode === 'cm1') {
			for (var w = 1; w <= 4; w++) {
				windowStates[w].autoX = true;
				windowStates[w].xMin = null;
				windowStates[w].xMax = null;
			}
			requestRenderAll();
		}
		persistConfig();
	}
}

function isWavelengthChannel(ch) {
	if (!ch) return false;
	return /nm|wavelength|lambda/i.test(ch);
}

function hasWavelengthChannel() {
	for (var w = 1; w <= numGraphs; w++) {
		var selX = document.getElementById('sel_x_' + w);
		var selY = document.getElementById('sel_y_' + w);
		if (selX && isWavelengthChannel(selX.value)) return true;
		if (selY && isWavelengthChannel(selY.value)) return true;
	}
	return false;
}

function updateConversionVisibility() {
	var cont = document.getElementById('conv_controls_container');
	if (!cont) return;
	cont.style.display = hasWavelengthChannel() ? 'inline' : 'none';
}

function convertValue(v, isWl) {
	if (!isWl || conversionMode === 'none' || v <= 0) return v;
	if (conversionMode === 'ev') {
		return 1239.841984 / v;
	} else if (conversionMode === 'cm1') {
		if (centerLambda > 0) {
			return 1e7 * (1.0 / centerLambda - 1.0 / v);
		}
		return 1e7 / v;
	}
	return v;
}

function getConvertedAxisTitle(baseChan, isWl) {
	if (!isWl || conversionMode === 'none') return baseChan;
	if (conversionMode === 'ev') return 'Energy (eV)';
	if (conversionMode === 'cm1') {
		return (centerLambda > 0 ? 'Energy shift (cm\u207B\u00B9)' : 'Wavenumber (cm\u207B\u00B9)');
	}
	return baseChan;
}

// SI Prefix Lookup & Axis Title Formatter
var SI_PREFIX_MAP = {
	24: 'Y', 21: 'Z', 18: 'E', 15: 'P', 12: 'T', 9: 'G', 6: 'M', 3: 'k', 0: '',
	'-3': 'm', '-6': '\u03BC', '-9': 'n', '-12': 'p', '-15': 'f', '-18': 'a', '-21': 'z', '-24': 'y'
};
var KNOWN_PREFIXES = {
	'Y': 24, 'Z': 21, 'E': 18, 'P': 15, 'T': 12, 'G': 9, 'M': 6, 'k': 3,
	'm': -3, 'u': -6, '\u03BC': -6, '\u00B5': -6, 'n': -9, 'p': -12, 'f': -15, 'a': -18, 'z': -21, 'y': -24
};
var BASE_UNITS = ['eV', 'Hz', 'Ohm', '\u03A9', 'A', 'V', 'm', 's', 'F', 'W', 'N', 'J', 'Pa', 'bar'];

function formatTitleWithSI(title, E) {
	if (!title) return '';
	if (!E || E === 0) return title;

	var match = title.match(/^(.*)\s*\(([^)]+)\)\s*$/);
	if (match) {
		var name = match[1].trim();
		var unit = match[2].trim();

		// 1. Check exact base unit e.g. (A), (V), (m), (eV), (Hz)
		for (var i = 0; i < BASE_UNITS.length; i++) {
			var b = BASE_UNITS[i];
			if (unit === b) {
				var pref = SI_PREFIX_MAP[E];
				if (pref !== undefined) return name + ' (' + pref + b + ')';
				break;
			}
		}

		// 2. Check already prefixed base unit e.g. (nm), (pm), (um), (mV), (kHz)
		for (var i = 0; i < BASE_UNITS.length; i++) {
			var b = BASE_UNITS[i];
			if (unit.length > b.length && unit.endsWith(b)) {
				var p = unit.substring(0, unit.length - b.length);
				if (KNOWN_PREFIXES[p] !== undefined) {
					var netE = KNOWN_PREFIXES[p] + E;
					var netPref = SI_PREFIX_MAP[netE];
					if (netPref !== undefined) {
						return name + ' (' + netPref + b + ')';
					}
				}
			}
		}

		// Fallback for non-base units in parentheses e.g. (cm^-1), (deg)
		var expStr = 'x10^' + E;
		return name + ' (' + expStr + ' ' + unit + ')';
	}

	var pref = SI_PREFIX_MAP[E];
	return title + (pref !== undefined ? ' (' + pref + ')' : ' (x10^' + E + ')');
}

// Check if backward sweep channel exists for active selection in window
function hasBwdChannel(winIdx) {
	var selY = document.getElementById('sel_y_' + winIdx);
	if (!selY) return false;
	var chanY = selY.value;
	if (!chanY) return false;

	for (var i = 0; i < selectedCurveFiles.length; i++) {
		var curve = curveCache[selectedCurveFiles[i]];
		if (curve && curve.data) {
			if (resolveKey(curve, chanY, true)) return true;
		}
	}
	return false;
}

// Toggle Forward / Backward sweep display in window
function toggleSweep(winIdx, dir) {
	var st = windowStates[winIdx];
	var hasBwd = hasBwdChannel(winIdx);

	if (dir === 'fwd') {
		if (!hasBwd) {
			st.fwd = true;
		} else {
			st.fwd = !st.fwd;
			if (!st.fwd && !st.bwd) st.bwd = true;
		}
	} else if (dir === 'bwd') {
		if (hasBwd) {
			st.bwd = !st.bwd;
			if (!st.fwd && !st.bwd) st.fwd = true;
		} else {
			st.bwd = false;
		}
	}
	updateSweepButtonsVisual(winIdx);
	renderPlot(winIdx);

	if (syncX) {
		for (var w = 1; w <= numGraphs; w++) {
			if (w !== winIdx) {
				windowStates[w].fwd = st.fwd;
				windowStates[w].bwd = st.bwd;
				updateSweepButtonsVisual(w);
				renderPlot(w);
			}
		}
	}
	persistConfig();
}

function updateSweepButtonsVisual(winIdx) {
	var st = windowStates[winIdx];
	var btnF = document.getElementById('btn_fwd_' + winIdx);
	var btnB = document.getElementById('btn_bwd_' + winIdx);
	var hasBwd = hasBwdChannel(winIdx);

	// Fwd button is there always
	if (btnF) {
		btnF.style.display = 'inline-block';
		var visualFwd = st.fwd || (!hasBwd);
		if (visualFwd) btnF.classList.add('btn-yellow');
		else btnF.classList.remove('btn-yellow');
	}

	if (btnB) {
		if (hasBwd) {
			btnB.style.display = 'inline-block';
			if (st.bwd) btnB.classList.add('btn-yellow');
			else btnB.classList.remove('btn-yellow');
		} else {
			btnB.style.display = 'none';
			// Preserve user preference across files!
		}
	}

	// Invariant: at least one button must be selected if bwd is present
	if (hasBwd && !st.fwd && !st.bwd) {
		st.fwd = true;
		if (btnF) btnF.classList.add('btn-yellow');
	}
}

// Toggle AutoX / AutoY
function toggleAuto(winIdx, axis) {
	var st = windowStates[winIdx];
	if (axis === 'x') {
		st.autoX = !st.autoX;
		if (st.autoX) {
			st.xMin = null; st.xMax = null;
		}
		updateAutoButtonsVisual(winIdx);
		renderPlot(winIdx);

		if (syncX) {
			for (var w = 1; w <= numGraphs; w++) {
				if (w !== winIdx) {
					windowStates[w].autoX = st.autoX;
					if (st.autoX) {
						windowStates[w].xMin = null;
						windowStates[w].xMax = null;
					} else {
						windowStates[w].xMin = st.xMin;
						windowStates[w].xMax = st.xMax;
					}
					updateAutoButtonsVisual(w);
					renderPlot(w);
				}
			}
		}
	} else if (axis === 'y') {
		st.autoY = !st.autoY;
		if (st.autoY) { st.yMin = null; st.yMax = null; }
		updateAutoButtonsVisual(winIdx);
		renderPlot(winIdx);
	}
	persistConfig();
}

function updateAutoButtonsVisual(winIdx) {
	var st = windowStates[winIdx];
	var btnX = document.getElementById('btn_autox_' + winIdx);
	var btnY = document.getElementById('btn_autoy_' + winIdx);
	if (btnX) {
		if (st.autoX) btnX.classList.add('btn-yellow');
		else btnX.classList.remove('btn-yellow');
	}
	if (btnY) {
		if (st.autoY) btnY.classList.add('btn-yellow');
		else btnY.classList.remove('btn-yellow');
	}
}

// Channel dropdown change
function onChannelChange(winIdx) {
	var selX = document.getElementById('sel_x_' + winIdx);
	var selY = document.getElementById('sel_y_' + winIdx);
	if (selX) saveUserTypeChannel(winIdx, 'x', selX.value);
	if (selY) saveUserTypeChannel(winIdx, 'y', selY.value);

	var st = windowStates[winIdx];
	st.autoX = true;
	st.autoY = true;
	st.xMin = null; st.xMax = null;
	st.yMin = null; st.yMax = null;
	updateAutoButtonsVisual(winIdx);
	updateSweepButtonsVisual(winIdx);
	updateConversionVisibility();
	persistConfig();
	renderPlot(winIdx);
}

// Save configuration to localStorage, hidden inputs, and save_config.php (Rule 16)
function persistConfig() {
	var qvudEl = document.getElementById('qvud');
	var stsQvudEl = document.getElementById('sts_qvud');
	var colLeft = document.getElementById('col_left');
	var actualImgW = colLeft ? Math.round(colLeft.getBoundingClientRect().width) : currentImgWidth;
	var infoH = qvudEl ? (parseInt(qvudEl.style.height, 10) || qvudEl.offsetHeight || 140) : 140;
	var specH = stsQvudEl ? (parseInt(stsQvudEl.style.height, 10) || stsQvudEl.offsetHeight || 140) : 140;

	currentImgWidth = actualImgW;

	var cfg = {
		numGraphs: numGraphs,
		showLines: showLines ? '1' : '0',
		showPoints: showPoints ? '1' : '0',
		showInfo: showInfo ? '1' : '0',
		showSpec: showSpec ? '1' : '0',
		syncX: syncX ? '1' : '0',
		convMode: conversionMode,
		lambda: centerLambda,
		imgWidth: currentImgWidth,
		infoHeight: infoH,
		specHeight: specH,
		colorLink: colorLink ? '1' : '0'
	};
	for (var w = 1; w <= 4; w++) {
		cfg['g' + w + '_fwd'] = windowStates[w].fwd ? '1' : '0';
		cfg['g' + w + '_bwd'] = windowStates[w].bwd ? '1' : '0';
	}
	try {
		localStorage.setItem('wspa_sts_config', JSON.stringify(cfg));
		sessionStorage.setItem('wspa_sts_plot_lines', showLines ? '1' : '0');
		sessionStorage.setItem('wspa_sts_plot_points', showPoints ? '1' : '0');
	} catch (e) {}

	var f = document.getElementById('sts_nav_form');
	if (f) {
		setNavHidden(f, 'save_cfg_flag', '1');
		setNavHidden(f, 'cfg_num_graphs', numGraphs);
		setNavHidden(f, 'cfg_plot_lines', showLines ? '1' : '0');
		setNavHidden(f, 'cfg_plot_points', showPoints ? '1' : '0');
		setNavHidden(f, 'cfg_show_info', showInfo ? '1' : '0');
		setNavHidden(f, 'cfg_show_spec', showSpec ? '1' : '0');
		setNavHidden(f, 'cfg_sync_x', syncX ? '1' : '0');
		setNavHidden(f, 'cfg_conv_mode', conversionMode);
		setNavHidden(f, 'cfg_lambda', centerLambda);
		setNavHidden(f, 'cfg_img_width', currentImgWidth);
		setNavHidden(f, 'cfg_info_height', infoH);
		setNavHidden(f, 'cfg_spec_height', specH);
		setNavHidden(f, 'cfg_color_link', colorLink ? '1' : '0');
		for (var w = 1; w <= 4; w++) {
			var selX = document.getElementById('sel_x_' + w);
			var selY = document.getElementById('sel_y_' + w);
			if (selX) setNavHidden(f, 'cfg_g' + w + '_x', selX.value);
			if (selY) setNavHidden(f, 'cfg_g' + w + '_y', selY.value);
			setNavHidden(f, 'cfg_g' + w + '_fwd', windowStates[w].fwd ? '1' : '0');
			setNavHidden(f, 'cfg_g' + w + '_bwd', windowStates[w].bwd ? '1' : '0');
		}
	}

	// Immediate async save to <user>.cfg via save_config.php
	try {
		var fd = new FormData();
		fd.append('sts_num_graphs', numGraphs);
		fd.append('sts_plot_lines', showLines ? '1' : '0');
		fd.append('sts_plot_points', showPoints ? '1' : '0');
		fd.append('sts_show_info', showInfo ? '1' : '0');
		fd.append('sts_show_spec', showSpec ? '1' : '0');
		fd.append('sts_sync_x', syncX ? '1' : '0');
		fd.append('sts_conv_mode', conversionMode);
		fd.append('sts_lambda', centerLambda);
		fd.append('sts_img_width', currentImgWidth);
		fd.append('sts_info_height', infoH);
		fd.append('sts_spec_height', specH);
		fd.append('sts_color_link', colorLink ? '1' : '0');
		for (var w = 1; w <= 4; w++) {
			var sx = document.getElementById('sel_x_' + w);
			var sy = document.getElementById('sel_y_' + w);
			if (sx) fd.append('sts_g' + w + '_x', sx.value);
			if (sy) fd.append('sts_g' + w + '_y', sy.value);
			fd.append('sts_g' + w + '_fwd', windowStates[w].fwd ? '1' : '0');
			fd.append('sts_g' + w + '_bwd', windowStates[w].bwd ? '1' : '0');
		}
		if (navigator.sendBeacon) {
			navigator.sendBeacon('save_config.php', fd);
		} else if (window.fetch) {
			fetch('save_config.php', { method: 'POST', body: fd });
		}
	} catch (e) {}
}

function setNavHidden(form, name, value) {
	var inp = form.querySelector('input[name="' + name + '"]');
	if (!inp) {
		inp = document.createElement('input');
		inp.type = 'hidden';
		inp.name = name;
		form.appendChild(inp);
	}
	inp.value = value;
}

// Standard "Nice Numbers" Tick Positioning and Format Algorithm
// (Based on Heckbert, Graphics Gems and Matplotlib MaxNLocator/ScalarFormatter)
function getNiceAxisTicks(min, max, maxTicks) {
	if (min >= max) {
		max = min + 1.0;
	}
	var range = max - min;
	var rawStep = range / Math.max(2, maxTicks);
	var k = Math.floor(Math.log10(rawStep));
	var f = rawStep / Math.pow(10, k);
	var c;
	if (f < 1.5) c = 1;
	else if (f < 3.5) c = 2;
	else if (f < 7.5) c = 5;
	else { c = 1; k += 1; }
	var step = parseFloat((c * Math.pow(10, k)).toPrecision(12));

	// Minor step divisions (integer increments at last significant digit)
	var minorDiv = (c === 2) ? 4 : 5;
	var minorStep = parseFloat((step / minorDiv).toPrecision(12));

	// Determine common engineering exponent E (multiples of 3)
	var maxAbs = Math.max(Math.abs(min), Math.abs(max));
	var E = 0;
	if (maxAbs < 0.01 && maxAbs > 0) {
		E = Math.floor(Math.log10(maxAbs) / 3) * 3;
	} else if (maxAbs >= 1000) {
		E = Math.floor(Math.log10(maxAbs) / 3) * 3;
	}

	var d_m = step / Math.pow(10, E);
	var decimals = Math.max(0, -Math.floor(Math.log10(d_m) + 1e-9));

	var iMin = Math.ceil(min / step - 1e-9);
	var iMax = Math.floor(max / step + 1e-9);
	var majorTicks = [];

	for (var i = iMin; i <= iMax; i++) {
		var val = i * step;
		val = Math.round(val / (step * 0.0001)) * (step * 0.0001);
		var label;
		if (Math.abs(val) < 1e-25 || i === 0) {
			label = "0";
		} else {
			var m = val / Math.pow(10, E);
			if (Math.abs(m) < 1e-12) m = 0;
			var mStr = m.toFixed(decimals);
			label = mStr;
		}
		majorTicks.push({ val: val, label: label });
	}

	// Minor ticks: integer multiples of minorStep, excluding major ticks
	var jMin = Math.ceil(min / minorStep - 1e-9);
	var jMax = Math.floor(max / minorStep + 1e-9);
	var minorTicks = [];
	for (var j = jMin; j <= jMax; j++) {
		if (j % minorDiv !== 0) {
			var mVal = j * minorStep;
			mVal = Math.round(mVal / (minorStep * 0.0001)) * (minorStep * 0.0001);
			minorTicks.push(mVal);
		}
	}

	return { step: step, minorStep: minorStep, E: E, decimals: decimals, major: majorTicks, minor: minorTicks };
}

// Engineering notation with 3 valid digits (significant figures)
// Exponent is strictly in multiples of 3, and omitted for 0.01 <= |v| < 1000
function formatEngineering(v) {
	if (v === 0 || Math.abs(v) < 1e-35) return "0";
	var sign = v < 0 ? "-" : "";
	var absV = Math.abs(v);

	// Normal range: 0.01 <= absV < 1000 -> 3 valid digits, no exponent
	if (absV >= 0.01 && absV < 1000) {
		return sign + absV.toPrecision(3);
	}

	// Engineering notation: exponent multiple of 3, mantissa in [1, 1000) with 3 sig figs
	var exp = Math.floor(Math.log10(absV) / 3) * 3;
	var mantissa = absV / Math.pow(10, exp);

	if (mantissa >= 999.95) {
		mantissa /= 1000;
		exp += 3;
	} else if (mantissa < 0.99995 && mantissa > 0) {
		mantissa *= 1000;
		exp -= 3;
	}

	var mStr;
	if (mantissa >= 100) {
		mStr = mantissa.toFixed(0);
	} else if (mantissa >= 10) {
		mStr = mantissa.toFixed(1);
	} else {
		mStr = mantissa.toFixed(2);
	}

	return sign + mStr + (exp !== 0 ? 'E' + exp : '');
}

function resolveKey(curve, baseChan, isBwd) {
	if (!curve || !curve.data) return null;
	var map = isBwd ? curve._keyMapBwd : curve._keyMapFwd;
	if (map) {
		if (map[baseChan]) return map[baseChan];
		var low = baseChan.toLowerCase();
		if (map[low]) return map[low];
	}
	if (!isBwd && curve.data[baseChan]) return baseChan;
	return null;
}

// Pure HTML5 Canvas 2D Plotting Engine
function renderPlot(winIdx) {
	if (winIdx > numGraphs) return;
	var canvas = document.getElementById('canvas_' + winIdx);
	if (!canvas) return;

	var selX = document.getElementById('sel_x_' + winIdx);
	var selY = document.getElementById('sel_y_' + winIdx);
	if (!selX || !selY) return;

	var chanX = selX.value;
	var chanY = selY.value;
	var st = windowStates[winIdx];

	var dpr = window.devicePixelRatio || 1;
	var wrap = canvas.parentElement;
	var rect = wrap ? wrap.getBoundingClientRect() : canvas.getBoundingClientRect();
	var width = Math.floor(rect.width);
	var height = Math.floor(rect.height);

	if (width <= 0 || height <= 0) return;

	if (canvas.width !== width * dpr || canvas.height !== height * dpr) {
		canvas.width = width * dpr;
		canvas.height = height * dpr;
	}

	var ctx = canvas.getContext('2d');
	ctx.save();
	ctx.scale(dpr, dpr);

	ctx.fillStyle = '#111';
	ctx.fillRect(0, 0, width, height);

	// Fixed padding across all windows (accommodating 11pt monospace ticks and titles)
	var padLeft = 98;
	var padRight = 15;
	var padTop = 15;
	var padBottom = 48;
	var plotW = width - padLeft - padRight;
	var plotH = height - padTop - padBottom;

	var activeCurves = getActiveCurvesToPlot();
	if (plotW <= 20 || plotH <= 20 || activeCurves.length === 0) {
		ctx.fillStyle = '#777';
		ctx.font = '11pt monospace';
		ctx.fillText(activeCurves.length === 0 ? (interactiveMode ? 'No curve highlighted' : 'No curves selected') : 'Waiting for channels...', padLeft + 10, height / 2);
		ctx.restore();
		return;
	}

	var colorMap = getCurveColorMap();
	var seriesList = [];
	var rawMinX = Infinity, rawMaxX = -Infinity;
	var rawMinY = Infinity, rawMaxY = -Infinity;

	var isWlX = isWavelengthChannel(chanX);
	var isWlY = isWavelengthChannel(chanY);
	var convXMode = (isWlX && conversionMode !== 'none') ? conversionMode : 'none';
	var convYMode = (isWlY && conversionMode !== 'none') ? conversionMode : 'none';

	activeCurves.forEach(function(fn) {
		var curve = curveCache[fn];
		if (!curve || !curve.data) return;
		var col = interactiveMode ? '#ff8800' : (colorMap[fn] || '#00ff41');

		// Forward
		var effFwd = st.fwd || (!hasBwdChannel(winIdx));
		if (effFwd) {
			var kX = resolveKey(curve, chanX, false);
			var kY = resolveKey(curve, chanY, false);
			if (kX && kY && curve.data[kX] && curve.data[kY]) {
				var pts = [];
				var len = Math.min(curve.data[kX].length, curve.data[kY].length);
				for (var i = 0; i < len; i++) {
					var rawX = curve.data[kX][i];
					var rawY = curve.data[kY][i];
					if (isFinite(rawX) && isFinite(rawY)) {
						var vx = rawX;
						if (convXMode === 'ev' && rawX > 0) vx = 1239.841984 / rawX;
						else if (convXMode === 'cm1' && rawX > 0) vx = (centerLambda > 0) ? (1e7 * (1.0 / centerLambda - 1.0 / rawX)) : (1e7 / rawX);

						var vy = rawY;
						if (convYMode === 'ev' && rawY > 0) vy = 1239.841984 / rawY;
						else if (convYMode === 'cm1' && rawY > 0) vy = (centerLambda > 0) ? (1e7 * (1.0 / centerLambda - 1.0 / rawY)) : (1e7 / rawY);

						pts.push({ x: vx, y: vy });
						if (vx < rawMinX) rawMinX = vx;
						if (vx > rawMaxX) rawMaxX = vx;
						if (vy < rawMinY) rawMinY = vy;
						if (vy > rawMaxY) rawMaxY = vy;
					}
				}
				if (pts.length > 0) seriesList.push({ file: fn, isBwd: false, color: col, pts: pts });
			}
		}

		// Backward
		if (st.bwd) {
			var kXb = resolveKey(curve, chanX, true) || resolveKey(curve, chanX, false);
			var kYb = resolveKey(curve, chanY, true);
			if (kXb && kYb && curve.data[kXb] && curve.data[kYb]) {
				var ptsB = [];
				var lenB = Math.min(curve.data[kXb].length, curve.data[kY].length);
				for (var j = 0; j < lenB; j++) {
					var rawXb = curve.data[kXb][j];
					var rawYb = curve.data[kYb][j];
					if (isFinite(rawXb) && isFinite(rawYb)) {
						var vxb = rawXb;
						if (convXMode === 'ev' && rawXb > 0) vxb = 1239.841984 / rawXb;
						else if (convXMode === 'cm1' && rawXb > 0) vxb = (centerLambda > 0) ? (1e7 * (1.0 / centerLambda - 1.0 / rawXb)) : (1e7 / rawXb);

						var vyb = rawYb;
						if (convYMode === 'ev' && rawYb > 0) vyb = 1239.841984 / rawYb;
						else if (convYMode === 'cm1' && rawYb > 0) vyb = (centerLambda > 0) ? (1e7 * (1.0 / centerLambda - 1.0 / rawYb)) : (1e7 / rawYb);

						ptsB.push({ x: vxb, y: vyb });
						if (vxb < rawMinX) rawMinX = vxb;
						if (vxb > rawMaxX) rawMaxX = vxb;
						if (vyb < rawMinY) rawMinY = vyb;
						if (vyb > rawMaxY) rawMaxY = vyb;
					}
				}
				if (ptsB.length > 0) seriesList.push({ file: fn, isBwd: true, color: darkenColor(col, 0.65), pts: ptsB });
			}
		}
	});

	if (seriesList.length === 0 || !isFinite(rawMinX) || !isFinite(rawMinY)) {
		ctx.fillStyle = '#777';
		ctx.font = '11pt monospace';
		ctx.fillText('Channel not available in selection', padLeft + 10, height / 2);
		ctx.restore();
		return;
	}

	// Auto-scaling calculations
	if (st.autoX || st.xMin === null || st.xMax === null) {
		var spanX = (rawMaxX - rawMinX) || Math.abs(rawMaxX) * 0.1 || 1.0;
		st.xMin = rawMinX - spanX * 0.03;
		st.xMax = rawMaxX + spanX * 0.03;
	}
	if (st.autoY || st.yMin === null || st.yMax === null) {
		var spanY = (rawMaxY - rawMinY) || Math.abs(rawMaxY) * 0.1 || 1.0;
		st.yMin = rawMinY - spanY * 0.04;
		st.yMax = rawMaxY + spanY * 0.04;
	}

	var xMin = st.xMin, xMax = st.xMax;
	var yMin = st.yMin, yMax = st.yMax;
	var rangeX = (xMax - xMin) || 1;
	var rangeY = (yMax - yMin) || 1;

	function toScreenX(vx) { return padLeft + ((vx - xMin) / rangeX) * plotW; }
	function toScreenY(vy) { return (padTop + plotH) - ((vy - yMin) / rangeY) * plotH; }
	function toValX(sx) { return xMin + ((sx - padLeft) / plotW) * rangeX; }
	function toValY(sy) { return yMin + (((padTop + plotH) - sy) / plotH) * rangeY; }

	canvas._toScreenX = toScreenX;
	canvas._toScreenY = toScreenY;
	canvas._toValX = toValX;
	canvas._toValY = toValY;
	canvas._chanX = chanX;
	canvas._chanY = chanY;

	// Draw Axes Box (Light Gray #888)
	ctx.strokeStyle = '#888';
	ctx.lineWidth = 1;
	ctx.strokeRect(padLeft, padTop, plotW, plotH);

	// X Ticks & Grid (Standard Heckbert / Matplotlib MaxNLocator Algorithm)
	var xTicks = getNiceAxisTicks(xMin, xMax, Math.max(3, Math.floor(plotW / 95)));
	canvas._xTicks = xTicks;

	xTicks.major.forEach(function(t) {
		var sx = toScreenX(t.val);
		if (sx < padLeft - 0.5 || sx > padLeft + plotW + 0.5) return;

		// Grid line: faint #282828
		ctx.beginPath();
		ctx.strokeStyle = '#282828';
		ctx.moveTo(sx, padTop);
		ctx.lineTo(sx, padTop + plotH);
		ctx.stroke();

		// Inward Major ticks (5px inwards from bottom and top borders)
		ctx.beginPath();
		ctx.strokeStyle = '#bbb';
		ctx.moveTo(sx, padTop + plotH);
		ctx.lineTo(sx, padTop + plotH - 5);
		ctx.moveTo(sx, padTop);
		ctx.lineTo(sx, padTop + 5);
		ctx.stroke();

		// X Tick labels: light gray #ddd, 11pt monospace
		ctx.fillStyle = '#ddd';
		ctx.font = '11pt monospace';
		ctx.textAlign = 'center';
		ctx.fillText(t.label, sx, padTop + plotH + 16);
	});

	// Inward Minor Ticks (X) (3px inwards)
	xTicks.minor.forEach(function(mVal) {
		var smx = toScreenX(mVal);
		if (smx >= padLeft && smx <= padLeft + plotW) {
			ctx.beginPath();
			ctx.strokeStyle = '#777';
			ctx.moveTo(smx, padTop + plotH);
			ctx.lineTo(smx, padTop + plotH - 3);
			ctx.moveTo(smx, padTop);
			ctx.lineTo(smx, padTop + 3);
			ctx.stroke();
		}
	});

	// Y Ticks & Grid (Standard Heckbert / Matplotlib MaxNLocator Algorithm)
	var yTicks = getNiceAxisTicks(yMin, yMax, Math.max(3, Math.floor(plotH / 32)));
	canvas._yTicks = yTicks;

	yTicks.major.forEach(function(t) {
		var sy = toScreenY(t.val);
		if (sy < padTop - 0.5 || sy > padTop + plotH + 0.5) return;

		// Grid line: faint #282828
		ctx.beginPath();
		ctx.strokeStyle = '#282828';
		ctx.moveTo(padLeft, sy);
		ctx.lineTo(padLeft + plotW, sy);
		ctx.stroke();

		// Inward Major ticks (5px inwards from left and right borders)
		ctx.beginPath();
		ctx.strokeStyle = '#bbb';
		ctx.moveTo(padLeft, sy);
		ctx.lineTo(padLeft + 5, sy);
		ctx.moveTo(padLeft + plotW, sy);
		ctx.lineTo(padLeft + plotW - 5, sy);
		ctx.stroke();

		// Y Tick labels: light gray #ddd, 11pt monospace
		ctx.fillStyle = '#ddd';
		ctx.font = '11pt monospace';
		ctx.textAlign = 'right';
		ctx.fillText(t.label, padLeft - 7, sy + 4);
	});

	// Inward Minor Ticks (Y) (3px inwards)
	yTicks.minor.forEach(function(mVal) {
		var smy = toScreenY(mVal);
		if (smy >= padTop && smy <= padTop + plotH) {
			ctx.beginPath();
			ctx.strokeStyle = '#777';
			ctx.moveTo(padLeft, smy);
			ctx.lineTo(padLeft + 3, smy);
			ctx.moveTo(padLeft + plotW, smy);
			ctx.lineTo(padLeft + plotW - 3, smy);
			ctx.stroke();
		}
	});

	// X-axis Title (centered below X ticks): light gray #eee, 11pt monospace
	var titleX = formatTitleWithSI(getConvertedAxisTitle(chanX, isWlX), xTicks.E);
	ctx.fillStyle = '#eee';
	ctx.font = '11pt monospace';
	ctx.textAlign = 'center';
	ctx.fillText(titleX, padLeft + plotW / 2, height - 8);

	// Y-axis Title (rotated 90 degrees along left margin): light gray #eee, 11pt monospace
	var titleY = formatTitleWithSI(getConvertedAxisTitle(chanY, isWlY), yTicks.E);
	ctx.save();
	ctx.translate(16, padTop + plotH / 2);
	ctx.rotate(-Math.PI / 2);
	ctx.fillStyle = '#eee';
	ctx.font = '11pt monospace';
	ctx.textAlign = 'center';
	ctx.fillText(titleY, 0, 0);
	ctx.restore();

	// Clip & Plot series
	ctx.save();
	ctx.beginPath();
	ctx.rect(padLeft, padTop, plotW, plotH);
	ctx.clip();

	var sortedSeries = seriesList.slice();
	if (hoveredCurveFile) {
		sortedSeries.sort(function(a, b) {
			var aHover = (a.file === hoveredCurveFile);
			var bHover = (b.file === hoveredCurveFile);
			if (aHover && !bHover) return 1;
			if (!aHover && bHover) return -1;
			return 0;
		});
	}

	sortedSeries.forEach(function(s) {
		var isHovered = (s.file === hoveredCurveFile);
		ctx.strokeStyle = s.color;
		ctx.fillStyle = s.color;
		ctx.lineWidth = (isHovered || interactiveMode) ? 2.2 : 1.3;
		ctx.setLineDash([]);

		if (showLines) {
			ctx.beginPath();
			var pts = s.pts;
			var pLen = pts.length;
			for (var p = 0; p < pLen; p++) {
				var sx = toScreenX(pts[p].x);
				var sy = toScreenY(pts[p].y);
				if (p === 0) ctx.moveTo(sx, sy);
				else ctx.lineTo(sx, sy);
			}
			ctx.stroke();
		}

		if (showPoints) {
			var ptHalf = (isHovered || interactiveMode) ? 2.5 : 1.5;
			var ptSize = (isHovered || interactiveMode) ? 5.0 : 3.0;
			var pts = s.pts;
			var pLen = pts.length;
			for (var p = 0; p < pLen; p++) {
				var sx = toScreenX(pts[p].x);
				var sy = toScreenY(pts[p].y);
				ctx.fillRect(sx - ptHalf, sy - ptHalf, ptSize, ptSize);
			}
		}
	});

	// Measurement Box & Guides (Ctrl-Left Drag or Shift-Left Drag)
	if (st.measureBox) {
		var mx0 = Math.min(st.measureBox.x0, st.measureBox.x1);
		var mx1 = Math.max(st.measureBox.x0, st.measureBox.x1);
		var my0 = Math.min(st.measureBox.y0, st.measureBox.y1);
		var my1 = Math.max(st.measureBox.y0, st.measureBox.y1);
		var mw = mx1 - mx0;
		var mh = my1 - my0;

		// 1. Shaded vertical area (spanning full plot height)
		ctx.fillStyle = 'rgba(0, 255, 255, 0.08)';
		ctx.fillRect(mx0, padTop, mw, plotH);

		// 2. Shaded horizontal area (spanning full plot width)
		ctx.fillRect(padLeft, my0, plotW, mh);

		// 3. Shaded intersection rectangle
		ctx.fillStyle = 'rgba(0, 255, 255, 0.20)';
		ctx.fillRect(mx0, my0, mw, mh);

		// 4. Bounding dashed box
		ctx.setLineDash([3, 3]);
		ctx.strokeStyle = '#0ff';
		ctx.lineWidth = 1;
		ctx.strokeRect(mx0, my0, mw, mh);

		// 5. Crosshair guide lines across the whole plot
		ctx.strokeStyle = 'rgba(0, 255, 255, 0.6)';
		ctx.beginPath();
		ctx.moveTo(st.measureBox.x0, padTop);
		ctx.lineTo(st.measureBox.x0, padTop + plotH);
		ctx.moveTo(st.measureBox.x1, padTop);
		ctx.lineTo(st.measureBox.x1, padTop + plotH);
		ctx.moveTo(padLeft, st.measureBox.y0);
		ctx.lineTo(padLeft + plotW, st.measureBox.y0);
		ctx.moveTo(padLeft, st.measureBox.y1);
		ctx.lineTo(padLeft + plotW, st.measureBox.y1);
		ctx.stroke();
	}

	// Box Zoom Drag Outline (Normal Drag with directional horizontal/vertical zoom indication)
	if (st.boxZoom) {
		var zx0 = Math.min(st.boxZoom.x0, st.boxZoom.x1);
		var zx1 = Math.max(st.boxZoom.x0, st.boxZoom.x1);
		var zy0 = Math.min(st.boxZoom.y0, st.boxZoom.y1);
		var zy1 = Math.max(st.boxZoom.y0, st.boxZoom.y1);
		var zw = zx1 - zx0;
		var zh = zy1 - zy0;

		ctx.setLineDash([3, 3]);
		ctx.strokeStyle = '#ff0';
		ctx.lineWidth = 1;

		if (zw > 1.3 * zh) {
			// Predominantly horizontal -> X-only zoom preview
			ctx.fillStyle = 'rgba(255, 255, 0, 0.12)';
			ctx.fillRect(zx0, padTop, zw, plotH);
			ctx.strokeRect(zx0, padTop, zw, plotH);
		} else if (zh > 1.3 * zw) {
			// Predominantly vertical -> Y-only zoom preview
			ctx.fillStyle = 'rgba(255, 255, 0, 0.12)';
			ctx.fillRect(padLeft, zy0, plotW, zh);
			ctx.strokeRect(padLeft, zy0, plotW, zh);
		} else {
			// Both X and Y zoom preview
			ctx.fillStyle = 'rgba(255, 255, 0, 0.12)';
			ctx.fillRect(zx0, zy0, zw, zh);
			ctx.strokeRect(zx0, zy0, zw, zh);
		}
	}

	// Crosshairs (hover cursor or synchronized cursor across graphs)
	if (!st.measureBox && canvas._cursorX !== null && canvas._cursorY !== null &&
	    canvas._cursorX >= padLeft && canvas._cursorX <= padLeft + plotW &&
	    canvas._cursorY >= padTop && canvas._cursorY <= padTop + plotH) {
		ctx.save();
		ctx.strokeStyle = '#666';
		ctx.setLineDash([2, 2]);
		ctx.lineWidth = 1;
		ctx.beginPath();
		ctx.moveTo(canvas._cursorX, padTop);
		ctx.lineTo(canvas._cursorX, padTop + plotH);
		ctx.stroke();
		ctx.beginPath();
		ctx.moveTo(padLeft, canvas._cursorY);
		ctx.lineTo(padLeft + plotW, canvas._cursorY);
		ctx.stroke();
		ctx.restore();
	} else if (!st.measureBox && syncX && globalCursorValX !== null && canvas._toScreenX) {
		var synScreenX = toScreenX(globalCursorValX);
		if (synScreenX >= padLeft && synScreenX <= padLeft + plotW) {
			ctx.save();
			ctx.strokeStyle = '#666';
			ctx.setLineDash([2, 2]);
			ctx.lineWidth = 1;
			ctx.beginPath();
			ctx.moveTo(synScreenX, padTop);
			ctx.lineTo(synScreenX, padTop + plotH);
			ctx.stroke();
			ctx.restore();
		}
	}

	ctx.restore();
	ctx.restore();
}

function renderAllPlots() {
	for (var w = 1; w <= numGraphs; w++) {
		renderPlot(w);
	}
}

var renderScheduled = {};
var renderAllScheduled = false;

function requestRenderPlot(winIdx) {
	if (renderAllScheduled || renderScheduled[winIdx]) return;
	renderScheduled[winIdx] = true;
	requestAnimationFrame(function() {
		renderScheduled[winIdx] = false;
		renderPlot(winIdx);
	});
}

function requestRenderAll() {
	if (renderAllScheduled) return;
	renderAllScheduled = true;
	requestAnimationFrame(function() {
		renderAllScheduled = false;
		renderAllPlots();
	});
}

// Crosshair readout format: uses three more digits than the axis tick labels
function formatReadoutVal(val, axisTicks) {
	if (val === null || val === undefined || !isFinite(val)) return "";
	if (axisTicks && typeof axisTicks.decimals === 'number') {
		var E = axisTicks.E || 0;
		var dec = axisTicks.decimals + 3;
		var m = val / Math.pow(10, E);
		if (Math.abs(m) < Math.pow(10, -dec) / 2) {
			m = 0;
		}
		var sign = m < 0 ? "-" : "";
		var absM = Math.abs(m);
		var mStr = absM.toFixed(dec);
		return sign + mStr;
	}
	return formatEngineering(val);
}

// Mouse events on plot canvas (Measurement, Zoom, Crosshairs)
function setupPlotCanvas(winIdx) {
	var canvas = document.getElementById('canvas_' + winIdx);
	if (!canvas) return;
	var st = windowStates[winIdx];

	canvas.addEventListener('mousedown', function(e) {
		if (e.button === 0) {
			var rect = canvas.getBoundingClientRect();
			var mx = e.clientX - rect.left;
			var my = e.clientY - rect.top;
			if (e.ctrlKey || e.shiftKey) {
				st.measureBox = { x0: mx, y0: my, x1: mx, y1: my };
			} else {
				st.boxZoom = { x0: mx, y0: my, x1: mx, y1: my };
			}
		}
	});

	canvas.addEventListener('mousemove', function(e) {
		var rect = canvas.getBoundingClientRect();
		var mx = e.clientX - rect.left;
		var my = e.clientY - rect.top;
		canvas._cursorX = mx;
		canvas._cursorY = my;

		if (canvas._toValX && canvas._toValY) {
			var vx = canvas._toValX(mx);
			var vy = canvas._toValY(my);
			var readout = document.getElementById('readout_' + winIdx);

			if (st.measureBox) {
				st.measureBox.x1 = mx;
				st.measureBox.y1 = my;
				var dValX = Math.abs(canvas._toValX(st.measureBox.x1) - canvas._toValX(st.measureBox.x0));
				var dValY = Math.abs(canvas._toValY(st.measureBox.y1) - canvas._toValY(st.measureBox.y0));
				if (readout) readout.innerText = "dX:" + formatReadoutVal(dValX, canvas._xTicks) + " \u00A0dY:" + formatReadoutVal(dValY, canvas._yTicks);
			} else if (st.boxZoom) {
				st.boxZoom.x1 = mx;
				st.boxZoom.y1 = my;
				var dValX = Math.abs(canvas._toValX(st.boxZoom.x1) - canvas._toValX(st.boxZoom.x0));
				var dValY = Math.abs(canvas._toValY(st.boxZoom.y1) - canvas._toValY(st.boxZoom.y0));
				if (readout) readout.innerText = "dX:" + formatReadoutVal(dValX, canvas._xTicks) + " \u00A0dY:" + formatReadoutVal(dValY, canvas._yTicks);
			} else {
				if (readout) readout.innerText = "X:" + formatReadoutVal(vx, canvas._xTicks) + " \u00A0Y:" + formatReadoutVal(vy, canvas._yTicks);
			}

			if (syncX) {
				globalCursorValX = vx;
				for (var w = 1; w <= numGraphs; w++) {
					if (w !== winIdx) {
						var r = document.getElementById('readout_' + w);
						var cw = document.getElementById('canvas_' + w);
						if (r) {
							var targetXTicks = (cw && cw._xTicks) ? cw._xTicks : canvas._xTicks;
							if (st.measureBox || st.boxZoom) {
								var activeBox = st.measureBox || st.boxZoom;
								var dValXSync = Math.abs(canvas._toValX(activeBox.x1) - canvas._toValX(activeBox.x0));
								r.innerText = "dX:" + formatReadoutVal(dValXSync, targetXTicks);
							} else {
								r.innerText = "X:" + formatReadoutVal(vx, targetXTicks);
							}
						}
					}
				}
				requestRenderAll();
			} else {
				requestRenderPlot(winIdx);
			}
		}
	});

	canvas.addEventListener('mouseleave', function() {
		if (st.measureBox || st.boxZoom) return;
		canvas._cursorX = null;
		canvas._cursorY = null;
		var readout = document.getElementById('readout_' + winIdx);
		if (readout) readout.innerText = '';
		if (syncX) {
			globalCursorValX = null;
			for (var w = 1; w <= numGraphs; w++) {
				var r = document.getElementById('readout_' + w);
				if (r) r.innerText = '';
			}
			requestRenderAll();
		} else {
			requestRenderPlot(winIdx);
		}
	});

	canvas.addEventListener('wheel', function(e) {
		e.preventDefault();
		if (!canvas._toValX || !canvas._toValY) return;

		var rect = canvas.getBoundingClientRect();
		var mx = e.clientX - rect.left;
		var my = e.clientY - rect.top;
		var vX = canvas._toValX(mx);
		var vY = canvas._toValY(my);
		var factor = e.deltaY < 0 ? 0.8 : 1.25;

		if (!e.ctrlKey) {
			st.xMin = vX - (vX - st.xMin) * factor;
			st.xMax = vX + (st.xMax - vX) * factor;
			st.autoX = false;
		}
		if (!e.shiftKey) {
			st.yMin = vY - (vY - st.yMin) * factor;
			st.yMax = vY + (st.yMax - vY) * factor;
			st.autoY = false;
		}
		updateAutoButtonsVisual(winIdx);
		if (syncX && !e.ctrlKey) syncAllGraphsX(winIdx);
		renderPlot(winIdx);
	}, { passive: false });

	canvas.addEventListener('dblclick', function() {
		toggleAuto(winIdx, 'x');
		toggleAuto(winIdx, 'y');
		if (syncX) syncAllGraphsX(winIdx);
	});
}

// Global mouseup handler across all graph windows (Handles Measurement release and Directional Zoom)
window.addEventListener('mouseup', function(e) {
	for (var w = 1; w <= numGraphs; w++) {
		var st = windowStates[w];
		var canvas = document.getElementById('canvas_' + w);
		if (!st || !canvas) continue;

		if (st.measureBox) {
			st.measureBox = null;
			renderPlot(w);
		} else if (st.boxZoom) {
			var dx = Math.abs(st.boxZoom.x1 - st.boxZoom.x0);
			var dy = Math.abs(st.boxZoom.y1 - st.boxZoom.y0);
			var zoomed = false;

			if (dx > 1.3 * dy) {
				// Predominantly horizontal -> Zoom X axis only
				if (dx > 5 && canvas._toValX) {
					st.xMin = canvas._toValX(Math.min(st.boxZoom.x0, st.boxZoom.x1));
					st.xMax = canvas._toValX(Math.max(st.boxZoom.x0, st.boxZoom.x1));
					st.autoX = false;
					zoomed = true;
				}
			} else if (dy > 1.3 * dx) {
				// Predominantly vertical -> Zoom Y axis only
				if (dy > 5 && canvas._toValY) {
					st.yMin = canvas._toValY(Math.max(st.boxZoom.y0, st.boxZoom.y1));
					st.yMax = canvas._toValY(Math.min(st.boxZoom.y0, st.boxZoom.y1));
					st.autoY = false;
					zoomed = true;
				}
			} else {
				// Both horizontal & vertical -> 2D Zoom
				if (dx > 5 && canvas._toValX) {
					st.xMin = canvas._toValX(Math.min(st.boxZoom.x0, st.boxZoom.x1));
					st.xMax = canvas._toValX(Math.max(st.boxZoom.x0, st.boxZoom.x1));
					st.autoX = false;
					zoomed = true;
				}
				if (dy > 5 && canvas._toValY) {
					st.yMin = canvas._toValY(Math.max(st.boxZoom.y0, st.boxZoom.y1));
					st.yMax = canvas._toValY(Math.min(st.boxZoom.y0, st.boxZoom.y1));
					st.autoY = false;
					zoomed = true;
				}
			}

			if (zoomed) {
				updateAutoButtonsVisual(w);
				if (syncX && !st.autoX) syncAllGraphsX(w);
			}
			st.boxZoom = null;
			renderPlot(w);
		}
	}
});

function triggerNav(cmd) {
	var f = document.getElementById('sts_nav_form');
	var hidden = document.getElementById('nav_cmd');
	var btn = document.getElementById(cmd);
	if (btn) btn.classList.add('btn-yellow');
	if (hidden) hidden.value = cmd;
	if (typeof persistConfig === 'function') persistConfig();
	if (f) {
		f.submit();
	} else if (btn) {
		btn.click();
	}
}

function switchScanChannelInPlace(targetCh, aEl) {
	var targetIdx = targetCh - 1;
	var chanThumbnails = document.getElementById('channel_thumbnails');
	var scanImg = document.getElementById('scan_img');
	var clickedImg = aEl ? aEl.querySelector('img') : null;
	if (!clickedImg && chanThumbnails) {
		var links = chanThumbnails.querySelectorAll('a');
		for (var li = 0; li < links.length; li++) {
			var lm = (links[li].getAttribute('href') || '').match(/command=goto\s+(\d+)/);
			if (lm && parseInt(lm[1], 10) === targetCh) {
				clickedImg = links[li].querySelector('img');
				aEl = links[li];
				break;
			}
		}
	}
	if (clickedImg && scanImg) {
		scanImg.src = clickedImg.src;
		if (chanThumbnails) {
			var allThumbImgs = chanThumbnails.querySelectorAll('img');
			for (var ti = 0; ti < allThumbImgs.length; ti++) {
				allThumbImgs[ti].style.backgroundColor = (allThumbImgs[ti] === clickedImg) ? '#fff' : '#000';
			}
		}
		var indexInput = document.querySelector('#sts_nav_form input[name="index"]');
		if (indexInput) indexInput.value = targetIdx;
		var navCmd = document.getElementById('nav_cmd');
		if (navCmd) navCmd.value = '';

		// Update Channel line in qvud textarea if visible
		var qvudEl = document.getElementById('qvud');
		var chTitle = (clickedImg.title || (aEl ? aEl.title : ''));
		if (qvudEl && chTitle) {
			var qLines = qvudEl.value.split('\n');
			for (var qi = 0; qi < qLines.length; qi++) {
				if (qLines[qi].indexOf('Channel:') === 0) {
					var rest = qLines[qi].indexOf('  ');
					var suffix = (rest !== -1) ? qLines[qi].substring(rest) : '';
					qLines[qi] = 'Channel: ' + chTitle + suffix;
					break;
				}
			}
			qvudEl.value = qLines.join('\n');
		}
		if (typeof persistConfig === 'function') persistConfig();
		return true;
	}
	return false;
}

function stepScanChannel(direction) {
	var chanThumbnails = document.getElementById('channel_thumbnails');
	if (!chanThumbnails) return false;
	var links = Array.prototype.slice.call(chanThumbnails.querySelectorAll('a'));
	if (links.length <= 1) return false;

	var curIdxInput = document.querySelector('#sts_nav_form input[name="index"]');
	var curIdx = curIdxInput ? parseInt(curIdxInput.value, 10) : -1;
	var curPos = -1;

	for (var i = 0; i < links.length; i++) {
		var m = (links[i].getAttribute('href') || '').match(/command=goto\s+(\d+)/);
		if (m && (parseInt(m[1], 10) - 1) === curIdx) {
			curPos = i;
			break;
		}
	}

	if (curPos === -1) {
		for (var i = 0; i < links.length; i++) {
			var img = links[i].querySelector('img');
			if (img && (img.style.backgroundColor === 'rgb(255, 255, 255)' || img.style.backgroundColor === '#fff')) {
				curPos = i;
				break;
			}
		}
	}

	var targetPos = curPos + direction;
	if (targetPos >= 0 && targetPos < links.length) {
		var tm = (links[targetPos].getAttribute('href') || '').match(/command=goto\s+(\d+)/);
		if (tm) {
			return switchScanChannelInPlace(parseInt(tm[1], 10), links[targetPos]);
		}
	}
	return false;
}

// Global Keyboard Navigation (Quickview-style channels on load, curves workstation once clicked)
document.addEventListener('keydown', function(e) {
	var activeEl = document.activeElement;
	var inInput = (activeEl && (activeEl.tagName === 'INPUT' || activeEl.tagName === 'SELECT' || activeEl.tagName === 'TEXTAREA') && activeEl.type !== 'checkbox' && activeEl.type !== 'button' && activeEl.type !== 'submit');

	if (inInput) return;

	// PageUp (33): prev_sts (previous STS map file, <<<)
	// PageDown (34): next_sts (next STS map file, >>>)
	if (e.keyCode === 33) {
		e.preventDefault();
		triggerNav('prev_sts');
		return;
	} else if (e.keyCode === 34) {
		e.preventDefault();
		triggerNav('next_sts');
		return;
	}

	var inCurvesList = curvesListActive || (activeEl && (activeEl.id === 'curves_container' || activeEl.closest('#curves_container')));

	if (inCurvesList) {
		// Ctrl+A / Cmd+A: select all curves up to 16 (only when Interactive mode is OFF)
		if ((e.ctrlKey || e.metaKey) && (e.keyCode === 65 || e.key === 'a' || e.key === 'A')) {
			e.preventDefault();
			if (!interactiveMode) {
				selectAllCurves(true);
			}
			return;
		}

		if (e.keyCode === 38) { // Arrow Up
			e.preventDefault();
			lastKeyNavTime = Date.now();
			if (e.shiftKey && !interactiveMode) {
				// Shift + Up: navigate up and toggle at the same time
				if (focusedRowIndex > 0) {
					var prevFn = allCurveFiles[focusedRowIndex - 1];
					toggleFileSelection(prevFn);
					setHighlightRow(focusedRowIndex - 1);
				}
			} else {
				// Up: navigate up
				if (focusedRowIndex > 0) {
					setHighlightRow(focusedRowIndex - 1);
				}
			}
		} else if (e.keyCode === 40) { // Arrow Down
			e.preventDefault();
			lastKeyNavTime = Date.now();
			if (e.shiftKey && !interactiveMode) {
				// Shift + Down: navigate down and toggle at the same time
				if (focusedRowIndex < allCurveFiles.length - 1) {
					var nextFn = allCurveFiles[focusedRowIndex + 1];
					toggleFileSelection(nextFn);
					setHighlightRow(focusedRowIndex + 1);
				}
			} else {
				// Down: navigate down
				if (focusedRowIndex < allCurveFiles.length - 1) {
					setHighlightRow(focusedRowIndex + 1);
				}
			}
		} else if (e.keyCode === 45 || e.keyCode === 32) { // Insert or Space: toggle current without moving
			e.preventDefault();
			if (interactiveMode) return;
			var curFn = allCurveFiles[focusedRowIndex];
			if (curFn) {
				toggleFileSelection(curFn);
				updateRowFocusVisual();
			}
		}
		return;
	}

	// Outside curves list: Quickview-style file & channel navigation
	if (e.keyCode === 38) { // Up: prevs
		e.preventDefault();
		triggerNav('prevs');
	} else if (e.keyCode === 40) { // Down: nexts
		e.preventDefault();
		triggerNav('nexts');
	} else if (e.keyCode === 37) { // Left: prev
		e.preventDefault();
		if (!stepScanChannel(-1)) {
			triggerNav('prev');
		}
	} else if (e.keyCode === 39) { // Right: next
		e.preventDefault();
		if (!stepScanChannel(1)) {
			triggerNav('next');
		}
	}
});

function scrollRowIntoView(idx) {
	var r = document.getElementById('row_' + idx);
	if (r) r.scrollIntoView({ block: 'nearest' });
}

// Initialization
window.addEventListener('DOMContentLoaded', function() {
	var savedInteractive = null;
	var savedScrollTop = null;
	try {
		savedInteractive = sessionStorage.getItem('wspa_sts_interactive');
		savedScrollTop = sessionStorage.getItem('wspa_sts_scroll_top');
	} catch (e) {}

	if (savedInteractive !== null) {
		interactiveMode = (savedInteractive === '1');
	} else {
		interactiveMode = (allCurveFiles.length > maxCurvesLimit);
	}

	var cbs = document.querySelectorAll('.curve_checkbox');
	selectedCurveFiles = [];
	if (!interactiveMode) {
		cbs.forEach(function(cb) {
			if (cb.checked && selectedCurveFiles.length < maxCurvesLimit) {
				selectedCurveFiles.push(cb.value);
			} else {
				cb.checked = false;
			}
		});
		setInteractiveMode(false);
	} else {
		cbs.forEach(function(cb) { cb.checked = false; });
		setInteractiveMode(true);
	}

	initCurveChannelLookups();
	initCurveColors();

	if (initialTargetIndex >= 0) {
		focusedRowIndex = initialTargetIndex;
		lastAnchorIndex = initialTargetIndex;
	} else {
		focusedRowIndex = 0;
		lastAnchorIndex = 0;
	}
	updateRowFocusVisual();

	var initIdx = (initialTargetIndex >= 0) ? initialTargetIndex : 0;
	var initFn = (selectedCurveFiles.length > 0) ? selectedCurveFiles[0] : (allCurveFiles[initIdx] || '');
	if (initFn) {
		updateStsInfo(initFn);
		if (interactiveMode) {
			updateStsDotHighlight(initFn);
		} else {
			updateStsDotHighlight(null);
		}
	}

	if (initialTargetIndex >= 0) {
		scrollRowIntoView(initialTargetIndex);
	} else if (savedScrollTop !== null) {
		var curvesContInit = document.getElementById('curves_container');
		if (curvesContInit) curvesContInit.scrollTop = parseInt(savedScrollTop, 10);
	}

	var curvesContEl = document.getElementById('curves_container');
	if (curvesContEl) {
		curvesContEl.addEventListener('scroll', function() {
			try {
				sessionStorage.setItem('wspa_sts_scroll_top', curvesContEl.scrollTop);
			} catch (e) {}
		});
	}

	for (var w = 1; w <= 4; w++) {
		setupPlotCanvas(w);
		updateSweepButtonsVisual(w);
		updateAutoButtonsVisual(w);
	}
	updateSyncXVisual();
	updateStyleButtonsVisual();

	setupImageColumnResizer();
	setupTextareaResizer('qvud_resizer', 'qvud');
	setupTextareaResizer('sts_qvud_resizer', 'sts_qvud');

	var navForm = document.getElementById('sts_nav_form');
	if (navForm) {
		navForm.addEventListener('submit', function() {
			persistConfig();
		});
	}

	var savedLines = null;
	var savedPoints = null;
	try {
		savedLines = sessionStorage.getItem('wspa_sts_plot_lines');
		savedPoints = sessionStorage.getItem('wspa_sts_plot_points');
	} catch (e) {}

	var savedCfgStr = localStorage.getItem('wspa_sts_config');
	if (savedCfgStr) {
		try {
			var savedCfg = JSON.parse(savedCfgStr);
			if (savedCfg.showInfo !== undefined) {
				showInfo = (savedCfg.showInfo === '1');
				var infoContainer = document.getElementById('info_container');
				var btnInfo = document.getElementById('btn_info_toggle');
				if (infoContainer) infoContainer.style.display = showInfo ? 'block' : 'none';
				if (btnInfo) {
					if (showInfo) btnInfo.classList.add('btn-yellow');
					else btnInfo.classList.remove('btn-yellow');
				}
			}
			if (savedCfg.showSpec !== undefined) {
				showSpec = (savedCfg.showSpec === '1');
				var stsInfoContainer = document.getElementById('sts_info_container');
				var btnSpec = document.getElementById('btn_sts_info_toggle');
				if (stsInfoContainer) stsInfoContainer.style.display = showSpec ? 'block' : 'none';
				if (btnSpec) {
					if (showSpec) btnSpec.classList.add('btn-yellow');
					else btnSpec.classList.remove('btn-yellow');
				}
			}
			if (savedCfg.convMode !== undefined) {
				conversionMode = savedCfg.convMode;
				if (conversionMode === 'mev') conversionMode = 'ev';
				['none', 'ev', 'cm1'].forEach(function(m) {
					var b = document.getElementById('btn_conv_' + m);
					if (b) {
						if (m === conversionMode) b.classList.add('btn-yellow');
						else b.classList.remove('btn-yellow');
					}
				});
			}
			if (savedCfg.lambda !== undefined) {
				var parsedL = parseFloat(savedCfg.lambda);
				if (!isNaN(parsedL) && parsedL > 0) {
					centerLambda = parsedL;
					var lambdaInp = document.getElementById('sts_lambda_input');
					if (lambdaInp) lambdaInp.value = centerLambda;
				}
			}
			if (savedLines === null && savedCfg.showLines !== undefined) {
				savedLines = savedCfg.showLines;
			}
			if (savedPoints === null && savedCfg.showPoints !== undefined) {
				savedPoints = savedCfg.showPoints;
			}
			if (savedCfg.colorLink !== undefined) {
				colorLink = (savedCfg.colorLink === '1');
			}
			if (savedCfg.imgWidth) {
				var savedW = parseInt(savedCfg.imgWidth, 10);
				if (!isNaN(savedW) && savedW >= 200 && Math.abs(savedW - currentImgWidth) > 1) {
					setImageColumnWidth(savedW);
				}
			}
			for (var w = 1; w <= 4; w++) {
				if (savedCfg['g' + w + '_fwd'] !== undefined) {
					windowStates[w].fwd = (savedCfg['g' + w + '_fwd'] === '1');
				}
				if (savedCfg['g' + w + '_bwd'] !== undefined) {
					windowStates[w].bwd = (savedCfg['g' + w + '_bwd'] === '1');
				}
			}
		} catch (e) {}
	}

	if (savedLines !== null || savedPoints !== null) {
		if (savedLines !== null) showLines = (savedLines === '1');
		if (savedPoints !== null) showPoints = (savedPoints === '1');
		if (!showLines && !showPoints) showLines = true;
		updateStyleButtonsVisual();
	}
	updateColorLinkVisual();

	if (navForm) {
		setNavHidden(navForm, 'cfg_show_info', showInfo ? '1' : '0');
		setNavHidden(navForm, 'cfg_show_spec', showSpec ? '1' : '0');
		setNavHidden(navForm, 'cfg_conv_mode', conversionMode);
		setNavHidden(navForm, 'cfg_lambda', centerLambda);
		setNavHidden(navForm, 'cfg_plot_lines', showLines ? '1' : '0');
		setNavHidden(navForm, 'cfg_plot_points', showPoints ? '1' : '0');
		setNavHidden(navForm, 'cfg_color_link', colorLink ? '1' : '0');
	}

	var chanThumbnails = document.getElementById('channel_thumbnails');
	if (chanThumbnails) {
		chanThumbnails.addEventListener('click', function(e) {
			var a = e.target.closest('a');
			if (!a) return;
			e.preventDefault();
			var href = a.getAttribute('href') || '';
			var m = href.match(/command=goto\s+(\d+)/);
			if (m) {
				var targetCh = parseInt(m[1], 10);
				if (switchScanChannelInPlace(targetCh, a)) {
					return;
				}
				triggerNav('goto ' + targetCh);
			} else {
				window.location.href = href;
			}
		});
	}

	var btnPrev = document.getElementById('prev');
	if (btnPrev) {
		btnPrev.addEventListener('click', function(e) {
			if (stepScanChannel(-1)) {
				e.preventDefault();
			}
		});
	}

	var btnNext = document.getElementById('next');
	if (btnNext) {
		btnNext.addEventListener('click', function(e) {
			if (stepScanChannel(1)) {
				e.preventDefault();
			}
		});
	}

	if (showInfo || showSpec) {
		updateCurvesContainerHeight();
	}

	var initFn = (selectedCurveFiles.length > 0) ? selectedCurveFiles[0] : (allCurveFiles.length > 0 ? allCurveFiles[0] : '');
	if (initFn) updateStsInfo(initFn);

	onSelectionModified();

	if (window.ResizeObserver) {
		var ro = new ResizeObserver(function() {
			requestRenderAll();
		});
		var pCont = document.getElementById('plots_container');
		if (pCont) ro.observe(pCont);

		var roInfo = new ResizeObserver(function() {
			updateCurvesContainerHeight();
		});
		var qvudEl = document.getElementById('qvud');
		if (qvudEl) roInfo.observe(qvudEl);
		var stsQvudEl = document.getElementById('sts_qvud');
		if (stsQvudEl) roInfo.observe(stsQvudEl);
	}

	var curvesCont = document.getElementById('curves_container');
	if (curvesCont) curvesCont.addEventListener('mouseleave', clearHoverHighlights);
	var imgCont = document.getElementById('image_container');
	if (imgCont) {
		imgCont.addEventListener('mouseleave', clearHoverHighlights);
		imgCont.addEventListener('mousemove', function(e) {
			curvesListActive = true;
			var rect = imgCont.getBoundingClientRect();
			var mx = e.clientX - rect.left;
			var my = e.clientY - rect.top;
			var curH = imgCont.clientHeight;
			if (curH <= 0) return;

			var nearest = getNearestStsPoint(mx, my, curH);
			if (nearest && nearest.fn) {
				if (hoveredCurveFile !== nearest.fn) {
					highlightCurve(nearest.fn, true);
				}
			}
		});

		imgCont.addEventListener('click', function(e) {
			if (e.target.closest('.sts_dot') || e.target.closest('a')) return;
			var rect = imgCont.getBoundingClientRect();
			var mx = e.clientX - rect.left;
			var my = e.clientY - rect.top;
			var curH = imgCont.clientHeight;
			if (curH <= 0) return;

			var nearest = getNearestStsPoint(mx, my, curH);
			if (nearest && nearest.fn) {
				onPointClick(nearest.fn, e);
			}
		});
	}
	initStsPointsCache();
});

window.addEventListener('resize', function() {
	var colLeft = document.getElementById('col_left');
	var curW = colLeft ? colLeft.getBoundingClientRect().width : currentImgWidth;
	setImageColumnWidth(curW);
	requestRenderAll();
});

window.addEventListener('beforeunload', function() {
	persistConfig();
});
</script>

</body>
</html>
<?php exit; ?>
