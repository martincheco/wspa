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

$user_cfg = read_user_config($user);
$saved_overview_channels = null;
if (isset($user_cfg['overview_channels']) && trim($user_cfg['overview_channels']) !== '') {
	$saved_overview_channels = array_map('trim', explode(',', $user_cfg['overview_channels']));
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

require('over.php');
require('head.php');

if ($shm != '') { $userlnk = $userlink; } else { $userlnk = $userdir; }

?>

<div class="fill">
<div class="scrollfill">
<TABLE style="width:100%; border-collapse:collapse;">
<TR>
	<TD style="vertical-align:top;height:100%;width:100%;">
<?php

$scan_dim_cache = array();

function get_channel_dimensions($c, $bi, $img_file, $raw_file, $chans, $userlnk, $user) {
	global $scan_dim_cache;

	$sz = @filesize($img_file);
	// Flat image constant value placeholder (< 500 bytes) -> render at 8x8px
	if ($sz !== false && $sz < 500) {
		return array('w' => 8, 'h' => 8);
	}

	// Check scan group cache first
	if (isset($scan_dim_cache[$bi])) {
		return array('w' => $scan_dim_cache[$bi][0], 'h' => $scan_dim_cache[$bi][1]);
	}

	// Try getimagesize on current thumbnail if >= 500 bytes
	if ($sz !== false && $sz >= 500) {
		$hh = @getimagesize($img_file);
		if ($hh && !empty($hh[0]) && !empty($hh[1])) {
			$scan_dim_cache[$bi] = array($hh[0], $hh[1]);
			return array('w' => $hh[0], 'h' => $hh[1]);
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
				return array('w' => $chk_hh[0], 'h' => $chk_hh[1]);
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
			return array('w' => $w, 'h' => $h);
		}
	}

	// Default 100x100 if no image size or header found
	$scan_dim_cache[$bi] = array(100, 100);
	return array('w' => 100, 'h' => 100);
}

$scan_groups = array();
$unique_acqchans = array();

$c = 0;
$obi = "";
$active_row_idx = 0;
$row_counter = 0;

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
				'items' => array()
			);
			$row_counter++;
		}

		$is_active = ($c == $index || in_array($c, $chline));
		if ($is_active && $active_row_idx === 0) {
			$active_row_idx = max(0, $row_counter - 1);
		}

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
	}
	$c++;
}

$estimated_scroll_top = max(0, ($active_row_idx * 104) - 200);

echo '<script>';
echo '(function(){';
echo '  var sf = document.querySelector(".scrollfill");';
echo '  if (sf) { sf.scrollTop = ' . $estimated_scroll_top . '; }';
echo '})();';
echo '</script>';

// Step 4: Output HTML grid at exact sizes, matching past over.php / quickview_over.php / browser.php preview mode
echo '<TABLE style="position:relative; z-index:1;">';
foreach ($scan_groups as $bi => $group) {
	echo '<TR><TD>';
	foreach ($group['items'] as $item) {
		$c = $item['c'];
		$w = $item['dim']['w'];
		$h = $item['dim']['h'];

		$hash = @filemtime($item['img_file']);
		$real_src = 'serve_image.php?file=' . urlencode($item['img_file']) . '&v=' . $hash;

		$w_attr = ($w > 0 && $h > 0) ? 'width="' . $w . '" height="' . $h . '"' : '';
		$ar_css = ($w > 0 && $h > 0) ? 'aspect-ratio: ' . $w . ' / ' . $h . '; ' : '';
		$tooltip = htmlspecialchars($bi . ($item['chan_name'] !== '' ? ' [' . $item['chan_name'] . ']' : ''));

		// Step 5: Fill images by native HTML5 loading="lazy"
		echo '<a href="quickview.php?command=goto '.($c+1).'&over=over" title="'.$tooltip.'">';
		echo '<img id="img'.$c.'" src="'.$real_src.'" '.$w_attr.' loading="lazy" style="'.$ar_css.'width:auto;height:auto;max-width:100px;max-height:100px;padding:1px;background-color:#111;'.$item['border_css'].'" title="'.$tooltip.'" onerror="handleImgError(this)">';
		echo '</a>';

		if ($c == $index) {
			echo '<script>(function(){ var el = document.getElementById("img' . $c . '"); if (el) { el.scrollIntoView({ behavior: "auto", block: "center", inline: "center" }); } })();</script>';
		}
	}
	echo '</TD></TR>';
}
echo '</TABLE>';

?>

	</TD>

	<!-- Right Side Channel Preselection Window -->
	<TD style="vertical-align:top; width:200px;">
		<FORM id="chan_form" method="post" action="quickview_over.php">
		<div id="channel_panel" style="position:sticky; top:0; right:0; border-left:1px solid #444; border-bottom:1px solid #444; background:#181818; padding:6px; box-sizing:border-box; width:200px; overflow-x:hidden;">
			<div style="font-weight:bold; margin-bottom:6px; border-bottom:1px solid #444; padding-bottom:4px; color:#bff;">Channels</div>
			<div style="margin-bottom:6px;">
				<input type="button" value="All" onclick="toggleAllChans(true)">
				<input type="button" value="None" onclick="toggleAllChans(false)">
			</div>
			<div id="channel_checkboxes" style="display:flex; flex-direction:column; gap:4px; max-height:calc(100vh - 80px); overflow-y:auto; overflow-x:hidden;">
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
		</div>
		</FORM>
	</TD>

</TR>
</TABLE>
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

function scrollToActiveImage() {
  var targetImage = document.getElementById('<?echo 'img'.$index;?>');
  if (targetImage) {
    targetImage.scrollIntoView({ behavior: 'auto', block: 'center', inline: 'center' });
  }
}

scrollToActiveImage();
</script>

</BODY>

<?php exit; ?>
