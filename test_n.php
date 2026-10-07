<?
require('globals.php');
require('auth.php');
require('loadnanonis_sts.php');
require('graphs.php');

$fnm=$_GET['file'];

$a=loadnanonis_sts($fnm);
$exp=$a['data'];
$chanlist=$a['chan'];
$nchan=0;

foreach($exp as $achan => $chandata){
//	print_r($chandata);
	graph_drw($exp[$chanlist[0]],$chandata,$chanlist[0],'',250,400,$nchan);
	echo $achan.'<BR><img src="';
	echo $nchan.'.png?'.date("U").'"><BR>';	
	$nchan++;
}


?>
