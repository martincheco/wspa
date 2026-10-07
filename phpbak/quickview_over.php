<?

require('globals.php');
require('auth.php');
$tmpdat=$userdir.$user."/tmp.dat";
//read channel info and determine which keys are in the same set
if (file_exists($userdir.$user.'/chan.dat')){
	$chans=file($userdir.$user.'/chan.dat');
}
if (file_exists($userdir.$user.'/acqchan.dat')){
	$acqchans=file($userdir.$user.'/acqchan.dat');
}
$acqchans=preg_replace("/[\\n\\r]+/", "",$acqchans);

$msg=file($tmpdat);
$mapdir=pathinfo(trim(stripslashes($msg[0])), PATHINFO_DIRNAME);


//read image index from file
$parts = preg_split('/\s+/', $msg[1]);
$index=$parts[1]-1;

require('over.php');

require('head.php');

//is a part of image retrieval, depends on use of shared memory
if ($shm!=''){$userlnk=$userlink;}else{$userlnk=$userdir;}

//print_r($index);
?>

<div class="fill">
<div class="scrollfill">
<TABLE>
<TR>
			

	<TD style="vertical-align:top;width:30em;">
		<TABLE style="position:relative;z-index:1;">
		<TR>
			<TD>
<?	

$c=0;
$obi="";
foreach ($chans as $i){
	$info = pathinfo($i);

//	$mapfile=pathinfo(pathinfo(trim(stripslashes($info['basename'])), PATHINFO_FILENAME),PATHINFO_FILENAME).'.map';


	$value = isset($info['extension']) ? $info['extension'] : '';
	$bi =  basename($i,'.'.$value);
	$info = pathinfo($bi);

	$value = isset($info['extension']) ? $info['extension'] : '';
	$bi =  basename($bi,'.'.$value);






	if($bi != $obi){

//		echo "</TD></TR><TR><TD>".basename($msg[0])." ".$msg[1];
		echo "</TD></TR><TR><TD>";

		$mapfile=$mapdir.'/'.pathinfo(pathinfo(trim(stripslashes($info['basename'])), PATHINFO_FILENAME),PATHINFO_FILENAME).'.map';
		if (file_exists($mapfile)){
			$mapx=Array();
			$mapy=Array();
			$mapsy=Array();
			$mapf=Array();
			$map=file($mapfile);
	    		$ccc=1;
    			foreach($map as $mapln){
        			if($ccc==0){
 		        	$mapf[]=$mapln;$ccc=1;
			        }else{
			        $mapc=preg_split('/\s+/',trim($mapln));
			        $mapx[]=$mapc[0];
		        	$mapy[]=$mapc[1];
			        $mapsy[]=$mapc[2];
			        $ccc=0;
			        }
			}
			$stsim='sts.png';$mtagc='color:#0e0;';
			$hh[1]=100;
//			foreach($mapx as $key=>$dummy){
//				echo '<img src="'.$stsim.'" style="position:absolute;left: '.($mapx[$key]*$hh[1]/$mapsy[$key]-4).'px; top: '.($hh[1]-$mapy[$key]*$hh[1]/$mapsy[$key]-4).'px;">';
//
//			}

		
			$bordercol="#0e0";
			
		}else{$bordercol="#567";}
		
		if(in_array($c,$chline)){$bordercol="#fff; outline: 2px solid #0aa;  outline-offset: -2px";}

		$mapfile="";

	}

	echo '<a href="quickview.php?command=goto '.($c+1).'&over=over" title="'.$bi.'" ><img id="img'.$c.'" src="'.$userlnk.$user.'/tmp'.$c.'.png?v='.filemtime($userlnk.$user.'/tmp'.$c.'.png').'" style="max-width:100px; max-height:100px;padding:1px;background-color:'.$bordercol.';" title="'.$bi.'"></a>';


	$c++;
	$obi=$bi;

}
?>


	</TR>
	</TABLE>

</TR>
</TABLE>
</div>
</div>


<script>

window.addEventListener('load',function(){

var elmnt = document.getElementById('<?echo 'img'.$index;?>');
console.log(elmnt);

elmnt.scrollIntoView(
	{
            behavior: 'auto',
            block: 'center',
            inline: 'center'
        }

	);
})

</script>


</BODY>

<?

exit;?>
