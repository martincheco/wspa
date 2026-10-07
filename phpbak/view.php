<?
require('auth.php');
require('head.php');
//exit;
//echo $path."<BR>";


echo "<TABLE><TR><TD>";
if (strlen($path)===0){echo "No path specified.</body></html>";exit;}else{echo "Logged in as ".$user;}
echo "</TD></TR></TABLE>";

echo '<div class="loc"><TABLE><TR><TD>Images in '.$path.'</TD></TR></TABLE></div>';


//check rights not implemented yet!!



$handle=opendir($path);
$pics=array();

?>
<?
//	read directory into pics array
while (($file = readdir($handle))!==false) {
	//	filter for jpg, gif or png files...
	if (substr($file,-4) == ".jpg" || substr($file,-4) == ".gif" || substr($file,-4) == ".png" || substr($file,-4) == ".JPG" || substr($file,-4) == ".GIF" || substr($file,-4) == ".PNG"){
	// 	you can apply other filters here...
		$pics[$count] = $file;
		$count++;
	//	don't forget to close the filter conditions here!
	}
}
closedir($handle); 

//	done reading, sort the filenames alphabetically, shade these lines if you want no sorting
if (count($pics)===0){echo "No images recognized in this directory.</body></html>";}

//echo count($pics);
//exit;
sort($pics);
reset($pics);

foreach ($pics as $pic){
    echo '<div style="display: inline-block;width: 200px;padding:2px;overflow:hidden;font-size:80%;text-align:center;position:relative;">';
    echo '<a class="decor" href='.$path.'/'.$pic.' target=_blank><img src='.$path.'/'.$pic.' style="max-height:200px;max-width:200px;">';
    echo '<div>'.$pic.'</div></a></div>';
}

//for ($i=$cnt;$i++;$i<5;){echo "<TD>";}

exit;
?></body>
</html>
