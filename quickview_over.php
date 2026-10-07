<?php

require('globals.php');
require('auth.php');
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
<TABLE>
<TR>
	<TD style="vertical-align:top;height:100%;width:100%;">
		<TABLE style="position:relative;z-index:1;">
		<TR>
			<TD>
<?php

$c = 0;
$obi = "";
foreach ($chans as $i) {
	$info = pathinfo($i);

	$value = isset($info['extension']) ? $info['extension'] : '';
	$bi = basename($i, '.' . $value);
	$info = pathinfo($bi);

	$value = isset($info['extension']) ? $info['extension'] : '';
	$bi = basename($bi, '.' . $value);

	if ($bi != $obi) {
		echo "</TD></TR><TR><TD>";

		$raw_file = isset($raw_chans[$c]) ? trim(stripslashes($raw_chans[$c])) : "";
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

		$has_sts = false;
		if ($mapfile !== "" && file_exists($mapfile) && filesize($mapfile) > 0) {
			$stsim = 'sts.png'; $mtagc = 'color:#0e0;';
			$bordercol = "#00ff41";
			$has_sts = true;
		} else {
			$bordercol = "#567";
		}

		if (in_array($c, $chline)) {
			$border_css = "border:2px solid #fff; outline: 2px solid #0aa; outline-offset: -2px;";
		} else if ($has_sts) {
			$border_css = "border:2px solid #00ff41; box-shadow: 0 0 3px rgba(0, 255, 65, 0.4);";
		} else {
			$border_css = "border:1px solid " . $bordercol . ";";
		}

		$mapfile = "";
	}

	$img_file = $userlnk . $user . '/tmp' . $c . '.png';
	$hash = @filemtime($img_file);

	// Fetch image dimensions for current channel's own thumbnail image
	$hh = null;
	$sz = @filesize($img_file);
	if ($sz !== false && $sz >= 500) {
		$hh = @getimagesize($img_file);
	}

	// Fallback to scan dataset image size if current channel thumbnail is not generated yet
	if (!$hh || empty($hh[0]) || empty($hh[1])) {
		if ($bi != $obi || !isset($fallback_hh)) {
			$fallback_hh = null;
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
						$fallback_hh = $chk_hh;
						break;
					}
				}
				$chk_c++;
			}
		}
		$hh = $fallback_hh;
	}

	if ($sz !== false && $sz < 500) {
		$w_attr = 'width="8" height="8"';
		$ar_css = 'width:8px; height:8px; aspect-ratio: 1 / 1; ';
		$cached_w = 8; $cached_h = 8;
	} else if ($hh && !empty($hh[0]) && !empty($hh[1])) {
		$scale = min(100 / $hh[0], 100 / $hh[1], 1.0);
		$css_w = max(1, round($hh[0] * $scale));
		$css_h = max(1, round($hh[1] * $scale));
		$w_attr = 'width="' . $hh[0] . '" height="' . $hh[1] . '"';
		$ar_css = 'width:' . $css_w . 'px; height:' . $css_h . 'px; aspect-ratio: ' . $hh[0] . ' / ' . $hh[1] . '; ';
		$cached_w = $css_w; $cached_h = $css_h;
	} else {
		$w_attr = '';
		$ar_css = '';
		$cached_w = 100; $cached_h = 100;
	}

	$real_src = 'serve_image.php?file=' . urlencode($img_file) . '&v=' . $hash;

	// Eager load active file channels & channels within +/- 45 index window; load off-screen thumbnails via IntersectionObserver
	$is_near_active = (abs($c - $index) <= 45 || in_array($c, $chline));
	if ($is_near_active) {
		$src_attr = 'src="' . $real_src . '"';
	} else {
		$placeholder = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='" . $cached_w . "' height='" . $cached_h . "'%3E%3C/svg%3E";
		$src_attr = 'src="' . $placeholder . '" data-src="' . $real_src . '"';
	}

	$chan_name = isset($acqchans[$c]) ? trim($acqchans[$c]) : '';
	$base_chan_name = get_base_channel_name($chan_name);
	$tooltip = htmlspecialchars($bi . ($chan_name !== '' ? ' [' . $chan_name . ']' : ''));
	echo '<a class="thumb-link" data-channel="'.htmlspecialchars($base_chan_name).'" href="quickview.php?command=goto '.($c+1).'&over=over" title="'.$tooltip.'"><img id="img'.$c.'" '.$src_attr.' '.$w_attr.' style="'.$ar_css.'max-width:100px;max-height:100px;box-sizing:border-box;'.$border_css.'background-color:#111;" title="'.$tooltip.'" onerror="handleImgError(this)"></a>';
	$c++;
	$obi = $bi;
}

// Compute unique acquisition base channels for preselection panel
$unique_acqchans = array();
if (!empty($acqchans)) {
	foreach ($acqchans as $acname) {
		$base = get_base_channel_name($acname);
		if ($base !== '' && !in_array($base, $unique_acqchans)) {
			$unique_acqchans[] = $base;
		}
	}
}

?>

	</TR>
	</TABLE>
	</TD>

	<!-- Right Side Channel Preselection Window (Glued to Right Edge as in quickview.php) -->
	<TD style="vertical-align:top; width:200px;">
		<div id="channel_panel" style="position:sticky; top:0; right:0; border-left:1px solid #444; border-bottom:1px solid #444; background:#181818; padding:6px; box-sizing:border-box; width:200px; overflow-x:hidden;">
			<div style="font-weight:bold; margin-bottom:6px; border-bottom:1px solid #444; padding-bottom:4px; color:#bff;">Channels</div>
			<div style="margin-bottom:6px;">
				<input type="button" value="All" onclick="toggleAllChannels(true)" style="margin-right:4px;">
				<input type="button" value="None" onclick="toggleAllChannels(false)">
			</div>
			<div id="channel_checkboxes" style="display:flex; flex-direction:column; gap:4px; max-height:calc(100vh - 60px); overflow-y:auto; overflow-x:hidden;">
<?php
foreach ($unique_acqchans as $uchan) {
	$escaped = htmlspecialchars($uchan);
	echo '<label style="cursor:pointer; display:flex; align-items:center; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="' . $escaped . '">';
	echo '<input type="checkbox" class="chan-cb" value="' . $escaped . '" checked onchange="onChannelChange()" style="vertical-align:middle; margin-right:6px; flex-shrink:0;">';
	echo '<span style="overflow:hidden; text-overflow:ellipsis;">' . $escaped . '</span>';
	echo '</label>';
}
?>
			</div>
		</div>
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

function getCheckedChannels() {
  var checked = [];
  var cbs = document.querySelectorAll('.chan-cb');
  cbs.forEach(function(cb) {
    if (cb.checked) checked.push(cb.value);
  });
  return checked;
}

function applyChannelFilters() {
  var checked = getCheckedChannels();
  try {
    localStorage.setItem('wspa_overview_channels', JSON.stringify(checked));
  } catch(e) {}

  var links = document.querySelectorAll('.thumb-link');
  links.forEach(function(link) {
    var ch = link.getAttribute('data-channel');
    if (!ch || checked.indexOf(ch) !== -1) {
      link.style.display = 'inline-block';
    } else {
      link.style.display = 'none';
    }
  });

  if (typeof initLazyLoading === 'function') {
    initLazyLoading();
  }
}

function onChannelChange() {
  applyChannelFilters();
}

function toggleAllChannels(enable) {
  var cbs = document.querySelectorAll('.chan-cb');
  cbs.forEach(function(cb) {
    cb.checked = enable;
  });
  applyChannelFilters();
}

function loadChannelPreferences() {
  try {
    var saved = localStorage.getItem('wspa_overview_channels');
    if (saved) {
      var checkedArr = JSON.parse(saved);
      if (Array.isArray(checkedArr)) {
        var cbs = document.querySelectorAll('.chan-cb');
        cbs.forEach(function(cb) {
          cb.checked = (checkedArr.indexOf(cb.value) !== -1);
        });
      }
    }
  } catch(e) {}
  applyChannelFilters();
}

function scrollToActiveImage() {
  var targetImage = document.getElementById('<?echo 'img'.$index;?>');
  if (targetImage) {
    targetImage.scrollIntoView({ behavior: 'auto', block: 'center', inline: 'center' });
  }
}

// 1. Instantly scroll active target image into view
scrollToActiveImage();
document.addEventListener('DOMContentLoaded', function() {
  scrollToActiveImage();
  loadChannelPreferences();
});

// 2. Populate off-screen images reliably with IntersectionObserver
function initLazyLoading() {
  var lazyImages = document.querySelectorAll('img[data-src]');
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function(entries, obs) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          var img = entry.target;
          var dataSrc = img.getAttribute('data-src');
          if (dataSrc) {
            img.src = dataSrc;
            img.removeAttribute('data-src');
          }
          obs.unobserve(img);
        }
      });
    }, { rootMargin: '300px 0px' });

    lazyImages.forEach(function(img) {
      observer.observe(img);
    });
  } else {
    lazyImages.forEach(function(img) {
      var dataSrc = img.getAttribute('data-src');
      if (dataSrc) {
        img.src = dataSrc;
        img.removeAttribute('data-src');
      }
    });
  }
}

if (window.requestAnimationFrame) {
  requestAnimationFrame(initLazyLoading);
} else {
  setTimeout(initLazyLoading, 0);
}
</script>

</BODY>

<?php exit; ?>
