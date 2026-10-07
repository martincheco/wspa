<?

require('globals.php');
require('auth.php');

if (!isset($_GET['file'])){exit;}
$file = $userdir.$user.'/'.$_GET['file'];
if (!file_exists($file)){exit;}

//header("HTTP/1.1 200 OK");
//header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
//header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
//header("Cache-Control: no-store, no-cache, must-revalidate");
//header("Cache-Control: post-check=0, pre-check=0", false);
//header("Pragma: no-cache");
//header("Content-Length: $Size");
/* 
and finally the image itself
*/
echo "<pre>";
readfile($file);
echo "</pre>";

?> 