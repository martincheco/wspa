<?php

require('globals.php');
require('auth.php');

// Handle channel preselection form POST submit
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
	$selected_chans = isset($_POST['chans']) && is_array($_POST['chans']) ? $_POST['chans'] : array();
	$chans_str = implode(',', $selected_chans);
	save_user_config(array('overview_channels' => $chans_str), $user);
	header('Location: quickview_over.php');
	exit;
}

// STEP 1: Load preselection of the channels from user config
$user_cfg = read_user_config($user);
$saved_overview_channels = null;
if (array_key_exists('overview_channels', $user_cfg)) {
	$val = trim($user_cfg['overview_channels']);
	if ($val === '') {
		$saved_overview_channels = array(); // Explicitly 0 channels selected
	} else {
		$saved_overview_channels = array_map('trim', explode(',', $val));
	}
}

$tmpdat = $userdir . $user . "/tmp.dat";

function get_base_channel_name($ch) {
	$s = trim($ch);
	$pattern = '/\b(down|up|forward|backward|forw|backw|fwd|bwd|trace|retrace)\b|\[[fb]\]|\([fb]\)/i';
	$s = preg_replace($pattern, '', $s);
	$s = preg_replace('/\s+[fb]\b/i', '', $s);
	$s = trim(preg_replace('/\s+/', ' ', $s));
	return $s !== '' ? $s : $ch;
}

// Read channel info and raw channel file paths
if (file_exists($userdir . $user . '/chan.dat')) {
	$chans = file($userdir . $user . '/chan.dat');
	$raw_chans = $chans;
}
if (file_exists($userdir . $user . '/acqchan.dat')) {
	$acqchans = file($userdir . $user . '/acqchan.dat');
}
$acqchans = preg_replace("/[\\n\\r]+/", "", $acqchans);

$msg = file($tmpdat);
$mapdir = pathinfo(trim(stripslashes($msg[0])), PATHINFO_DIRNAME);

// Read image index from tmp.dat
$parts = preg_split('/\s+/', $msg[1]);
$index = $parts[1] - 1;

// Resolve target base filename strictly for active $index
$target_bi = "";
if (isset($chans[$index])) {
	$info = pathinfo($chans[$index]);
	$val = isset($info['extension']) ? $info['extension'] : '';
	$target_bi = basename($chans[$index], '.' . $val);
	$info = pathinfo($target_bi);
	$val = isset($info['extension']) ? $info['extension'] : '';
	$target_bi = basename($target_bi, '.' . $val);
}

require('over.php');
require('head.php');

if ($shm != '') { $userlnk = $userlink; } else { $userlnk = $userdir; }

$scan_dim_cache = array();

function get_channel_dimensions($c, $bi, $img_file, $raw_file, $chans, $userlnk, $user) {
	global $scan_dim_cache;

	$sz = @filesize($img_file);
	// Flat image constant value placeholder (< 500 bytes) -> render at 8x8px
	if ($sz !== false && $sz < 500) {
		return array('w' => 8, 'h' => 8, 'css_w' => 8, 'css_h' => 8);
	}

	$calc_scale = function($w, $h) {
		$scale = min(100 / $w, 100 / $h, 1.0);
		return array(
			'w' => $w,
			'h' => $h,
			'css_w' => max(1, round($w * $scale)),
			'css_h' => max(1, round($h * $scale))
		);
	};

	// Check scan group cache first
	if (isset($scan_dim_cache[$bi])) {
		return $calc_scale($scan_dim_cache[$bi][0], $scan_dim_cache[$bi][1]);
	}

	// Try getimagesize on current thumbnail if >= 500 bytes
	if ($sz !== false && $sz >= 500) {
		$hh = @getimagesize($img_file);
		if ($hh && !empty($hh[0]) && !empty($hh[1])) {
			$scan_dim_cache[$bi] = array($hh[0], $hh[1]);
			return $calc_scale($hh[0], $hh[1]);
		}
	}

	// Check sibling channel thumbnails for same base file $bi
	$chk_c = $c;
	while (isset($chans[$chk_c])) {
		$chk_info = pathinfo($chans[$chk_c]);
		$chk_val = isset($chk_info['extension']) ? $chk_info['extension'] : '';
		$chk_bi = basename($chans[$chk_c], '.' . $chk_val);
		$chk_info = pathinfo($chk_bi);
		$chk_val = isset($chk_info['extension']) ? $chk_info['extension'] : '';
		$chk_bi = basename($chk_bi, '.' . $chk_val);
		if ($chk_bi != $bi) break;

		$chk_img = $userlnk . $user . '/tmp' . $chk_c . '.png';
		$chk_sz = @filesize($chk_img);
		if ($chk_sz !== false && $chk_sz >= 500) {
			$chk_hh = @getimagesize($chk_img);
			if ($chk_hh && !empty($chk_hh[0]) && !empty($chk_hh[1])) {
				$scan_dim_cache[$bi] = array($chk_hh[0], $chk_hh[1]);
				return $calc_scale($chk_hh[0], $chk_hh[1]);
			}
		}
		$chk_c++;
	}

	// Native Physical Scan Dimensions Fallback (xs / ys)
	if ($raw_file !== '' && file_exists($raw_file)) {
		$hdr = parse_spm_header($raw_file);
		if ($hdr['xs'] > 0 && $hdr['ys'] > 0) {
			$ratio = $hdr['xs'] / $hdr['ys'];
			$w = 100;
			$h = max(1, round(100 / $ratio));
			$scan_dim_cache[$bi] = array($w, $h);
			return $calc_scale($w, $h);
		}
	}

	// Default 100x100 if no image size or header found
	$scan_dim_cache[$bi] = array(100, 100);
	return array('w' => 100, 'h' => 100, 'css_w' => 100, 'css_h' => 100);
}

// STEP 2 & STEP 3: Pre-extract unique channels & build grid structure in PHP memory
$scan_groups = array();
$unique_acqchans = array();

$c = 0;
$obi = "";
foreach ($chans as $i) {
	$info = pathinfo($i);

	$value = isset($info['extension']) ? $info['extension'] : '';
	$bi = basename($i, '.' . $value);
	$info = pathinfo($bi);

	$value = isset($info['extension']) ? $info['extension'] : '';
	$bi = basename($bi, '.' . $value);

	$chan_name = isset($acqchans[$c]) ? trim($acqchans[$c]) : '';
	$base_chan_name = get_base_channel_name($chan_name);
	if ($base_chan_name !== '' && !in_array($base_chan_name, $unique_acqchans)) {
		$unique_acqchans[] = $base_chan_name;
	}

	$is_checked = ($saved_overview_channels === null || in_array($base_chan_name, $saved_overview_channels));

	if ($is_checked) {
		$raw_file = isset($raw_chans[$c]) ? trim(stripslashes($raw_chans[$c])) : "";
		$img_file = $userlnk . $user . '/tmp' . $c . '.png';
		$dim = get_channel_dimensions($c, $bi, $img_file, $raw_file, $chans, $userlnk, $user);

		if (!isset($scan_groups[$bi])) {
			$mapdir = pathinfo($raw_file, PATHINFO_DIRNAME);
			$mapfile = $mapdir . '/' . $bi . '.map';
			if (!file_exists($mapfile)) {
				$meta_map = get_meta_path_for_file($raw_file, 'map', $user);
				if (file_exists($meta_map) && is_file($meta_map)) {
					$mapfile = $meta_map;
				} else {
					$mapfile = "";
				}
			}

			$has_sts = ($mapfile !== "" && file_exists($mapfile) && filesize($mapfile) > 0);
			$scan_groups[$bi] = array(
				'bi' => $bi,
				'has_sts' => $has_sts,
				'items' => array(),
				'max_h' => 0,
				'is_target_row' => ($target_bi !== '' && $bi === $target_bi)
			);
		}

		$is_active = ($c == $index);

		if (in_array($c, $chline)) {
			$border_css = "border:1px solid #fff; outline: 2px solid #0aa; outline-offset: -2px;";
		} else if ($scan_groups[$bi]['has_sts']) {
			$border_css = "border:1px solid #0e0;";
		} else {
			$border_css = "border:1px solid #567;";
		}

		$scan_groups[$bi]['items'][] = array(
			'c' => $c,
			'chan_name' => $chan_name,
			'base_chan_name' => $base_chan_name,
			'img_file' => $img_file,
			'dim' => $dim,
			'border_css' => $border_css,
			'is_active' => $is_active
		);
		if ($dim['css_h'] > $scan_groups[$bi]['max_h']) {
			$scan_groups[$bi]['max_h'] = $dim['css_h'];
		}
	}
	$c++;
}

// Pre-calculate heights & active row offset in PHP memory before generating HTML
$active_row_top = 0;
$active_row_height = 102;
$current_y = 0;
$found_target_row = false;

foreach ($scan_groups as $bi => $group) {
	$row_h = max(10, $group['max_h'] + 2);
	if ($group['is_target_row'] && !$found_target_row) {
		$active_row_top = $current_y;
		$active_row_height = $row_h;
		$found_target_row = true;
	}
	$current_y += $row_h;
}
$total_table_height = max(100, $current_y);

// STEP 4: Output HTML layout with Channels Panel IN THE BEGINNING hanging OVER images on top-right
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
	echo '<span style="overflow:hidden; text-overflow:ellipsis;">' . $escaped . '</span>';
	echo '</label>';
}
?>
	</div>
	</FORM>
</div>

<!-- Left Side Grid Container: Pre-scrolled at line 1 before row 0 is parsed -->
<div class="scrollfill" id="overview_scroll" style="height:calc(100vh - 20px); overflow-y:auto; overflow-x:auto;">
<?php
if (empty($scan_groups)) {
	echo '<div style="padding:20px; color:#aaa;">No channels selected. Use the Channels panel to select channels.</div>';
} else {
	echo '<TABLE style="position:relative; z-index:1; border-collapse:collapse; min-height:' . $total_table_height . 'px;">';
	echo '<script>';
	echo '(function(){';
	echo '  var sf = document.getElementById("overview_scroll");';
	echo '  if (sf) {';
	echo '    var rowTop = ' . $active_row_top . ';';
	echo '    var rowH = ' . $active_row_height . ';';
	echo '    var vH = sf.clientHeight || (window.innerHeight - 20);';
	echo '    sf.scrollTop = Math.max(0, rowTop + (rowH / 2) - (vH / 2));';
	echo '  }';
	echo '})();';
	echo '</script>';

	foreach ($scan_groups as $bi => $group) {
		$tr_attr = $group['is_target_row'] ? ' id="active_row"' : '';
		echo '<TR' . $tr_attr . '><TD style="padding:0; margin:0; white-space:nowrap;">';
		if ($group['is_target_row']) {
			echo '<script>(function(){ var sf = document.getElementById("overview_scroll"); var row = document.getElementById("active_row"); if (sf && row) { var sfRect = sf.getBoundingClientRect(); var rowRect = row.getBoundingClientRect(); var targetY = (rowRect.top - sfRect.top) + sf.scrollTop; var rowCenter = targetY + (row.offsetHeight / 2); sf.scrollTop = Math.max(0, rowCenter - (sf.clientHeight / 2)); } })();</script>';
		}
		foreach ($group['items'] as $item) {
			$c = $item['c'];
			$w = $item['dim']['w'];
			$h = $item['dim']['h'];
			$css_w = $item['dim']['css_w'];
			$css_h = $item['dim']['css_h'];

			$hash = @filemtime($item['img_file']);
			$real_src = 'serve_image.php?file=' . urlencode($item['img_file']) . '&v=' . $hash;

			$w_attr = 'width="' . $css_w . '" height="' . $css_h . '"';
			$ar_css = 'width:' . $css_w . 'px; height:' . $css_h . 'px; aspect-ratio: ' . $w . ' / ' . $h . '; ';
			$tooltip = htmlspecialchars($bi . ($item['chan_name'] !== '' ? ' [' . $item['chan_name'] . ']' : ''));

			// STEP 5: Fill images by native HTML5 loading="lazy"
			echo '<a href="quickview.php?command=goto '.($c+1).'&over=over" title="'.$tooltip.'">';
			echo '<img id="img'.$c.'" src="'.$real_src.'" '.$w_attr.' loading="lazy" style="'.$ar_css.'max-width:100px;max-height:100px;padding:1px;background-color:#111;'.$item['border_css'].'" title="'.$tooltip.'" onerror="handleImgError(this)">';
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
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual';
}

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
  cbs.forEach(function(cb) {
    cb.checked = enable;
  });
  document.getElementById('chan_form').submit();
}
</script>

</BODY>

<?php exit; ?>
