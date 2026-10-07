<?
function help_tooltip($filter){
//	$tooltip="Sorry, no description available";
	if (file_exists('help/'.$filter.'.txt')){
		$hlpf=file('help/'.$filter.'.txt');
		$tooltip[]=$hlpf[2];
		if (count($hlpf)>=4){if ($hlpf[4]!=""){
			$tooltip[]='&#013;';
			$tooltip[]='SYNTAX:&#013;'.$hlpf[4];
			$tooltip[]='&#013;';
		}
		}
		$tooltip[]=Implode(array_slice($hlpf,6));
	
//	$tooltip[]='SYNTAX: '.$hlpf[1];
	

}
//print_r($tooltip);
if (Is_Array($tooltip)){
return Implode($tooltip);}else{return $tooltip;}
}


function help_plain($filter){
//	$tooltip="Sorry, no description available";
	if (file_exists('help/'.$filter.'.txt')){
		$hlpf=file('help/'.$filter.'.txt');
	}
return Implode($hlpf);
}

?>
