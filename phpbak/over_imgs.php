
<?
//print_r($channew);
foreach ($chline as $i){
	if ($i==$ckey){
	    echo '<a href="?command=goto '.($i+1).'&over=over"><img src="'.$userlnk.$user.'/tmp'.$i.'.png?v='.filemtime($userlnk.$user.'/tmp'.$i.'.png').'" style="max-height:'.$mxh.'px;max-width:'.$mxh.'px; padding:1px;background-color:#fff;" title="'.$acqchans[$i].'"></a>';
	}else{
	    echo '<a href="?command=goto '.($i+1).'&over=over"><img src="'.$userlnk.$user.'/tmp'.$i.'.png?v='.filemtime($userlnk.$user.'/tmp'.$i.'.png').'" style="max-height:'.$mxh.'px;max-width:'.$mxh.'px; padding:1px;background-color:#000;" title="'.$acqchans[$i].'"></a>';

	}


}
?>
