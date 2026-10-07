<html>
<head>
<link rel="icon" href="favicon.ico" type="image/x-icon">
<meta charset="UTF-8">
<meta http-equiv="Content-type" content="text/html;charset=UTF-8">
<meta http-equiv="refresh" content="9999">
<STYLE type="text/css">
*, *:focus, *:focus-visible, *:focus-within {
	border-radius: 0px !important;
	outline-radius: 0px !important;
	-webkit-outline-radius: 0px !important;
	-moz-outline-radius: 0px !important;
	outline: none !important;
	box-shadow: none !important;
}

body, div, dl, dt, dd, ul, ol, li, h1, h2, h3, h4, h5, h6, pre, code, form, fieldset, legend, input, button, textarea, select, p, blockquote, th, tr, td, a, img {
	margin: 0px;
	padding: 0px;
	border: 0px;
	border-spacing: 0px;
	border-collapse: collapse;
}

body {
	font-family:monospace;font-size:11pt;background-color:#111;color:#eee;margin:0px;height:100vh;overflow:hidden;
}

body a {color:#bff;text-decoration:none;}
body a:hover {color:#eff;text-decoration:underline;}
body form {border:0px;padding:0px;margin:0px;display:inline;}

input {padding:2px;border:1px solid #444;font-family:Arial,sans-serif;font-size:11pt;box-sizing:border-box;}
input[type="checkbox"] {background-color:#444;color:#eee;}
input[type=text]{padding:2px;border:1px solid #444;font-family:Arial,sans-serif;font-size:11pt;}
input[type=file]{padding:0px;border:0px;}
input[type=image]{padding:0px;border:0px;}

button, input[type=submit], input[type=button], select {
	font-family: Arial, sans-serif;
	font-size: 11pt;
	box-sizing: border-box;
}

input[type=submit], input[type=button]{padding:2px;border:1px solid #444;cursor:pointer;}
input[type=submit]:hover, input[type=button]:hover{background-color:#ff0 !important;color:#000 !important;}

select{padding:0px;border:1px solid #444;font-family:Arial,sans-serif;font-size:11pt;}
textarea{padding:2px;border:1px solid #444;color:#000;font-family:monospace;font-size:11pt;box-sizing:border-box;}

.decor img{border:1px solid #444}
.decor:hover img{border:1px solid;}


.twocolumn TABLE{table-layout:auto; border:0px solid;}
.twocolumn TD:nth-of-type(1){width:38%; vertical-align:top;overflow-y:hidden;}
.twocolumn TD:nth-of-type(3){width:62%; vertical-align:top;overflow-y:hidden;}

.dlist {overflow-y:auto;height:calc(100vh - 65px);}
.dlist table{table-layout:auto;}

.dlist th{background:#111;text-align:left;font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:ellipsis;position:sticky;top:0;}
.dlist td:nth-of-type(1){max-width:22em; font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:ellipsis;}
.dlist tr.dlist-row { cursor: pointer; }
.dlist td:nth-of-type(2){max-width:10em; font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:ellipsis;padding-left:4px;}
.dlist td:nth-of-type(3){max-width:8em; font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:ellipsis;}

.dlist a:hover {font-size:11pt;text-decoration:none;}
.dlist input[type=submit]{padding:2px;border:1px solid;}
.dlist tr.mc-selected {background-color:#0055aa !important;color:#ffffff !important;cursor:pointer;}
.dlist tr.mc-selected td {background-color:#0055aa !important;color:#ffffff !important;}
.dlist tr.mc-selected a {color:#ffffff !important;background-color:transparent !important;}

.flist {overflow-y:auto;height:calc(100vh - 65px);}
.flist table{table-layout:auto;}
.flist th{background:#111;text-align:left;font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:ellipsis;position:sticky;top:0;}
.flist td{font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:ellipsis;}
.flist a:hover {font-size:11pt;text-decoration:none;background-color:#888;}
.flist input[type=submit]{padding:2px;border:1px solid;}
.flist input[type=text]{padding:2px;border:1px solid;}


.menu {font-family:Arial,sans-serif;font-size:11pt;position:fixed;top:0;left:0;width:100%;height:20px;line-height:20px;z-index:999;}
.menu a {color:#aaa; text-decoration:none;font-size:11pt;font-weight:bold;line-height:20px;display:inline-block;vertical-align:top;}
.menu a:hover {color:#fff; text-decoration:none;}
.menu table {width:100%; border: 0px; padding:0px; color:#777;border-spacing:0px;overflow:hidden;white-space:nowrap;height:20px;}
.menu td {padding:0px; border:0px; background-color:#000; border-spacing:0px;height:20px;line-height:20px;vertical-align:top;}
.menu tr {padding:0px; border:0px; background-color:#000; border-spacing:0px;height:20px;}

.loc {background-color:#222;padding:0px;margin:0px;overflow:hidden;white-space:nowrap;border:0px;height:20px;line-height:20px;}
.loc table{padding:0px;margin:0px;border:0px;border-collapse:collapse;width:100%;height:20px;}
.loc td{font-size:11pt;font-weight:bold;padding:0px;margin:0px;border:0px;overflow:hidden;white-space:nowrap;vertical-align:top;height:20px;line-height:20px;}
.loc a{color:#8ff;vertical-align:top;line-height:20px;font-size:11pt;}
.loc a:hover {color:#fff;}
.loc img{vertical-align:middle;}
.loc input[type=text], .loc select {
    font-size: 11pt;
    font-weight: bold;
    height: 20px;
    line-height: 20px;
    padding: 0 5px;
    margin: 0;
    border: none;
    outline: none;
    border-radius: 0;
    box-shadow: none;
    vertical-align: top;
    box-sizing: border-box;
}


#coordinates,#a1,#a2,#a3,#x1, #x2, #x3,#y1, #y2, #y3,#r12,#r23,#r31 {background:#444;border:none;padding:0px;width:3.2em;text-align:right;color:#fff;font-size:9pt}
#coordinates{background:#222}

#image {cursor:crosshair;}

#buttoninh3 {border:0px;padding:0px}

#debug {resize:vertical;padding:0px;white-space:nowrap;overflow-x:hidden;overflow-y:scroll;width:100%;background-color:#ccc;font-size:8pt;height:100%;width:100%}
#qvud {resize:vertical;padding:0px;overflow-x:hidden;overflow-y:scroll;width:40em;background-color:#f93;}
#filter {resize:vertical;width:100%;background-color:#6e6;overflow-x:hidden;}
#proc {resize:vertical;background-color:#6cf;overflow-x:hidden;width:100%;}
#command {background-color:#000;color:#0f0;font-family:courier;}

#proctd {vertical-align:top;}
#proca {color:#fff;font-size:80%}
#proctable {border-spacing:0px;}

#filts {width:8em;}
#procs {width:8em;}

#filldebug {overflow:scroll;overflow-x:hidden;overflow-y:auto;width:100%;background-color:#ccc;font-size:80%;height:100%}

.fill {padding-top:20px;box-sizing:border-box;}
.fill TABLE {width:100%;padding:0px;border:0px;border-spacing:0px;}
.fill FORM {padding:0px;border:none;margin:0;}
.fill TEXTAREA {padding:2px;border:none;margin:0;}
.fill TR {padding:0px;border:0px;}
.fill TD {padding:0px;border:0px;}

.scrollfill {height:95vh;overflow-y:auto;}

.badge-matrix { font-size:9px; background:#111; color:#00ff41; border:1px solid #00ff41; padding:0 3px; border-radius:0px; font-weight:bold; margin-left:2px; vertical-align:middle; display:inline-block; cursor:help; height:16px; line-height:14px; box-sizing:border-box; }
.badge-projects { font-size:9px; background:#111; color:#ff9800; border:1px solid #ff9800; padding:0 3px; border-radius:0px; font-weight:bold; margin-left:2px; vertical-align:middle; display:inline-block; cursor:help; height:16px; line-height:14px; box-sizing:border-box; }
.badge-shadow { font-size:9px; background:#111; color:#ffd54f; border:1px solid #ffd54f; padding:0 3px; border-radius:0px; font-weight:bold; margin-left:2px; vertical-align:middle; display:inline-block; cursor:help; height:16px; line-height:14px; box-sizing:border-box; }
.badge-project { font-size:9px; background:#111; padding:0 3px; border-radius:0px; font-weight:bold; margin-left:2px; vertical-align:middle; display:inline-block; cursor:help; height:16px; line-height:14px; box-sizing:border-box; }
.badge-default { font-size:9px; background:#111; color:#888; border:1px solid #888; padding:0 3px; border-radius:0px; font-weight:bold; margin-left:2px; vertical-align:middle; display:inline-block; cursor:help; height:16px; line-height:14px; box-sizing:border-box; }
.badge-rw { font-size:9px; background:#111; color:#eee; border:1px solid #eee; padding:0 3px; border-radius:0px; font-weight:bold; margin-left:2px; vertical-align:middle; display:inline-block; cursor:help; height:16px; line-height:14px; box-sizing:border-box; }
.badge-ro { font-size:9px; background:#111; color:#888; border:1px solid #888; padding:0 3px; border-radius:0px; font-weight:bold; margin-left:2px; vertical-align:middle; display:inline-block; cursor:help; height:16px; line-height:14px; box-sizing:border-box; }
.file-shadow { color:#ffd54f !important; font-weight:bold; }
.file-shadow:hover { color:#ffe082 !important; }

</STYLE>
</head>
<body>
<div class=menu>
<TABLE>
<TR>
<TD align=left>
<a href="" target=_blank title="Open a new tab">&nbsp;&nbsp;+Tab&nbsp;&nbsp;</a>
<?php
$curphp=basename($_SERVER["SCRIPT_FILENAME"]);
if (!IsSet($mode)){$mode='';}
echo '<a title="Upload, organize and open data files"';
if ($curphp=='browser.php'){echo ' style="color:#ff0"';}
echo ' href="browser.php?path='.urlencode($path).'&mode='.$mode.'">&nbsp;&nbsp;Browser&nbsp;&nbsp;</a>';
//echo '<a href="view.php?path='.urlencode($path).'">&nbsp;&nbsp;Images&nbsp;&nbsp;</a>';
echo '<a title="Currently loaded data"';
if ($curphp=='quickview.php'){echo ' style="color:#ff0"';}
//echo ' href="quickview.php?path='.urlencode($path).'">&nbsp;&nbsp;Analysis&nbsp;&nbsp;</a>';
echo ' href="quickview.php">&nbsp;&nbsp;Analysis&nbsp;&nbsp;</a>';
echo '<a title="Spectroscopy associated to current image"';
if ($curphp=='sts.php'){echo ' style="color:#ff0"';}
//echo ' href="quickview.php?path='.urlencode($path).'">&nbsp;&nbsp;Analysis&nbsp;&nbsp;</a>';
echo ' href="sts.php">&nbsp;&nbsp;Sts&nbsp;&nbsp;</a>';


echo '<a title="Currently loaded data overview"';
if ($curphp=='quickview_over.php' || $curphp=='quickview_over2.php'){echo ' style="color:#ff0"';}
echo ' href="quickview_over.php">&nbsp;&nbsp;Overview&nbsp;&nbsp;</a>';

echo '<a title="3D Spatial arrangement of dataset scans"';
if ($curphp=='globalview.php'){echo ' style="color:#ff0"';}
echo ' href="globalview.php">&nbsp;&nbsp;Global View&nbsp;&nbsp;</a>';


echo '<a title="If something gets wrong.."';
if ($curphp=='err.php'){echo ' style="color:#ff0"';}
echo ' href=err.php>&nbsp;&nbsp;Debug&nbsp;&nbsp;</a>';

?>
<TD width="10em" align=right><a href=cred.php>&nbsp;X&nbsp;</a>
</TR>
</TABLE>
</div>
