<?

require('globals.php');
//this will get session vars also
require('auth.php');


if (IsSet($_GET['log'])){
	$log="yes";
}else{
//exec('mkdir -p '.$userdir.$user);

//a trick to allow using the shared memory
if ($shm!=''){
@unlink($userlink.$user);
//echo 'ln -s '.$userdir.$user.'/ '.$userlink.$user;
exec('ln -s '.$userdir.$user.'/ '.$userlink.$user);
}

@unlink($userdir.$user.'/gdl.log');
@unlink($userdir.$user.'/tmp.dat');
@unlink($userdir.$user.'/main_launcher.log');
exec('./main_launcher '.$userdir.$user.' '.getcwd().' >> '.$userdir.$user.'/main_launcher.log 2>&1 &');
$log="";
}



if ($log != ""){
//echo $userdir.$user.'/gdl.log<BR>';
//    $fcs=file($userdir.$user.'/gdl.log');
$gdllogfile=$userdir.$user.'/gdl.log';
$fcs=@file_get_contents($gdllogfile,false,null,-10000);
if (empty($fcs)){$fcs=file_get_contents($gdllogfile);}


if (stripos($fcs,$readystring) !== false){
 header('Location: quickview.php?path='.urlencode($path));

	exit;
    }
    if (stripos($fcs,$failstring) !== false){
	header('Location: err.php?path='.urlencode($path));
	exit;
    }

//$fc=Implode($fcs,"&#10;");
//$fct=file_get_contents($userdir.$user.'/gdl.log');
$fc=$fcs;//preg_replace('/\n/',"&#13;",$fcs);
}

if (IsSet($fcs) && strpos($fcs,"processing image",-1000) !== false){
	$ps=strpos($fcs,'processing image',-1000);

	$snip=substr($fcs,$ps+16,40);
	$snip=preg_replace( '/\s+/', ' ', trim($snip) );
	$esnip=explode(" ",$snip);
//	print_r($esnip);
	$prog=($esnip[0]/$esnip[2]);
	$per=0.01;
	if ($prog < $per){$prog=0.01;}
}

	if (!IsSet($prog)){$prog=0.01;}



header( 'Refresh: '.($qout).'; url=launcher.php?path='.urlencode($path).'&log=reload', true, 303);

require('head.php');

echo "<FORM method=GET>";

?>
<div class=fill>
<TABLE><TR><TD>Loading and processing files - <b><span id="progress"><?echo number_format($prog*100,0)."%";?></span></b> done</TR>
<TR><TD><span style="float:left; width:<?echo($prog*100);?>%; background-color:#a00">&nbsp;</span>

	<TR><TD><TABLE><TR><TD>


<FORM method=POST>
<TEXTAREA readonly tabindex=-1 id="filldebug" NAME="log" rows=30>
<?if (isset($fcs)){echo $fcs;}?></TEXTAREA></FORM>
</TR></TABLE></TR></TABLE>
</div>
	<script>
		var textArea = document.getElementById("filldebug");
		textArea.scrollTop = textArea.scrollHeight;


//		var count=<?echo $qout*1000;?>;
//		var counter=setInterval(timer, 100); //1000 will  run it every 1 second

//		function timer()
//		{
//		  count=count-100;
//		  if (count <= 0)
//		  {
//		     clearInterval(counter);
//		     return;
//		  }

//		 document.getElementById("progress").innerHTML=count; 
}
	</script>

</body>
</html>
<?exit;?>
