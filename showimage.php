<?
require('globals.php');
require('auth.php');
/* 
some basic checking
*/
if (!isset($_GET['image'])) exit;
$ImageFile = $userdir.$user.'/'.$_GET['image'];//.".png";
//echo $ImageFile;
//wait for the file to be written
while (!file_exists($ImageFile)){usleep(10000);}
$PrevSize=-1;
while (($Size = filesize($ImageFile))!=$PrevSize){$PrevSize=$Size;usleep(10000);};

header("HTTP/1.1 200 OK");
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header("Content-Type: image/png");
header("Content-Length: $Size");

readfile($ImageFile);

?>
