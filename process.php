<?

require('globals.php');
require('auth.php');


if (IsSet($_GET['graph'])){
$graph=$_GET[graph];
	echo '<a href=flush.php?file='.$graph.'><img src=graph.php?file='.$graph.'></a><BR>';
}

if (IsSet($_GET['img'])){
	$img=$_GET['img'];
		echo '<img src="'.$userlink.$user.'/'.$img.'?v='.filemtime($userlnk.$userdir.'/'.$img).'">';
	
}

?>
