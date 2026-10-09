<?php

require('globals.php');
require('auth.php');

// Handle channel preselection form submit
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
	$selected_chans = isset($_POST['chans']) && is_array($_POST['chans']) ? $_POST['chans'] : array();
	save_user_config(array('overview_channels' => implode(',', $selected_chans)), $user);
	header('Location: quickview_over.php');
	exit;
}

// STEP a) Determine channels & user configuration
$user_cfg = read_user_config($user);
$saved_overview_channels = array_key_exists('overview_channels', $user_cfg) ?
	(trim($user_cfg['overview_channels']) === '' ? array() : array_map('trim', explode(',', trim($user_cfg['overview_channels'])))) : null;

function get_base_channel_name($ch) {
	$s = trim(preg_replace('/\b(down|up|forward|backward|forw|backw|fwd|bwd|trace|retrace)\b|\[[fb]\]|\([fb]\)|\s+[fb]\b/i', '', trim($ch)));
	$s = trim(preg_replace('/\s+/', ' ', $s));
	return $s !== '' ? $s : $ch;
}

$chans = file_exists($userdir . $user . '/chan.dat') ? file($userdir . $user . '/chan.dat') : array();
$acqchans = file_exists($userdir . $user . '/acqchan.dat') ? preg_replace("/[\r\n]+/", "", file($userdir . $user . '/acqchan.dat')) : array();

$msg = file($userdir . $user . "/tmp.dat");
$index = (int)(preg_split('/\s+/', $msg[1])[1]) - 1;
$target_bi = isset($chans[$index]) ? pathinfo(pathinfo(basename(trim($chans[$index])), PATHINFO_FILENAME), PATHINFO_FILENAME) : "";

require('over.php');
require('head.php');

$userlnk = ($shm != '') ? $userlink : $userdir;
$scan_dim_cache = array();

// STEP b) Determine image sizes and grid dimensions
function get_channel_dimensions($c, $bi, $img_file, $raw_file, $chans, $userlnk, $user) {
	global $scan_dim_cache;
	$sz = @filesize($img_file);
	if ($sz !== false && $sz < 500) return array('w' => 8, 'h' => 8, 'css_w' => 8, 'css_h' => 8);

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
$unique_acqchans = array();
$c = 0;

foreach ($chans as $i) {
	$bi = pathinfo(pathinfo(basename(trim($i)), PATHINFO_FILENAME), PATHINFO_FILENAME);
	$chan_name = isset($acqchans[$c]) ? trim($acqchans[$c]) : '';
	$base_chan_name = get_base_channel_name($chan_name);
	if ($base_chan_name !== '' && !in_array($base_chan_name, $unique_acqchans)) {
		$unique_acqchans[] = $base_chan_name;
	}

	if ($saved_overview_channels === null || in_array($base_chan_name, $saved_overview_channels)) {
		$raw_file = isset($chans[$c]) ? trim(stripslashes($chans[$c])) : "";
		$img_file = $userlnk . $user . '/tmp' . $c . '.png';
		$dim = get_channel_dimensions($c, $bi, $img_file, $raw_file, $chans, $userlnk, $user);

		if (!isset($scan_groups[$bi])) {
			$mapdir = pathinfo($raw_file, PATHINFO_DIRNAME);
			$mapfile = $mapdir . '/' . $bi . '.map';
			if (!file_exists($mapfile)) {
				$meta_map = get_meta_path_for_file($raw_file, 'map', $user);
				$mapfile = (file_exists($meta_map) && is_file($meta_map)) ? $meta_map : "";
			}
			$scan_groups[$bi] = array(
				'bi' => $bi,
				'has_sts' => ($mapfile !== "" && file_exists($mapfile) && filesize($mapfile) > 0),
				'items' => array(),
				'max_h' => 0,
				'is_target_row' => ($target_bi !== '' && $bi === $target_bi)
			);
		}

		$border_css = in_array($c, $chline) ? "border:1px solid #fff; outline: 2px solid #0aa; outline-offset: -2px;" :
			($scan_groups[$bi]['has_sts'] ? "border:1px solid #0e0;" : "border:1px solid #567;");

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
	$cb_checked = ($saved_overview_channels === null || in_array($uchan, $saved_overview_channels)) ? 'checked' : '';
	echo '<label style="cursor:pointer; display:flex; align-items:center; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="' . $escaped . '">';
	echo '<input type="checkbox" name="chans[]" value="' . $escaped . '" ' . $cb_checked . ' onchange="this.form.submit()" style="vertical-align:middle; margin-right:6px; flex-shrink:0;">';
	echo '<span style="overflow:hidden; text-overflow:ellipsis;">' . $escaped . '</span></label>';
}
?>
	</div>
	</FORM>
</div>

<!-- Left Side Grid Container: opacity 0 during DOM assembly to prevent pre-scroll flash -->
<div class="scrollfill" id="overview_scroll" style="height:calc(100vh - 20px); overflow-y:auto; overflow-x:auto; opacity:0; transition:opacity 0.05s ease-in;">
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
			$w = $item['dim']['w'];
			$h = $item['dim']['h'];
			$css_w = $item['dim']['css_w'];
			$css_h = $item['dim']['css_h'];
			$hash = @filemtime($item['img_file']);
			$real_src = 'serve_image.php?file=' . urlencode($item['img_file']) . '&v=' . $hash;
			$tooltip = htmlspecialchars($bi . ($item['chan_name'] !== '' ? ' [' . $item['chan_name'] . ']' : ''));

			echo '<a href="quickview.php?command=goto '.($c+1).'&over=over" title="'.$tooltip.'">';
			echo '<img id="img'.$c.'" src="'.$real_src.'" width="'.$css_w.'" height="'.$css_h.'" loading="lazy" style="width:'.$css_w.'px;height:'.$css_h.'px;aspect-ratio:'.$w.' / '.$h.';max-width:100px;max-height:100px;padding:1px;background-color:#111;'.$item['border_css'].'" title="'.$tooltip.'" onerror="handleImgError(this)">';
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

function handleImgError(img) {
	if (!img.getAttribute('data-retried')) {
		img.setAttribute('data-retried', 'true');
		setTimeout(function() {
			var src = img.src;
			if (src && src.indexOf('serve_image.php') !== -1) {
				img.src = src.split('&retry=')[0] + '&retry=' + Date.now();
			}
		}, 400);
	}
}

function toggleAllChans(enable) {
	var cbs = document.querySelectorAll('#channel_checkboxes input[type="checkbox"]');
	cbs.forEach(function(cb) { cb.checked = enable; });
	document.getElementById('chan_form').submit();
}
</script>
</body>
<?php exit; ?>
