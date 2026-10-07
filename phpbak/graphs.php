<?


function graph_drw($x,$y,$xtit,$ytit,$hei,$wid,$id){

//print_r($x);
$oytit=$ytit;
//echo "|".$ytit."|";

//header("Content-type: image/png");

$fsz=round(min(Array($wid,$hei))/100);
$fw=ImageFontWidth($fsz);
$fh=ImageFontHeight($fsz);
$hl = 3*$fh;
$wl = 7*$fw;
$hh = $fh/2;
$wh = $fw;


$h=$hei-$hl-$hh;
$w=$wid-$wl-$wh;

$im = imagecreate($wid,$hei);
$white = imagecolorallocate($im,255,255,255);
$gray = imagecolorallocate($im,150,150,150);
$black = imagecolorallocate($im,0,0,0);
$red = imagecolorallocate($im,255,0,0);
$red2 = imagecolorallocate($im,255,96,96);

//echo max($x).' '.min($x);
//echo max($y).' '.min($y);


//reduce zeroes in the axes
$xdiff=(max(abs(max($x)),abs(min($x))))+1e-20;
$xpwr=round(log10($xdiff));
//echo "diff:".$xdiff;
//echo "pwr:".$xpwr;

if((($xpwr < -1) || ($xpwr > 1))){
//if (( (($pwr < -1) && ($pwr > -20)) || ($pwr > 1))){
    foreach($x as $i=>$xi){$x[$i]=$xi/pow(10,$xpwr);}
    $xtit=$xtit.' x '.pow(10,$xpwr);
}

$ydiff=(max(abs(max($y)),abs(min($y))))+1e-20;
$ypwr=round(log10($ydiff));
//echo "diff:".$ydiff;
//echo "pwr:".$ypwr;


if ((($ypwr < -1) || ($ypwr > 1))){
//if (( (($pwr < -1) && ($pwr > -20)) || ($pwr > 1))){
    foreach($y as $i=>$yi){$y[$i]=$yi/pow(10,$ypwr);}
    $ytit=$ytit.' x '.pow(10,$ypwr);
}

$xdif=(max($x)-min($x));
$ydif=(max($y)-min($y));

//$xincr=$w/($xdif);
//$yincr=$h/($ydif);

if ($xdif != 0){$xincr=$w/($xdif);}else{$xincr=0;}
if ($ydif != 0){$yincr=$h/($ydif);}else{$yincr=0;}
$xo=min($x);
$yo=min($y);

$tx=($x[0]-$xo)*$xincr+$wl;
$ty=$hei-($y[0]-$yo)*$yincr-$hl;

//draw the graph
foreach($x as $i=>$v){
    $cx=($x[$i]-$xo)*$xincr+$wl;
    $cy=$hei-($y[$i]-$yo)*$yincr-$hl;

//    imageline($im,$tx,$ty-1,$cx,$cy-1,$red2);
//    imageline($im,$tx,$ty+1,$cx,$cy+1,$red2);
//    imageline($im,$tx-1,$ty,$cx,$cy-1,$red2);
//    imageline($im,$tx+1,$ty,$cx,$cy+1,$red2);

    imageline($im,$tx,$ty,$cx,$cy,$red);
    $ty = $cy;
    $tx = $cx;
}

//draw x tick marks

if($xdif!=0){
$lblh=$fh;
//$diff=(max($x)-min($x));
$xpwr=round(log10($xdif));
$step=pow(10,$xpwr-1)*2;
$prec=1-$xpwr;
$ntck=$xdif/$step;
$lblw=($fw * strlen(round(max($x),$prec)));
$mtck=2;
$skip=(($wid-$wl-$wh)/$lblw/2/$ntck);


if ($skip <= 0.75){
    $step=$step*2;
//    $prec=$prec;
    $ntck=$xdif/$step;
    $mtck=2;
}
if ($skip >= 1.5){
    $step=$step/2;
//    $prec=$prec+1;
    $ntck=$xdif/$step;
    $mtck=2;
}



//$step=pow(10,round(log10(max($x)-min($x))));

$startx=ceil(min($x)/$step)*$step;

    $cy1=$hei-$hl;
    $cy2=$hei-$hl-$lblh/2;
    $cy3=$hei-$hl-$lblh/4;

for ($xp=$startx;$xp<=max($x);$xp=$xp+$step){
    $cx=($xp-$xo)*$xincr+$wl;

    imageline($im,$cx,$cy1,$cx,$cy2,$black);
    $corr=($fw * strlen(number_format($xp,$prec))) / 2;
    imagestring($im,$fsz,$cx-$corr,$cy1,number_format($xp,$prec),$black);

    for($j=1;(($xp+$step/$mtck*$j)<=max($x)) && ($j<=$mtck);$j++){
	    $cx=($xp+$step*$j/$mtck-$xo)*$xincr+$wl;
	    imageline($im,$cx,$cy1,$cx,$cy3,$black);
    }

}
}

//draw y tick marks
if($ydif!=0){
$ypwr=round(log10($ydif));
$step=pow(10,$ypwr-1)*2;
$prec=1-$ypwr;
$ntck=$ydif/$step;
$lblw=$fw * (strlen(round(max($y),$prec))+1);
$skip=(($hei-$hl-$hh)/$lblw/2/$ntck);

/*
echo "ypwr".$ypwr;
echo "step".$step;
echo "prec".$prec;
echo "ntck".$ntck;
echo "skip".$skip."<BR>";
*/
$mtck=2;
if ($skip <= 0.75){
    $step=$step*2;
    $prec=$prec;
    $ntck=$ydif/$step;
    $mtck=2;
}
if ($skip >= 1.5){
    $step=$step/2;
    $prec=$prec;
    $ntck=$ydif/$step;
    $mtck=2;
}

$starty=ceil(min($y)/$step)*$step;

    $cx1=$wl;
    $cx2=$wl+$lblh/2;
    $cx3=$wl+$lblh/4;

if ($ntck<100){
for ($xp=$starty;$xp<=max($y);$xp=$xp+$step){

    $cy=$hei-($xp-$yo)*$yincr-$hl;
    $corr=$fw*strlen(number_format($xp,$prec));
    imageline($im,$cx1,$cy,$cx2,$cy,$black);
    imagestring($im,$fsz,$cx1-$corr,$cy-$lblh/2,number_format($xp,$prec),$black);

    for($j=1;(($xp+$step/$mtck*$j)<=max($y)) && ($j<=$mtck);$j++){
	$cy=$hei-($xp+$step*$j/$mtck-$yo)*$yincr-$hl;
	imageline($im,$cx1,$cy,$cx3,$cy,$black);

    }
}
}
}

//draw frame
imageline($im, $wl, $hh, $wid-$wh, $hh, $black);
imageline($im, $wl, $hei-$hl, $wid-$wh, $hei-$hl, $black);
imageline($im, $wl, $hh, $wl, $hei-$hl, $black);
imageline($im, $wid-$wh, $hh, $wid-$wh, $hei-$hl, $black);

//axis labels
//imagestring($im,$fsz,$wl+($wid-$wl-$wh)/2-$fw*strlen($xtit)/2+1,$hei-$hl+1.3*$fh+1,$xtit,$gray);
//imagestringup($im,$fsz,$wl-$lblw-$lblh*1.3+1,$hh+($hei-$hl-$hh)/2+$fw*strlen($ytit)/2+1,$ytit,$gray);
imagestring($im,$fsz,$wl+($wid-$wl-$wh)/2-$fw*strlen($xtit)/2,$hei-$hl+1.3*$fh,$xtit,$black);
imagestringup($im,$fsz,$lblh*0.15,$hh+($hei-$hl-$hh)/2+$fw*strlen($ytit)/2,$ytit,$black);


//imageline($im, 20, $height-49, $width-10, $height-49, $black);


imagepng($im,$id.".png");
imageDestroy($im);
}

?>
