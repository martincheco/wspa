<?php

require('globals.php');
require('auth.php');
$tmpdat = $userdir . $user . "/tmp.dat";

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
	<TD style="vertical-align:top;width:30em;">
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

		if ($mapfile !== "" && file_exists($mapfile)) {
			$stsim = 'sts.png'; $mtagc = 'color:#0e0;';
			$bordercol = "#0e0";
		} else {
			$bordercol = "#567";
		}

		if (in_array($c, $chline)) {
			$border_css = "border:1px solid #fff; outline: 2px solid #0aa; outline-offset: -2px;";
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

	echo '<a href="quickview.php?command=goto '.($c+1).'&over=over" title="'.$bi.'"><img id="img'.$c.'" '.$src_attr.' '.$w_attr.' style="'.$ar_css.'max-width:100px;max-height:100px;box-sizing:border-box;'.$border_css.'background-color:#111;" title="'.$bi.'"></a>';
	$c++;
	$obi = $bi;
}

?>

	</TR>
	</TABLE>

</TR>
</TABLE>
</div>
</div>

<script>
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual';
}

function scrollToActiveImage() {
  var targetImage = document.getElementById('<?echo 'img'.$index;?>');
  if (targetImage) {
    targetImage.scrollIntoView({ behavior: 'auto', block: 'center', inline: 'center' });
  }
}

// 1. Instantly scroll active target image into view
scrollToActiveImage();
document.addEventListener('DOMContentLoaded', scrollToActiveImage);

// 2. Populate off-screen images with background decoding to prevent visual flicker
function initLazyLoading() {
  var lazyImages = document.querySelectorAll('img[data-src]');
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function(entries, obs) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          var img = entry.target;
          var dataSrc = img.getAttribute('data-src');
          img.removeAttribute('data-src');
          obs.unobserve(img);

          var tempImg = new Image();
          tempImg.src = dataSrc;
          if (tempImg.decode) {
            tempImg.decode().then(function() {
              img.src = dataSrc;
            }).catch(function() {
              img.src = dataSrc;
            });
          } else {
            img.src = dataSrc;
          }
        }
      });
    }, { rootMargin: '400px 0px' });

    lazyImages.forEach(function(img) {
      observer.observe(img);
    });
  } else {
    lazyImages.forEach(function(img) {
      img.src = img.getAttribute('data-src');
      img.removeAttribute('data-src');
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
