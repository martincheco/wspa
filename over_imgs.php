<?php
foreach ($chline as $i){
	$img_file = $userlnk . $user . '/tmp' . $i . '.png';
	$hh = @getimagesize($img_file);
	$w_attr = ($hh && !empty($hh[0]) && !empty($hh[1])) ? 'width="'.$hh[0].'" height="'.$hh[1].'"' : '';
	$ar_css = ($hh && !empty($hh[0]) && !empty($hh[1])) ? 'aspect-ratio: '.$hh[0].' / '.$hh[1].'; ' : '';
	$v = (function_exists('get_dataset_token') ? get_dataset_token($user) : '0') . '-' . (@filemtime($img_file) ?: '0');
	$bg = ($i == $ckey) ? '#fff' : '#000';

	echo '<a href="?command=goto '.($i+1).'&over=over"><img src="'.$img_file.'?v='.$v.'" '.$w_attr.' style="'.$ar_css.'width:auto;height:auto;max-height:'.$mxh.'px;max-width:'.$mxh.'px;padding:1px;background-color:'.$bg.';" title="'.$acqchans[$i].'"></a>';
}
?>
