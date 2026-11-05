<?php

require('globals.php');
require('auth.php');

function get_base_channel_name($ch) {
	$s = trim(preg_replace('/\b(down|up|forward|backward|forw|backw|fwd|bwd|trace|retrace)\b|\[[fb]\]|\([fb]\)|\s+[fb]\b/i', '', trim($ch)));
	$s = trim(preg_replace('/\s+/', ' ', $s));
	return $s !== '' ? $s : $ch;
}

$raw_chans = file_exists($userdir . $user . '/chan.dat') ? file($userdir . $user . '/chan.dat') : array();
$chans = $raw_chans;
$acqchans = file_exists($userdir . $user . '/acqchan.dat') ? preg_replace("/[\r\n]+/", "", file($userdir . $user . '/acqchan.dat')) : array();

$tmp_file = $userdir . $user . "/tmp.dat";
$msg = (file_exists($tmp_file) && filesize($tmp_file) > 0) ? file($tmp_file) : array();
$index = (!empty($msg) && isset($msg[1])) ? max(0, (int)(preg_split('/\s+/', $msg[1])[1]) - 1) : 0;
$target_bi = isset($chans[$index]) ? stripslashes(pathinfo(pathinfo(basename(trim($chans[$index])), PATHINFO_FILENAME), PATHINFO_FILENAME)) : "";
$cur_dataset = (!empty($msg) && isset($msg[0])) ? dirname(trim(stripslashes($msg[0]))) : (isset($_SESSION['path']) ? $_SESSION['path'] : '');

// Compute unique acquisition base channels for active dataset
$unique_acqchans = array();
if (!empty($acqchans)) {
	foreach ($acqchans as $acname) {
		$base = get_base_channel_name($acname);
		if ($base !== '' && !in_array($base, $unique_acqchans)) {
			$unique_acqchans[] = $base;
		}
	}
}

// Handle channel preselection form submit
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
	$selected_chans = isset($_POST['chans']) && is_array($_POST['chans']) ? $_POST['chans'] : array();
	if (empty($selected_chans)) {
		$_SESSION['overview_explicit_zero_dataset'] = $cur_dataset;
	} else {
		unset($_SESSION['overview_explicit_zero_dataset']);
	}

	$user_cfg = read_user_config($user);
	$prev_saved = array_key_exists('overview_channels', $user_cfg) ?
		(trim($user_cfg['overview_channels']) === '' ? array() : array_map('trim', explode(',', trim($user_cfg['overview_channels'])))) : array();

	// Retain previously saved channels from other datasets that are not present in this dataset
	$retained_other = array_diff($prev_saved, $unique_acqchans);
	$new_saved = array_values(array_unique(array_merge($retained_other, $selected_chans)));

	save_user_config(array('overview_channels' => implode(',', $new_saved)), $user);
	header('Location: quickview_over.php');
	exit;
}

// STEP a) Determine channels & user configuration
$user_cfg = read_user_config($user);
$saved_overview_channels = array_key_exists('overview_channels', $user_cfg) ?
	(trim($user_cfg['overview_channels']) === '' ? array() : array_map('trim', explode(',', trim($user_cfg['overview_channels'])))) : null;

$matching_saved = ($saved_overview_channels !== null) ? array_intersect($unique_acqchans, $saved_overview_channels) : array();
$is_explicit_zero = (isset($_SESSION['overview_explicit_zero_dataset']) && $_SESSION['overview_explicit_zero_dataset'] === $cur_dataset);

if ($is_explicit_zero) {
	$active_overview_channels = array();
} elseif (!empty($matching_saved)) {
	$active_overview_channels = $matching_saved;
} else {
	// Sensible defaults when no saved channels match this dataset
	if (count($unique_acqchans) > 4) {
		$target_ac = isset($acqchans[$index]) ? get_base_channel_name($acqchans[$index]) : '';
		if ($target_ac !== '' && in_array($target_ac, $unique_acqchans)) {
			$active_overview_channels = array($target_ac);
		} else {
			$found_z = false;
			foreach ($unique_acqchans as $uac) {
				if (stripos($uac, 'z') !== false || stripos($uac, 'topo') !== false || stripos($uac, 'height') !== false) {
					$active_overview_channels = array($uac);
					$found_z = true;
					break;
				}
			}
			if (!$found_z && !empty($unique_acqchans)) {
				$active_overview_channels = array($unique_acqchans[0]);
			} else {
				$active_overview_channels = array();
			}
		}
	} else {
		$active_overview_channels = $unique_acqchans;
	}
}

require('over.php');
require('head.php');

$userlnk = ($shm != '') ? $userlink : $userdir;
$scan_dim_cache = array();

// STEP b) Determine image sizes and grid dimensions
function get_channel_dimensions($c, $bi, $img_file, $raw_file, $chans, $userlnk, $user) {
	global $scan_dim_cache;
	$sz = @filesize($img_file);
	if ($sz !== false && $sz > 0 && $sz < 500) return array('w' => 8, 'h' => 8, 'css_w' => 8, 'css_h' => 8);

	$scale_fn = function($w, $h) {
		$scale = min(100 / $w, 100 / $h, 1.0);
		return array('w' => $w, 'h' => $h, 'css_w' => max(1, round($w * $scale)), 'css_h' => max(1, round($h * $scale)));
	};

	if (isset($scan_dim_cache[$bi])) return $scale_fn($scan_dim_cache[$bi][0], $scan_dim_cache[$bi][1]);

	if ($sz !== false && $sz >= 500) {
		$hh = @getimagesize($img_file);
		if ($hh && !empty($hh[0]) && !empty($hh[1])) {
			$scan_dim_cache[$bi] = array($hh[0], $hh[1]);
			return $scale_fn($hh[0], $hh[1]);
		}
	}

	if ($raw_file !== '' && file_exists($raw_file)) {
		$hdr = parse_spm_header($raw_file);
		if (!empty($hdr['xs']) && !empty($hdr['ys']) && $hdr['xs'] > 0 && $hdr['ys'] > 0) {
			$w = 100; $h = max(1, round(100 * ($hdr['ys'] / $hdr['xs'])));
			$scan_dim_cache[$bi] = array($w, $h);
			return $scale_fn($w, $h);
		}
	}

	$scan_dim_cache[$bi] = array(100, 100);
	return array('w' => 100, 'h' => 100, 'css_w' => 100, 'css_h' => 100);
}

$scan_groups = array();
$c = 0;

foreach ($chans as $i) {
	$clean_i = stripslashes(trim($i));
	$bi = pathinfo(pathinfo(basename($clean_i), PATHINFO_FILENAME), PATHINFO_FILENAME);
	$chan_name = isset($acqchans[$c]) ? trim($acqchans[$c]) : '';
	$base_chan_name = get_base_channel_name($chan_name);

	if (in_array($base_chan_name, $active_overview_channels)) {
		$raw_file = isset($raw_chans[$c]) ? trim(stripslashes($raw_chans[$c])) : "";
		$img_file = $userlnk . $user . '/tmp' . $c . '.png';
		$dim = get_channel_dimensions($c, $bi, $img_file, $raw_file, $chans, $userlnk, $user);

		if (!isset($scan_groups[$bi])) {
			$clean_base_file = dirname($raw_file) . '/' . $bi;
			$mapfile = get_meta_path_for_file($clean_base_file, 'map', $user);
			$has_sts = ($mapfile !== "" && file_exists($mapfile));

			if (!$has_sts) {
				if (file_exists(dirname($raw_file) . '/' . $bi . '.map')) {
					$has_sts = true;
				} elseif (trim($bi) !== $bi) {
					$trimmed_base = dirname($raw_file) . '/' . trim($bi);
					$trimmed_map = get_meta_path_for_file($trimmed_base, 'map', $user);
					if ($trimmed_map !== "" && file_exists($trimmed_map)) {
						$has_sts = true;
					} elseif (file_exists(dirname($raw_file) . '/' . trim($bi) . '.map')) {
						$has_sts = true;
					}
				}
			}

			$scan_groups[$bi] = array(
				'bi' => $bi,
				'has_sts' => $has_sts,
				'items' => array(),
				'max_h' => 0,
				'is_target_row' => ($target_bi !== '' && $bi === $target_bi)
			);
		}

		$base_border = $scan_groups[$bi]['has_sts'] ? "border:1px solid #0e0;" : (in_array($c, $chline) ? "border:1px solid #fff;" : "border:1px solid #567;");
		$outline_css = in_array($c, $chline) ? " outline: 2px solid #0aa; outline-offset: -2px;" : "";
		$border_css = $base_border . $outline_css;

		$scan_groups[$bi]['items'][] = array(
			'c' => $c, 'chan_name' => $chan_name, 'img_file' => $img_file, 'dim' => $dim, 'border_css' => $border_css
		);
		if ($dim['css_h'] > $scan_groups[$bi]['max_h']) {
			$scan_groups[$bi]['max_h'] = $dim['css_h'];
		}
	}
	$c++;
}

// STEP c) Output HTML markup with hanging channels window
?>
<div class="fill">

<!-- Channels Panel: Rendered IN THE BEGINNING, hanging OVER images on top-right -->
<div id="channel_panel" style="position:fixed; top:25px; right:20px; z-index:1000; background:#181818; border:1px solid #444; padding:6px; box-sizing:border-box; width:200px; max-height:calc(100vh - 40px); overflow-y:auto;">
	<FORM id="chan_form" method="post" action="quickview_over.php">
	<div style="font-weight:bold; margin-bottom:6px; border-bottom:1px solid #444; padding-bottom:4px; color:#bff;">Channels</div>
	<div style="margin-bottom:6px;">
		<input type="button" value="All" onclick="toggleAllChans(true)">
		<input type="button" value="None" onclick="toggleAllChans(false)">
	</div>
	<div id="channel_checkboxes" style="display:flex; flex-direction:column; gap:4px;">
<?php
foreach ($unique_acqchans as $uchan) {
	$escaped = htmlspecialchars($uchan);
	$cb_checked = in_array($uchan, $active_overview_channels) ? 'checked' : '';
	echo '<label style="cursor:pointer; display:flex; align-items:center; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="' . $escaped . '">';
	echo '<input type="checkbox" name="chans[]" value="' . $escaped . '" ' . $cb_checked . ' onchange="this.form.submit()" style="vertical-align:middle; margin-right:6px; flex-shrink:0;">';
	echo '<span style="overflow:hidden; text-overflow:ellipsis;">' . $escaped . '</span></label>';
}
?>
	</div>
	</FORM>
</div>

<!-- Left Side Grid Container: opacity 0 during DOM assembly to prevent pre-scroll flash -->
<div class="scrollfill" id="overview_scroll" style="height:calc(100vh - 20px); overflow-y:auto; overflow-x:auto; opacity:0;">
<?php
if (empty($scan_groups)) {
	echo '<div style="padding:20px; color:#aaa;">No channels selected. Use the Channels panel to select channels.</div>';
} else {
	// TABLE has compact natural height without min-height to prevent row vertical stretching
	echo '<TABLE style="position:relative; z-index:1; border-collapse:collapse;">';

	// STEP d) Populate grid with images using native lazy loading
	foreach ($scan_groups as $bi => $group) {
		$tr_attr = $group['is_target_row'] ? ' id="active_row"' : '';
		echo '<TR' . $tr_attr . '><TD style="padding:0; margin:0; white-space:nowrap;">';
		foreach ($group['items'] as $item) {
			$c = $item['c'];
			$img_file = $item['img_file'];
			$sz = @filesize($img_file);
			$is_flat = ($sz !== false && $sz > 0 && $sz < 500);

			if ($is_flat) {
				$size_style = 'width:8px; height:8px; max-width:8px; max-height:8px;';
				$w_h_attr = 'width="8" height="8"';
			} else {
				$size_style = 'max-width:100px; max-height:100px; width:auto; height:auto;';
				$w_h_attr = '';
			}

			$v = get_dataset_token($user) . '-' . (@filemtime($img_file) ?: '0');
			$img_src = $img_file . '?v=' . $v;
			$tooltip = htmlspecialchars($bi . ($item['chan_name'] !== '' ? ' [' . $item['chan_name'] . ']' : ''));

			echo '<a href="quickview.php?command=goto '.($c+1).'&over=over" title="'.$tooltip.'">';
			echo '<img id="img'.$c.'" src="'.$img_src.'" '.$w_h_attr.' style="'.$size_style.' padding:1px; background-color:#111; '.$item['border_css'].'" title="'.$tooltip.'">';
			echo '</a>';
		}
		echo '</TD></TR>';
	}
	echo '</TABLE>';
}
?>
</div>

</div>

<script>
if ('scrollRestoration' in history) { history.scrollRestoration = 'manual'; }

function centerActiveRow() {
	var sf = document.getElementById("overview_scroll");
	var row = document.getElementById("active_row");
	if (sf) {
		if (row) {
			var sfRect = sf.getBoundingClientRect();
			var rowRect = row.getBoundingClientRect();
			var rowCenterInScroll = (rowRect.top - sfRect.top) + sf.scrollTop + (row.offsetHeight / 2);
			sf.scrollTop = Math.max(0, rowCenterInScroll - (sf.clientHeight / 2));
		}
		sf.style.opacity = '1';
	}
}

// Immediate scroll & reveal right after DOM table completion
centerActiveRow();
window.addEventListener("DOMContentLoaded", centerActiveRow);



function toggleAllChans(enable) {
	var cbs = document.querySelectorAll('#channel_checkboxes input[type="checkbox"]');
	cbs.forEach(function(cb) { cb.checked = enable; });
	document.getElementById('chan_form').submit();
}
</script>
</body>
<?php exit; ?>
