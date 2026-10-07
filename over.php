<?php
//read channel info and determine which keys are in the same set
if (file_exists($userdir.$user.'/chan.dat')){
	$chans=file($userdir.$user.'/chan.dat');
}
if (file_exists($userdir.$user.'/acqchan.dat')){
	$acqchans=file($userdir.$user.'/acqchan.dat');
}

//print_r($acqchans);

$acqchans=preg_replace("/[\\n\\r]+/", "",$acqchans);

//print_r($acqchans);

$cch=$chans[$index];
$info = pathinfo($cch);
$cch =  basename($cch,'.'.$info['extension']);
$info = pathinfo($cch);
$cch =  basename($cch,'.'.$info['extension']);
$chline=array();
foreach ($chans as $key => $chan){
//	$channew[$key]=true;
	$info = pathinfo($chan);
	$chans[$key] =  basename($chans[$key],'.'.$info['extension']);
	$info = pathinfo($chans[$key]);
	$chans[$key] =  basename($chans[$key],'.'.$info['extension']);

	if ($chans[$key] == $cch){$chline[]=$key;}
	if ($key == $index){$ckey=$key;}
}
//print_r($chans);


$nch=count($chline);
//print_r($nch);
$mxh=min(floor(520/count($chline)-2),100);
?>
