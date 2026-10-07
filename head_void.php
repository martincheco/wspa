<html>
<head>
<link rel="icon" type="image/png" href="icons/icon.png">
<meta http-equiv="Content-type" content="text/html;charset=UTF-8">
<meta http-equiv="refresh" content="900">
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

body {font-family:monospace;font-size:11pt;background-color:#111;color:#eee;margin:0px;}
body a {color:#bff;text-decoration:none;}
body a:hover {color:#eff;text-decoration:underline;}
body form {border:0px;padding:0px;margin:0px}

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

.dlist table{table-layout:auto;}

.dlist td:nth-of-type(1){max-width:30em; font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:string;}
.dlist td:nth-of-type(2){max-width:10em; font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:string;}

.dlist a:hover {font-size:11pt;text-decoration:none;background-color:#888;}
.dlist input[type=submit]{padding:2px;border:1px solid;}

.flist table{table-layout:auto;}
.flist td{font-size:11pt;vertical-align:middle;white-space: nowrap; overflow: hidden; text-overflow:ellipsis;}
.flist a:hover {font-size:11pt;text-decoration:none;background-color:#888;}
.flist input[type=submit]{padding:2px;border:1px solid;}
.flist input[type=text]{padding:2px;border:1px solid;}


.menu {font-family:Arial,sans-serif;font-size:11pt;}
.menu a {color:#aaa; text-decoration:none;font-size:11pt;font-weight:bold;}
.menu a:hover {color:#fff; text-decoration:none;}
.menu table {width:100%; border: 0px; padding:0px; color:#777;border-spacing:0px;overflow:hidden;white-space:nowrap;}
.menu td {padding:0px; border:0px; background-color:#000; border-spacing:0px;}
.menu tr {padding:0px; border:0px; background-color:#000; border-spacing:0px;}

.loc {background-color:#777;padding:0px;margin:0px;overflow:hidden;white-space:nowrap;border:0px;height:20px;line-height:20px;}
.loc table{padding:0px;margin:0px;border:0px;border-collapse:collapse;width:100%;height:20px;}
.loc td{font-size:11pt;font-weight:bold;padding:0px;margin:0px;border:0px;overflow:hidden;white-space:nowrap;vertical-align:top;height:20px;line-height:20px;}
.loc a{color:#8ff;vertical-align:top;line-height:20px;font-size:11pt;}
.loc a:hover {color:#fff;}
.loc img{vertical-align:middle;}
.loc input[type=text], .loc input[type=submit], .loc select {
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

#filldebug {white-space:nowrap; overflow:scroll;overflow-x:hidden;overflow-y:scroll;width:100%;background-color:#ccc;font-size:80%;height:100%}


.fill TABLE {width:100%;padding:0px;border:0px;border-spacing:0px;}
.fill FORM {padding:0px;border:none;margin:0;}
.fill TEXTAREA {padding:2px;border:none;margin:0;}
.fill TR {padding:0px;border:0px;}
.fill TD {padding:0px;border:0px;}

</STYLE>
</head>
<body>
