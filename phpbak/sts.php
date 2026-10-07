<?

require('globals.php');
require('auth.php');
require('head.php');
require('loadnanonis_sts.php');
require('graphs.php');

if (Isset($_POST['prev'])) {if (($_POST['prev'])==' < '){$command="prev";}}
if (Isset($_POST['next'])) {if (($_POST['next'])==' > '){$command="next";}}
if (IsSet($_POST['prevs'])) {if (($_POST['prevs'])=='<<'){$command="prevs";}}
if (IsSet($_POST['nexts'])) {if (($_POST['nexts'])=='>>'){$command="nexts";}}
if (IsSet($_POST['index'])) {$oldindex=$_POST["index"];}else{$oldindex=-1;}


if (!empty($command)){exec('nohup echo '.$command.' > '.$userdir.$user.'/comm 2>&1');
}
	$tmpdat=$userdir.$user."/tmp.dat";
	$c=0;

	while ((!file_exists($tmpdat)) && ($c<(100*$qtout))){usleep(10000);$c++;}

		if($c>(100*$qtout-1)){
		if (file_exists($userdir.$user.'/gdl.log')){
		$debug=file($userdir.$user.'/gdl.log');}else{$debug[]="Can't get GDL log :(";}
	//	session_write_close();
		header('Location: err.php');
		exit;
	}else{
		$PrevSize=-1;
		while (($Size = filesize($tmpdat))!=$PrevSize){$PrevSize=$Size;usleep(10000);}
	}




$imgwidth=400;

//read processed images and data
$msg=file($tmpdat);

//read image index from file
$parts = preg_split('/\s+/', $msg[1]);
$index=$parts[1]-1;
//read physical dimensions
$parts = preg_split('/\s+/', $msg[5]);
$xscale=$parts[1];
$runit=$parts[4];

$parts2=preg_split('/\s\s/',$msg[3]);
$parts3=preg_split('/-/',$parts2[1]);

$yscandir=trim($parts3[0]);
$xscandir=trim($parts3[1]);


$mapdir=pathinfo(trim(stripslashes($msg[0])), PATHINFO_DIRNAME);
//echo $mapdir;
$mapfile=$mapdir.'/'.pathinfo(pathinfo(trim(stripslashes($msg[0])), PATHINFO_FILENAME),PATHINFO_FILENAME).'.map';
if (file_exists($mapfile)){
    $map=file($mapfile);
    $c=1;
    foreach($map as $mapln){
	if($c==0){
	    $mapf[]=$mapln;$c=1;
	}else{
	    $mapc=preg_split('/\s+/',trim($mapln));
	    $mapx[]=$mapc[0];
	    $mapy[]=$mapc[1];
	    $mapsy[]=$mapc[2];
	    $c=0;
	}
    }
}else{$mapfile="";}
require('over.php');

//is a part of image retrieval, depends on use of shared memory
if ($shm!=''){$userlnk=$userlink;}else{$userlnk=$userdir;}

?>

<div class=fill>
<TABLE>
    <TR>
	<TD style="vertical-align:top;height:100%;width:100%;max-width:500px">
<?

if (IsSet($_GET['s'])){
	$shw=$_GET['s'];
	$show=Explode(",",$_GET['s']);
}else{$shw='';$show[0]='';}
	
//Image channel selection
if (IsSet($_GET['ch'])){
    $channels=$_GET['ch'];
    $selchan=Explode(",",$channels);
	//print_r(array_keys($chline));
    	if ($channels!=""){
		$chlinekeys=array_keys($chline);
		foreach($selchan as $slchn){
			if (in_array($slchn,$chlinekeys)){$schline[]=$chline[$slchn];}
		}
	}else{
		$schline[0]=$index;
		$channels=array_search($index,$chline);
	}

}else{
    	$schline[0]=$index;
	$channels=array_search($index,$chline);
}

if (IsSet($_GET['graph'])){$graph=$_GET['graph'];}else{ 
	if (IsSet($_POST['graphsel'])){$graph=$_POST['graphsel'];}
	if ($oldindex!=$index){if(!empty($mapf)){$graph=$mapf[0];}else{$graph='';}}
//	echo $oldindex."|".$index;
}
//if (IsSet($_GET['graph'])){$graph=$_GET['graph'];}else{$graph=$mapf[0];}





foreach ($schline as $i){
	echo '<div style="position:relative; display:inline-block">';
	    echo '<img src="'.$userlnk.$user.'/tmp'.$i.'.png?v='.filemtime($userlnk.$user.'/tmp'.$i.'.png').'">';

			$hh=getimagesize($userlnk.$user.'/tmp'.$i.'.png');
			if (!empty($mapf)) foreach($mapf as $key => $mapfl){
				$mapfl=trim($mapfl);
				$mtag=strpos(basename($mapfl),'.');
				$mtag=substr(basename($mapfl),$mtag-3,3);
				$nul=0;
				//decide which point is related to the actual image and which to the previous
				//$stl2='position:absolute;left: '.($mapx[$key]+4).'px; top: '.($hh[1]-$mapy[$key]).'px;';
				if (trim(basename(trim($mapfl)))==trim(basename($graph))){
					$stsim='sts_b.png';$mtagc='color:#00f;';$stl='z-index:999;';
				}else{
					$stsim='sts.png';$mtagc='color:#0f0;';$stl='';
				}
			    	echo '<a target=sts href="sts.php?s='.$shw.'&ch='.$channels.'&graph='.urlencode(basename($mapfl)).'" title="'.basename($mapfl).'"><img src="'.$stsim.'" style="position:absolute;'.$stl.' left: '.($mapx[$key]*$hh[1]/$mapsy[$key]-4).'px; top: '.($hh[1]-$mapy[$key]*$hh[1]/$mapsy[$key]-4).'px;"></a>';
			}

			if($yscandir=='up'){echo '<img src="up.png" style="position:absolute;left: 0px; top: '.($hh[1]-17).'px;">';}
			if($yscandir=='down'){echo '<div><img src="down.png" style="position:absolute;left: 0px; top: 0px;"></div>';}
	echo "</div>";
}

?>

</TD><TD style="vertical-align:top;width:450px;">

<FORM id=mainform action="sts.php" METHOD=POST>
<TABLE style="position:relative;z-index:1;">

<TR><TD><INPUT type=HIDDEN name="index" id=index value=<?echo $index;?>>
			<INPUT tabindex=-1 type=submit name="prevs" id="prevs" value="<<"><INPUT tabindex=-1 type=submit name="prev" id="prev" value=" < ">
			<INPUT tabindex=-1 type=submit name="next" value=" > " id="next"><INPUT tabindex=-1 type=submit id="nexts" name="nexts" value=">>">

			</TR>


<?
		echo '<TR><TD><h3>'.basename($msg[0]).' / '.$graph.'</h3></TR>';
	

		echo '<TR><TD><SELECT AUTOFOCUS name="graphsel" onchange="this.form.submit()">';
				foreach($mapf as $key => $mapfl){
					$mapfl=trim($mapfl);
					$mtag=strpos(basename($mapfl),'.');
					$mtag=substr(basename($mapfl),$mtag-3,3);
					if (basename($mapfl) === $graph){$slct=' SELECTED';}else{$slct='';}
					echo '<OPTION value='.basename($mapfl).$slct.'>'.basename($mapfl).'</OPTION>';
				}
		echo "</SELECT>";
	

			    	echo '<a target=txtview href="./'.dirname($msg[0]).'/'.basename($graph).'">&nbsp;-&gt;&nbsp;Open</a></TR>';
				if (!empty($mapf)){
					$fnm=dirname($msg[0]).'/'.basename($graph);
					$a=loadnanonis_sts($fnm);
					$exp=$a['data'];
					$chanlist=$a['chan'];
					$nchan=0;
					foreach(array_slice($exp,1) as $achan => $chandata){
						if (In_array($nchan,$show) || $show[0]==''){
							graph_drw($exp[$chanlist[0]],$chandata,$chanlist[0],'',$imgwidth*0.5,$imgwidth,$userlnk.$user.'/'.$nchan);
							echo '<TR><TD><h3>'.$achan.'</h3><img src="';
							echo $userlnk.$user.'/'.$nchan.'.png?'.date("U").'"></TR>';	
						}
						$nchan++;
					}
				}else{			
					graph_drw([0,1],[0,1],'','',$imgwidth*0.5,$imgwidth,$userlnk.$user.'/void');
					echo '<TR><TD><h3>void</h3><img src="';
					echo $userlnk.$user.'/void.png?'.date("U").'"></TR>';
				}
	
?>
</TABLE></FORM>

</TD></TR></TABLE>
</div>

<script>
				//document.addEventListener("keypress", function onPress(event) {
document.onkeydown = function(event) {
keycode=event.keyCode

	if (keycode == '38') {
	 event.preventDefault();
	    document.getElementById('prevs').style.background="#ff0";
	    document.getElementById('prevs').click();
    }
if (keycode == '40') {

	 event.preventDefault();
	    document.getElementById('nexts').style.background="#ff0";
	    document.getElementById('nexts').click();
    }
 


};
</script>

</BODY>
</html>
<?exit;?>
