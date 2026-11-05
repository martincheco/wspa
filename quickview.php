<?php
if (!in_array('ob_gzhandler', ob_list_handlers()) && extension_loaded('zlib')) {
	@ob_start('ob_gzhandler');
}

require('globals.php');
require('auth.php');

if (IsSet($_POST['help'])) {if (($_POST['help']=='help')){$help=$_POST['help'];}else{$help="";}}else{if ($help_default===true){$help="help";} else {$help="";}}
if (IsSet($_POST['sts'])) {if (($_POST['sts']=='sts')){$sts=$_POST['sts'];}else{$sts="";}}else{if ($sts_default===true){$sts="sts";} else {$sts="";}}
if (IsSet($_POST['helpon'])) {if (($_POST['helpon']=='Help')){$help="";}}
if (IsSet($_POST['helpoff'])) {if (($_POST['helpoff']=='Help')){$help="help";}}
if (IsSet($_POST['stson'])) {if (($_POST['stson']=='Sts')){$sts="";}}
if (IsSet($_POST['stsoff'])) {if (($_POST['stsoff']=='Sts')){$sts="sts";}}
if (IsSet($_POST['index'])) {$oldindex=$_POST['index'];}


$xcommand="none";
$filtfile="";


if (IsSet($_POST['command'])){
	$xcommand=$_POST['command'];
//echo $xcommand."*".$command;
}else if (IsSet($_GET['command'])){$xcommand=$_GET['command'];}

//sanitize the output
	$command=stripslashes($xcommand);
	if(preg_match('/[^A-Za-z0-9+\-\s.,$]/', $command)){
		$command="none";
	}

if (Isset($_POST['prev'])) {if (html_entity_decode($_POST['prev'])!=''){$command="prev";}}
if ((IsSet($_POST['prevs'])) || (IsSet($_POST['nexts']))){if (IsSet($_POST['nch'])) {$nch=$_POST['nch'];}}
if (IsSet($_POST['prevs'])) {if (html_entity_decode($_POST['prevs'])!=''){$command="prevs";}}
if (IsSet($_POST['nexts'])) {if (html_entity_decode($_POST['nexts'])!=''){$command="nexts";}}
if (IsSet($_POST['filt'])) {if (($_POST['filt'])=='APPLY FILTER'){$command="filter";}}
if (IsSet($_POST['next'])) {if (html_entity_decode($_POST['next'])!=''){$command="next";}}
if (IsSet($_POST['mark'])) {if (($_POST['mark']=='Mark')){$command="mark";}}
if (IsSet($_POST['dump'])) {if (($_POST['dump']=='Dump')){$command="dump";}}
if (IsSet($_POST['stsmap'])) {if (($_POST['stsmap']=='STS map')){$command="sts";}}
if (IsSet($_POST['pngsave'])) {if (($_POST['pngsave']=='PNG')){$command="pngsave";}}
if (IsSet($_POST['wsxmsave'])) {if (($_POST['wsxmsave']=='WSXM')){$command="wsxmsave";}}

if ($rights!="w" && $rights!="o"){
//eliminate some commands if we have only read properties
	if ($command != "none" && $command != "exit" && $command != "prev" && $command!="next" && $command != "prevs" && $command!="nexts" && !(strpos($command,"goto")===0) && !(strpos($command,"move")===0)){
		//echo $user." access in ".$path." is restricted to read! (".$rights.")";
		$command="command ".$command." eliminated!!";
	}
$acsctrl="<font color=#f00><b>READONLY</b></font>";
} else {$acsctrl="<font color=#0f0><b>READ/WRITE</b></font>";}

// Filter save if posted
if (isset($_POST['filter'])) {
	$filter = $_POST['filter'];
	if (file_exists($userdir . $user . '/tmp.flt')) { @unlink($userdir . $user . '/tmp.flt'); }
	if ($filter !== '') { @file_put_contents($userdir . $user . '/tmp.flt', $filter); }
	if ($filter === 'empty') { @file_put_contents($userdir . $user . '/tmp.flt', ''); }
}

// Clear temporary image cache
@unlink($userdir . $user . '/tmp.png');
@unlink($userdir . $user . '/scl.png');
@unlink($userdir . $user . '/tmp.dat');

// Write command to GDL FIFO pipe natively without exec()
@file_put_contents($userdir . $user . '/comm', $command . "\n");

$tmpdat = $userdir . $user . "/tmp.dat";

$c = 0;

while ((!file_exists($tmpdat)) && ($c < (100 * $qtout))) { usleep(10000); $c++; }

if ($c > (100 * $qtout - 1)) {
	if (file_exists($userdir . $user . '/gdl.log')) {
		$debug = file($userdir . $user . '/gdl.log');
	} else {
		$debug[] = "Can't get GDL log :(";
	}
	header('Location: err.php');
	exit;
} else {
	$PrevSize = -1;
	while (($Size = filesize($tmpdat)) != $PrevSize) { $PrevSize = $Size; usleep(10000); }
}

$msg = file($tmpdat);

// Read image index from file
$parts = preg_split('/\s+/', $msg[1]);
$index = $parts[1] - 1;
// Read physical dimensions
$parts = preg_split('/\s+/', $msg[5]);
$xscale = $parts[1];
$runit = $parts[4];

$parts2 = preg_split('/\s\s/', $msg[3]);
$parts3 = preg_split('/-/', $parts2[1]);

$yscandir = trim($parts3[0]);
$xscandir = trim($parts3[1]);

$raw_file = trim(stripslashes($msg[0]));

if (!empty($raw_file) && ($command === "filter")) {
	$data_dir = dirname($raw_file);
	sync_process_preview_dir($data_dir, $userdir, $user);
	bump_workspace_epoch($userdir, $user);
}

// Dual-mode resolver for .flt files
$filtfile = get_meta_path_for_file($raw_file, 'flt', $user);
if (file_exists($filtfile)) {
	$filtorig = file_get_contents($filtfile);
} else {
	$filtorig = "";
}

if (file_exists($userdir . $user . '/gdl.log')) {
	$debug = file_get_contents($userdir . $user . '/gdl.log');
} else {
	$debug = "Can't get GDL log :(";
}

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

if ($mapfile !== "" && file_exists($mapfile)) {
    $map = file($mapfile);
    $c = 1;
    $mapf = array();
    $mapx = array();
    $mapy = array();
    $mapsy = array();
    foreach ($map as $mapln) {
        if ($c == 0) {
            $mapf[] = $mapln; $c = 1;
        } else {
            $mapc = preg_split('/\s+/', trim($mapln));
            $mapx[] = $mapc[0];
            $mapy[] = $mapc[1];
            $mapsy[] = $mapc[2];
            $c = 0;
        }
    }
} else {
    $mapfile = "";
}
require('over.php');
require('head.php');
if ($help=='help'){require('help.php');}else{require('nohelp.php');}
//is a part of image retrieval, depends on use of shared memory
if ($shm!=''){$userlnk=$userlink;}else{$userlnk=$userdir;}
$qv_zoom = isset($_COOKIE['wspa_qv_zoom']) ? max(1, min(16, intval($_COOKIE['wspa_qv_zoom']))) : 1;
//print_r($mapl);

?>

<script>

var last;
var clic=1;

//taken from stackoverflow

function insertTextAtCursor(el, text) {
    var val = el.value, endIndex, range;
    if (typeof el.selectionStart != "undefined" && typeof el.selectionEnd != "undefined") {
        endIndex = el.selectionEnd;
        el.value = val.slice(0, endIndex) + text + val.slice(endIndex);
        el.selectionStart = el.selectionEnd = endIndex + text.length;
    } else if (typeof document.selection != "undefined" && typeof document.selection.createRange != "undefined") {
        el.focus();
        range = document.selection.createRange();
        range.collapse(false);
        range.text = text;
        range.select();
    }
}

function pad(num, size) {
    var s = "000000000" + num;
    return s.substr(s.length-size);
}

function AddFilter(event) {
    var x1 = document.getElementById("x1").value;
    var x2 = document.getElementById("x2").value;
    var x3 = document.getElementById("x3").value;
    var y1 = document.getElementById("y1").value;
    var y2 = document.getElementById("y2").value;
    var y3 = document.getElementById("y3").value;
    var h  = document.getElementById("pointer").clientHeight;
    var a1 = document.getElementById("a1").value;

    var target = event.target || event.srcElement;
    var id = target.id

    var sup = document.getElementById(id);
    res = sup.options[sup.selectedIndex].value;

    res=res.replace("%1",x1+pad(y1,4));
    res=res.replace("%2",x2+pad(y2,4));
    res=res.replace("%3",x3+pad(y3,4));
    res=res.replace("%dx",0+x1-x2);
    res=res.replace("%dy",0+y1-y2);
    mmx = 2*Math.max(Math.abs(0+x1-x2),Math.abs(0+y1-y2));
    res=res.replace("%mx",0+mmx);
    res=res.replace("%x1",0+x1);
    res=res.replace("%y1",0+y1);
    res=res.replace("%x2",0+x2);
    res=res.replace("%y2",0+y2);
    res=res.replace("%x3",0+x3);
    res=res.replace("%y3",0+y3);
    res=res.replace("%a",a1);


    res=res.replace("#","\n");
    insertTextAtCursor(document.getElementById("filter"),res);
}

function drawLine(elid, Ax, Ay, Bx, By)
{
bla = "";
col1="#000";
col2="#fff";
col=col1;
var lineLength = Math.sqrt( (Ax-Bx)*(Ax-Bx)+(Ay-By)*(Ay-By) );
cnt="0";

for( var i=0; i<lineLength; i++ )
{
    bla += "<div style='position:absolute;left:"+ Math.round( Ax+(Bx-Ax)*i/lineLength  ) +"px;top:"+ Math.round( Ay+(By-Ay)*i/lineLength  ) +"px;width:1px;height:1px;background:"+col+"'></div>";
    if ((col == col2) && (cnt > 2)){col=col1;cnt=0;} 
    if ((col == col1) && (cnt > 2)){col=col2;cnt=0;}
    cnt++;
}
elid.innerHTML = bla;
}

function drawPoint(elid, Ax, Ay)
{
    bla = elid.innerHTML;
    bla += "<div style='position:absolute;left:"+ Math.round( Ax ) +"px;top:"+ Math.round( Ay ) +"px;width:1px;height:1px;background:#0ff'></div>";
    elid.innerHTML = bla;
}


var currentZoom = <?echo $qv_zoom;?>;

function redrawAllPoints() {
    var x1El = document.getElementById("x1");
    var y1El = document.getElementById("y1");
    var x2El = document.getElementById("x2");
    var y2El = document.getElementById("y2");
    var x3El = document.getElementById("x3");
    var y3El = document.getElementById("y3");
    if (!x1El || !y1El) return;
    var x1 = parseFloat(x1El.value);
    var y1 = parseFloat(y1El.value);
    var x2 = parseFloat(x2El.value);
    var y2 = parseFloat(y2El.value);
    var x3 = parseFloat(x3El.value);
    var y3 = parseFloat(y3El.value);
    var img = document.getElementById("pointer");
    if (!img) return;
    var ys = parseFloat(img.getAttribute("data-orig-h")) || img.naturalHeight || img.height || 400;

    var z = currentZoom;
    var halfZ = Math.floor(z / 2);

    var l1 = document.getElementById("line1");
    var l2 = document.getElementById("line2");
    var pts = document.getElementById("pnts");
    if (l1) l1.innerHTML = "";
    if (l2) l2.innerHTML = "";
    if (pts) pts.innerHTML = "";

    if (!isNaN(x1) && !isNaN(y1)) {
        var sx1 = x1 * z + halfZ;
        var sy1 = (ys - y1) * z + halfZ;
        drawPoint(pts, sx1, sy1);
        var c1 = document.getElementById("cross1");
        if (c1) {
            c1.style.left = (sx1 - 6) + "px";
            c1.style.top  = (sy1 - 6) + "px";
            c1.style.visibility = (clic >= 1) ? "visible" : "hidden";
        }
    }
    if (!isNaN(x2) && !isNaN(y2)) {
        var sx2 = x2 * z + halfZ;
        var sy2 = (ys - y2) * z + halfZ;
        var sx1 = x1 * z + halfZ;
        var sy1 = (ys - y1) * z + halfZ;
        drawLine(l1, sx1, sy1, sx2, sy2);
        var c2 = document.getElementById("cross2");
        if (c2) {
            c2.style.left = (sx2 - 6) + "px";
            c2.style.top  = (sy2 - 6) + "px";
            c2.style.visibility = (clic >= 2) ? "visible" : "hidden";
        }
    }
    if (!isNaN(x3) && !isNaN(y3)) {
        var sx3 = x3 * z + halfZ;
        var sy3 = (ys - y3) * z + halfZ;
        var sx2 = x2 * z + halfZ;
        var sy2 = (ys - y2) * z + halfZ;
        drawLine(l2, sx2, sy2, sx3, sy3);
        var c3 = document.getElementById("cross3");
        if (c3) {
            c3.style.left = (sx3 - 6) + "px";
            c3.style.top  = (sy3 - 6) + "px";
            c3.style.visibility = (clic >= 3) ? "visible" : "hidden";
        }
    }
}

function applyZoom(z) {
    z = parseInt(z, 10);
    if (isNaN(z) || z < 1) z = 1;
    if (z > 16) z = 16;
    currentZoom = z;

    var input = document.getElementById("zoom_input");
    if (input && input.value != z) input.value = z;

    var img = document.getElementById("pointer");
    if (img) {
        var natW = parseFloat(img.getAttribute("data-orig-w")) || img.naturalWidth || img.width || 400;
        var natH = parseFloat(img.getAttribute("data-orig-h")) || img.naturalHeight || img.height || 400;
        img.style.width = (natW * z) + "px";
        img.style.height = (natH * z) + "px";
        img.style.imageRendering = "pixelated";
        img.style.setProperty("-moz-crisp-edges", "pixelated");
        img.style.setProperty("image-rendering", "crisp-edges");
    }

    var markers = document.querySelectorAll(".sts_marker");
    markers.forEach(function(m) {
        var ptX = parseFloat(m.getAttribute("data-pt-x"));
        var ptY = parseFloat(m.getAttribute("data-pt-y"));
        var newLeft = Math.round(ptX * z - 4);
        var newTop = Math.round(ptY * z - 4);
        var imgEl = m.querySelector("img");
        if (imgEl) {
            imgEl.style.left = newLeft + "px";
            imgEl.style.top = newTop + "px";
        }
    });

    var arr = document.getElementById("scandir_arrow");
    if (arr && img) {
        var natH = parseFloat(img.getAttribute("data-orig-h")) || img.naturalHeight || 400;
        var arrY = parseFloat(arr.getAttribute("data-orig-y"));
        if (arrY > 0) {
            arr.style.top = Math.round(natH * z - 17) + "px";
        }
    }

    redrawAllPoints();

    try {
        localStorage.setItem("wspa_qv_zoom", z);
        document.cookie = "wspa_qv_zoom=" + z + "; path=/; max-age=31536000; SameSite=Lax";
    } catch(e) {}
}

function stepZoom(delta) {
    applyZoom(currentZoom + delta);
}

function onZoomChange(val) {
    applyZoom(val);
}

window.addEventListener("DOMContentLoaded", function() {
    var savedZoom = currentZoom;
    try {
        var sz = localStorage.getItem("wspa_qv_zoom");
        if (sz) {
            var parsed = parseInt(sz, 10);
            if (parsed && parsed >= 1 && parsed <= 16) {
                savedZoom = parsed;
            }
        }
    } catch(e) {}

    if (savedZoom !== currentZoom) {
        applyZoom(savedZoom);
    } else {
        redrawAllPoints();
    }
});

function point_it(event){
    var x1 = document.getElementById("x1");
    var x2 = document.getElementById("x2");
    var x3 = document.getElementById("x3");
    var y1 = document.getElementById("y1");
    var y2 = document.getElementById("y2");
    var y3 = document.getElementById("y3");
    var img = document.getElementById("pointer");
    var ys = parseFloat(img.getAttribute("data-orig-h")) || img.naturalHeight || img.height || 400;
    var xs = parseFloat(img.getAttribute("data-orig-w")) || img.naturalWidth || img.width || 400;
    var butt = event.which;
    var xscl=<?echo $xscale;?>;
    var runit="<?echo $runit;?>";
    var r12 = document.getElementById("r12");
    var r23 = document.getElementById("r23");
    var r31 = document.getElementById("r31");
    var a1 = document.getElementById("a1");
    var a2 = document.getElementById("a2");
    var a3 = document.getElementById("a3");
    var store = document.getElementById("store");

    var click_x = (event.offsetX !== undefined) ? event.offsetX : event.layerX;
    var click_y = (event.offsetY !== undefined) ? event.offsetY : event.layerY;

    var pos_x = Math.max(0, Math.min(xs - 1, Math.floor(click_x / currentZoom)));
    var pos_y = Math.max(0, Math.min(ys - 1, Math.floor(click_y / currentZoom)));

    x3.value=x2.value;
    y3.value=y2.value;
    x2.value=x1.value;
    y2.value=y1.value;
    
    x1.value = pos_x;
    y1.value = ys-pos_y;
    
    store.value=store.value+' '+x1.value+' '+y1.value+' '+butt+'\n';

    r12.value=(Math.pow(x2.value-x1.value,2)+Math.pow(y2.value-y1.value,2));
    r23.value=(Math.pow(x3.value-x2.value,2)+Math.pow(y3.value-y2.value,2));
    r31.value=(Math.pow(x1.value-x3.value,2)+Math.pow(y1.value-y3.value,2));

    a1.value=r23.value-r12.value-r31.value;
    a2.value=r31.value-r23.value-r12.value;
    a3.value=r12.value-r31.value-r23.value;
    r12.value=Math.sqrt(r12.value);
    r23.value=Math.sqrt(r23.value);
    r31.value=Math.sqrt(r31.value);
    a1.value=-a1.value/(r12.value*r31.value)/2;
    a1.value=Math.acos(a1.value)*180/Math.PI;
    a2.value=-a2.value/(r23.value*r12.value)/2;
    a2.value=Math.acos(a2.value)*180/Math.PI;
    a3.value=-a3.value/(r31.value*r23.value)/2;
    a3.value=Math.acos(a3.value)*180/Math.PI;
    
    r12.value=((r12.value)*xscl/xs).toFixed(2);
    r23.value=((r23.value)*xscl/xs).toFixed(2);
    r31.value=((r31.value)*xscl/xs).toFixed(2);

    a1.value=(a1.value-0).toFixed(2);
    a2.value=(a2.value-0).toFixed(2);
    a3.value=(a3.value-0).toFixed(2);

    redrawAllPoints();

    clic++;

    document.getElementById("cmd").focus();
}

function keypressaction(keycode,e) {
    switch(keycode)
    {
    case 37:
	document.getElementById("prev").style.background="#ff0";
	document.getElementById("command").value="prev";
	document.mainform.submit();

	break;
    case 39:
	document.getElementById("next").style.background="#ff0";
	document.getElementById("command").value="next";
	document.mainform.submit();

	break;
    case 38:
	document.getElementById("prevs").style.background="#ff0";
//	document.getElementById("command").value="prevs";
	document.getElementById("prevs").click();
//	document.mainform.submit();

	break;
    case 40:
	e.preventDefault();
	document.getElementById("nexts").style.background='#ffff00';
//	document.getElementById("command").value="nexts";
	document.getElementById("nexts").click();

//	document.mainform.submit();

	break;
    case 34:
	document.getElementById("prevs").style.background="#ff0";
	document.getElementById("prev").style.background="#ff0";
	document.getElementById("command").value="move \-10";
	document.mainform.submit();

	break;
    case 33:
	document.getElementById("nexts").style.background="#ff0";
	document.getElementById("next").style.background="#ff0";
	document.getElementById("command").value="move 10";
	document.mainform.submit();

    case 80:
	document.getElementById("pngsave").style.background="#ff0";
//	document.getElementById("command").value="prevs";
	document.getElementById("pngsave").click();

	break;

    case 83:
	document.getElementById("stsmap").style.background="#ff0";
//	document.getElementById("command").value="prevs";
	document.getElementById("stsmap").click();

	break;
    }
}


function keypressaction2(keycode,ctrl) {
    if(keycode == 13 && ctrl){
	document.getElementById("filter").style.background="#ff0";
	document.getElementById("command").value="filter";
	document.mainform.submit();
    }
}

//$("body").css("overflow", "hidden");

</script>

<div class="fill">
<TABLE>

<TR>
			
	<TD style="vertical-align:top;height:100%;width:100%;max-width:500px;">
		<TABLE>
		<FORM name="pointform" ACTION="quickview.php" METHOD=POST>
		<INPUT type=hidden name=index value="<?echo $index;?>">
		<INPUT type=hidden name=nch value="<?echo $nch;?>">
		<INPUT type=hidden name=help value="<?echo $help;?>">
		<INPUT type=hidden name=sts value="<?echo $sts;?>">

		<TR>
			<TD>
			<?
			$img_scan_file = $userlnk . $user . '/tmp' . $index . '.png';
			$scan_hh = file_exists($img_scan_file) ? @getimagesize($img_scan_file) : array(400, 400);
			$orig_scan_w = (!empty($scan_hh[0])) ? $scan_hh[0] : 400;
			$orig_scan_h = (!empty($scan_hh[1])) ? $scan_hh[1] : 400;
			$disp_w = $orig_scan_w * $qv_zoom;
			$disp_h = $orig_scan_h * $qv_zoom;
			$scan_v = (function_exists('get_dataset_token') ? get_dataset_token($user) : '0') . '-' . (@filemtime($img_scan_file) ?: '0');
			$pointer_src = $img_scan_file . '?v=' . $scan_v;
			?>
			<div style="position:relative;cursor:crosshair;">
			<img id="pointer" data-orig-w="<?echo $orig_scan_w;?>" data-orig-h="<?echo $orig_scan_h;?>" src="<?echo $pointer_src;?>" title="<?echo help_tooltip('pointer')?>" style="position:relative;overflow:hidden;white-space:nowrap;display:block;width:<?echo $disp_w;?>px;height:<?echo $disp_h;?>px;image-rendering:pixelated;image-rendering:-moz-crisp-edges;image-rendering:crisp-edges;" onmouseup="point_it(event)" oncontextmenu="return false;">
			<script>
			(function() {
				try {
					var sz = parseInt(localStorage.getItem("wspa_qv_zoom"), 10);
					if (sz && sz >= 1 && sz <= 16 && sz !== <?echo $qv_zoom;?>) {
						var img = document.getElementById("pointer");
						if (img) {
							var nw = <?echo $orig_scan_w;?>;
							var nh = <?echo $orig_scan_h;?>;
							img.style.width = (nw * sz) + "px";
							img.style.height = (nh * sz) + "px";
						}
						currentZoom = sz;
						document.cookie = "wspa_qv_zoom=" + sz + "; path=/; max-age=31536000; SameSite=Lax";
					}
				} catch(e) {}
			})();
			</script>
			<div id="line1" style="pointer-events:none;"></div>
			<div id="line2" style="pointer-events:none;"></div>
			<div id="line3" style="pointer-events:none;"></div>
			<div id="pnts" style="pointer-events:none;"></div>

			<img id="cross1" src='mark1.png' style="position:absolute;visibility:hidden;pointer-events:none;">
			<img id="cross2" src='mark2.png' style="position:absolute;visibility:hidden;pointer-events:none;">
			<img id="cross3" src='mark3.png' style="position:absolute;visibility:hidden;pointer-events:none;">
<?
		if ($sts=='sts'){
			if (!empty($mapf)){
				$rendered_pts = array();
				foreach($mapf as $key => $mapfl){
					if (!isset($mapx[$key]) || !isset($mapy[$key]) || !is_numeric($mapx[$key]) || !is_numeric($mapy[$key])) {
						continue;
					}
					$mx = floatval($mapx[$key]);
					$my = floatval($mapy[$key]);
					$msy = (isset($mapsy[$key]) && is_numeric($mapsy[$key])) ? floatval($mapsy[$key]) : 1.0;
					if (!is_finite($mx) || !is_finite($my) || !is_finite($msy) || $msy <= 0) {
						continue;
					}

					$denom = $msy;
					$sts_pt_x = ($mx * (float)$orig_scan_h / $denom);
					$sts_pt_y = ((float)$orig_scan_h - ($my * (float)$orig_scan_h / $denom));

					$pix_left = round($sts_pt_x * $qv_zoom - 4);
					$pix_top  = round($sts_pt_y * $qv_zoom - 4);
					$pos_key  = $pix_left . '_' . $pix_top;

					if (!isset($rendered_pts[$pos_key])) {
						$rendered_pts[$pos_key] = array(
							'pt_x' => $sts_pt_x,
							'pt_y' => $sts_pt_y,
							'left' => $pix_left,
							'top'  => $pix_top,
							'fn'   => basename($mapfl),
							'cnt'  => 1
						);
					} else {
						$rendered_pts[$pos_key]['cnt']++;
					}
				}

				$stsim = 'sts.png';
				foreach ($rendered_pts as $rpt) {
					$title = ($rpt['cnt'] > 1) ? ($rpt['fn'] . ' (+' . ($rpt['cnt'] - 1) . ' curves)') : $rpt['fn'];
					echo '<a target=_self class="sts_marker" data-pt-x="'.$rpt['pt_x'].'" data-pt-y="'.$rpt['pt_y'].'" href="sts.php?s=&graph='.urlencode($rpt['fn']).'" title="'.htmlspecialchars($title).'"><img src="'.$stsim.'" style="position:absolute;left: '.$rpt['left'].'px; top: '.$rpt['top'].'px;"></a>';
				}
			}

			if(strtolower($yscandir)=='up'){echo '<img id="scandir_arrow" data-orig-y="'.($orig_scan_h-17).'" src="up.png" style="position:absolute;left: 0px; top: '.($orig_scan_h*$qv_zoom-17).'px;pointer-events:none;">';}
			if(strtolower($yscandir)=='down'){echo '<img id="scandir_arrow" data-orig-y="0" src="down.png" style="position:absolute;left: 0px; top: 0px;pointer-events:none;">';}
		}
?>

			</div>
		</TR>
		</FORM>
		</TABLE>

	<TD style="vertical-align:top;width:30em;">
		<TABLE style="position:relative;z-index:1;">
<? //if ($over=='over'){ ?>


		<TR>
			<TD height=<?echo $mxh+2?>px colspan=2>
			<?require('over_imgs.php');?>
		</TR>
<? //}
?>

		<TR>

		<FORM ID="secform" NAME="secform" ACTION="quickview.php" METHOD=POST>
		<INPUT type=hidden name=nch value="<?echo $nch;?>">
		<INPUT type=hidden name=index value="<?echo $index;?>">
		<INPUT type=hidden name=help value="<?echo $help;?>">
		<INPUT type=hidden name=sts value="<?echo $sts;?>">
			<TD id="cmdline" colspan=2><INPUT tabindex=-1 type=submit title="<?echo help_plain('sbwd');?>" name="prevs" id="prevs" value="<<"><INPUT tabindex=-1 type=submit name="prev" title="<?echo help_plain('bwd');?>" id="prev" value=" < "><INPUT tabindex=-1 type=submit id="next" name="next" title="<?echo help_plain('fwd')?>" value=" > "><INPUT tabindex=-1 type=submit name="nexts" title="<?echo help_plain('sfwd')?>" value=">>" id="nexts">
			<INPUT tabindex=-1 type=submit id="pngsave" name="pngsave" value="PNG" title="<?echo help_tooltip('png');?>"><INPUT tabindex=-1 type=submit name="wsxmsave" title="<?echo help_tooltip('wsxm');?>" value="WSXM">
			<INPUT tabindex=-1 type=submit id="stsmap" name="stsmap" value="STS map" title="<?echo help_tooltip('sts');?>">
			<? 
			echo $acsctrl;
			if($sts=="sts"){
			    echo ' <INPUT style="background:#ffa" type=submit name="stson" value="Sts" title="STS enabled">';
			}else{
			    echo ' <INPUT style="background:#aaa" type=submit name="stsoff" value="Sts" title="Enables STS">';
			}
			echo ' <span style="font-family:Arial,sans-serif;font-size:11pt;margin-left:4px;margin-right:2px;vertical-align:middle;">Zoom</span>';
			echo '<input type="button" id="zoom_down" value="<" onclick="stepZoom(-1); return false;" title="Zoom out" style="padding:2px;border:1px solid #444;cursor:pointer;font-family:Arial,sans-serif;font-size:11pt;height:21.6px;vertical-align:middle;box-sizing:border-box;">';
			echo '<input type="text" id="zoom_input" name="zoom" value="'.$qv_zoom.'" style="font-family:monospace;font-size:11pt;width:1.2em;text-align:center;height:21.6px;padding:2px 1px;border:1px solid #444;vertical-align:middle;box-sizing:border-box;background:#000;color:#eee;" onchange="onZoomChange(this.value);" onkeydown="if(event.keyCode===13){this.blur();return false;}">';
			echo '<input type="button" id="zoom_up" value=">" onclick="stepZoom(1); return false;" title="Zoom in" style="padding:2px;border:1px solid #444;cursor:pointer;font-family:Arial,sans-serif;font-size:11pt;height:21.6px;vertical-align:middle;box-sizing:border-box;">';
			if($help=='help'){
			    echo ' <INPUT style="background:#ffa" type=submit name="helpon" value="Help" title="Tooltips now enabled">';
			}else{
			    echo ' <INPUT style="background:#aaa" type=submit name="helpoff" value="Help" title="Enables tooltips">';
			}

			?>

		</FORM>
		</TR>


		<FORM ID="mainform" NAME="mainform" ACTION="quickview.php" METHOD=POST>
		<INPUT type=hidden name=nch value="<?echo $nch;?>">
		<INPUT type=hidden name=index value="<?echo $index;?>">
		<INPUT type=hidden name=help value="<?echo $help;?>">
		<INPUT type=hidden name=sts value="<?echo $sts;?>">
		<TR>
			<TD  colspan=2><TEXTAREA readonly id="qvud" title="<?echo help_plain('info');?>" tabindex=-1 cols=45 rows=10><? foreach($msg as $msgentry){echo $msgentry;} ?></TEXTAREA>
		</TR>
		<TR>
			<TD colspan=2 id="cmdline" ><INPUT tabindex=-1 id="command" title="<?echo help_plain('command');?>" TYPE=TEXT placeholder="Command" name="command" value="<?echo $command;?>" style="width:100%" onFocus="last='command'">
			<INPUT type=submit id="cmd" style="text-indent:-999px;background-color:#000;color:#0f0;border:collapse;font-family:courier;font-size:0px;line-height:0;" name="cmd" value="" onkeydown="keypressaction(event.keyCode,event);" tabindex="-1" title="<?echo help_plain('cmd')?>">
		</TR>
		<TR>
			<TD colspan=2>
			<TEXTAREA tabindex=1  onkeydown="keypressaction2(event.keyCode,event.ctrlKey); "id="filter" alt="Filters" title="<?echo help_plain('filters')?>" NAME=filter placeholder="Add filters, now default is active" rows=<?echo min(Array(count(explode("\n",$filtorig))+5,10));?> cols=45 onFocus="last='filter'"><? if($filtorig != ""){echo $filtorig;} ?></TEXTAREA>
		</TR>
		<TR>
			<TD colspan=2>
			<SELECT name="filts1" id="filts1" onchange="AddFilter(event);this.options[0].selected=true;" title="<?echo help_plain('filter_sel')?>" style="background-color:#6f6;">
				<OPTION label="Bkground" value="" title="<?echo help_tooltip('filters')?>">Bkground</OPTION>
				<OPTION value="subtrplane#" title="<?echo help_tooltip('subtrplane')?>">&nbsp;Plane</OPTION>
				<OPTION value="lineslope#" title="<?echo help_tooltip('lineslope')?>">&nbsp;Line fit</OPTION>
				<OPTION value="rowsequal#" title="<?echo help_tooltip('rowsequal')?>">&nbsp;Eq. rows</OPTION>
				<OPTION value="bkg_twist#" title="<?echo help_tooltip('bkg_twist')?>">&nbsp;Rm. twist</OPTION>
			
			</SELECT><SELECT name="filts2" id="filts2" onchange="AddFilter(event);this.options[0].selected=true;" title="<?echo help_plain('filter_sel')?>" style="background-color:#6f6;">
				<OPTION label="Smth/Sharp" value="" title="<?echo help_tooltip('filters')?>">Smooth/Sharpen</OPTION>
				<OPTION value="ftgauss 0.5#" title="<?echo help_tooltip('ftgauss')?>">Gauss smth.</OPTION>
				<OPTION value="flatten 20 1.#" title="<?echo help_tooltip('flatten')?>">Flatten</OPTION>
			
			</SELECT><SELECT name="filts3" id="filts3" onchange="AddFilter(event);this.options[0].selected=true;" title="<?echo help_plain('filter_sel')?>" style="background-color:#6f6;">
				<OPTION label="Size/Area" value="" title="<?echo help_tooltip('filters')?>">Size/Area</OPTION>
				<OPTION value="zoom 2.#" title="<?echo help_tooltip('zoom')?>">Zoom</OPTION>
				<OPTION value="recrop %1 %2#" title="<?echo help_tooltip('recrop')?>">Crop(2)</OPTION>
				<OPTION value="crop %x2 %y2 %mx#" title="<?echo help_tooltip('crop')?>">Sq. crop(3)</OPTION>
				<OPTION value="rotate 1#" title="<?echo help_tooltip('rotate')?>">rotate x90</OPTION>
				<OPTION value="rotate %a#" title="<?echo help_tooltip('rot')?>">rotate &alpha;1</OPTION>
				<OPTION value="center %x1 %y1#" title="<?echo help_tooltip('center')?>">Center(2)</OPTION>
				<OPTION value="stuff 512 512#" title="<?echo help_tooltip('stuff')?>">Stuff</OPTION>
				<OPTION value="transpose#" title="<?echo help_tooltip('transpose')?>">Transpose</OPTION>
				<OPTION value="mirror#" title="<?echo help_tooltip('mirror')?>">Mirror</OPTION>
				<OPTION value="flip#" title="<?echo help_tooltip('flip')?>">Flip</OPTION>

			</SELECT><SELECT name="filts4" id="filts4" onchange="AddFilter(event);this.options[0].selected=true;" title="<?echo help_plain('filter_sel')?>" style="background-color:#6f6;">
				<OPTION label="Contrast" value="" title="<?echo help_tooltip('filters')?>">Contrast</OPTION>
				<OPTION value="histxpand#" title="<?echo help_tooltip('histxpand')?>">Hist. Exp.</OPTION>
				<OPTION value="invert#" title="<?echo help_tooltip('invert')?>">Invert</OPTION>
				<OPTION value="histequal#" title="<?echo help_tooltip('histequal')?>">Hist. Equal</OPTION>

			</SELECT><SELECT name="filts5" id="filts5" onchange="AddFilter(event);this.options[0].selected=true;" title="<?echo help_plain('filter_sel')?>" style="background-color:#6f6;">
				<OPTION label="Special" value="" title="<?echo help_tooltip('filters')?>">Special</OPTION>
				<OPTION value="drift %3 %2 %1 #" title="<?echo help_tooltip('drift')?>">Hex drift(3)</OPTION>
				<OPTION value="driftfcc100 %3 %2 %1 #" title="<?echo help_tooltip('driftfcc100')?>">fcc110(3)</OPTION>
				<OPTION value="driftfcc110 %3 %2 %1 #" title="<?echo help_tooltip('driftfcc110')?>">fcc110(3)</OPTION>
				<OPTION value="dedouble %dx %dy 0.25#" title="<?echo help_tooltip('dedouble')?>">Dedouble(2)</OPTION>
				<OPTION value="color 1 0 0#" title="<?echo help_tooltip('color')?>">Color tbl.</OPTION>
				<OPTION value="visualft#" title="<?echo help_tooltip('visualft')?>">FFT</OPTION>

			</SELECT><INPUT tabindex=-1 type=submit name="filt" value="APPLY FILTER" style="background-color:#cf0;" title="<?echo help_plain('filter_apply')?>">

		</TR>
		
		</FORM>

		<TR>
			<? /* 
			<TD colspan=2><TEXTAREA style="height:100%" readonly tabindex=-1 id="debug" NAME="debug" title="<?echo help_plain('debug');?>" placeholder="nothing" rows=8 cols=45><? echo $debug; ?></TEXTAREA>
			*/ ?>
		</TR>


		<TR id="coordinates">
		    <TD id="coordinates;width:100%">
			<TABLE id="coordinates" title="<?echo help_plain('meas');?>" style="text-align:right;width:100%">
			<TR>
			<TD>x<sub>1</sub><input type="text" readonly id="x1" tabindex=-1 size=3 value=-></TD>
			<TD>x<sub>2</sub><input type="text" readonly id="x2" tabindex=-1 size=3 value=-></TD>
			<TD>x<sub>3</sub><input type="text" readonly id="x3" tabindex=-1 size=3 value=-></TD>
			</TR><TR>
			<TD>y<sub>1</sub><input type="text" readonly id="y1" tabindex=-1 size=3 value=-></TD>
			<TD>y<sub>2</sub><input type="text" readonly id="y2" tabindex=-1 size=3 value=-></TD>
			<TD>y<sub>3</sub><input type="text" readonly id="y3" tabindex=-1 size=3 value=-></TD>
			</tr><tr>
			<TD>r<sub>12</sub><input type="text" readonly id="r12" tabindex=-1 size=3><?//echo $runit;?></TD>
			<TD>r<sub>23</sub><input type="text" readonly id="r23" tabindex=-1 size=3><?//echo $runit;?></TD>
			<TD>r<sub>31</sub><input type="text" readonly id="r31" tabindex=-1 size=3><?//echo $runit;?></TD>
			</TR><TR>
			<td>&alpha;<sub>1</sub><input type="text" readonly id="a1" tabindex=-1 size=3></TD>
			<td>&alpha;<sub>2</sub><input type="text" readonly id="a2" tabindex=-1 size=3></TD>
			<td>&alpha;<sub>3</sub><input type="text" readonly id="a3" tabindex=-1 size=3></TD>
			</tr>
			</table>
		    </TD>
		    
		    <TD style="text-align:right;width:260px"><?
		    $hist_file = $userlnk . $user . '/hist' . $index . '.png';
		    $hist_v = (function_exists('get_dataset_token') ? get_dataset_token($user) : '0') . '-' . (@filemtime($hist_file) ?: '0');
		    $hist_src = file_exists($hist_file) ? ($hist_file . '?v=' . $hist_v) : 'unihist.png';
		    $scl_file = $userlnk . $user . '/scl' . $index . '.png';
		    $scl_v = (function_exists('get_dataset_token') ? get_dataset_token($user) : '0') . '-' . (@filemtime($scl_file) ?: '0');
		    $scl_src = file_exists($scl_file) ? ($scl_file . '?v=' . $scl_v) : 'uniscl.png';
		    ?><img src="<?echo $hist_src;?>" title="<?echo help_plain('histogram');?>"><BR>
		    <img title="<?echo help_plain('scl');?>" src="<?echo $scl_src;?>"></TD>
		</TR>
		<TR><TD colspan=2><TEXTAREA style="background-color:#333;color:#999;font-size:5px;width:100%" id="store" tabindex=-1></TEXTAREA></TD>

		</TR>

		</TABLE>

</div>
</TR>
</TABLE>
</div>

	<script>
		var filtarea = document.getElementById("filter");
		filtarea.focus();
		filtarea.value+=' ';
		filtarea.value=filtarea.value.substring(0,filtarea.value.length-1);

		//var textArea = document.getElementById("debug");
		//textArea.scrollTop = textArea.scrollHeight;
		document.getElementById("cmd").focus();
		window.scrollTo(0,0);
	</script>


</BODY>
<?exit;?>
