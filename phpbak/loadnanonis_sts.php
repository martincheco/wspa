<?
function transpose($array) {
    array_unshift($array, null);
    return call_user_func_array('array_map', $array);
}

function loadnanonis_sts($fnm){

	$fnm=trim($fnm);
	if(file_exists($fnm)){
		$data=file($fnm);
    	}else{
		echo "<h3>File not found!</h3>";
		exit;
    	}


$hdr=true;
$chns=false;
foreach ($data as $row){
//    $exp=preg_split("/[\s,]+/", trim($row));
//    if (is_numeric($exp[0])){$x[]=$exp[0];}else{$xtit=$exp[0];}
//    if (is_numeric($exp[1])){$y[]=$exp[1];}else{$ytit=$exp[1];}

	if (strpos($row, 'DATA') !== false){$hdr=false;$chns=true;continue;}
	if (!($hdr) && $chns){$chan=preg_split("/[\t,]+/", trim($row));$chns=false;continue;}
	if ($hdr){$header[]=$row;}else{$dat[]=$row;}
}

//foreach ($header as $row){echo $row."<BR>";}
//echo "DATA!!!";

//$chan=preg_split("/[\t,]+/", trim($dat[0]));


foreach ($dat as $row){
	$exp[]=preg_split("/[\t,]+/", trim($row));
}

//$expt=array_map(null, ...$exp);
$expt=transpose($exp);

$exptt=array_combine($chan, $expt);

$strctre['header']=$header;
$strctre['chan']=$chan;
$strctre['data']=$exptt;

return $strctre;

}

?>
