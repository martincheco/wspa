<?
require('globals.php');
require('auth.php');
header("Content-type: image/png");

if (IsSet($_GET['file'])){
    $fnm=$userdir.$user.'/'.$_GET['file'];
    if(file_exists($fnm)){
	$data=file($fnm);
    }else{
	exit;
    }
}else{
    exit;
}

if (IsSet($_GET['xlabel'])){$xtit=$_GET['xlabel'];}else{$xtit='x-axis';}
if (IsSet($_GET['ylabel'])){$ytit=$_GET['ylabel'];}else{$ytit='y-axis';}


foreach ($data as $row){
    $exp=preg_split("/[\s,]+/", trim($row));
    if (is_numeric($exp[0])){$x[]=$exp[0];}else{$xtit=$exp[0];}
    if (is_numeric($exp[1])){$y[]=$exp[1];}else{$ytit=$exp[1];}
//    echo $exp[0]."|".$exp[1]."<BR>";
}



if (IsSet($_GET['h'])){$hei=$_GET['h'];}else{$hei=200;}
if (IsSet($_GET['w'])){$wid=$_GET['w'];}else{$wid=600;}

//$hei = 250;
//$wid = 400;
$fsz=round(min(Array($wid,$hei))/50);
$fw=ImageFontWidth($fsz);
$fh=ImageFontHeight($fsz);
$hl = 5*$fh;
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

$diff=(max($x)-min($x));
$pwr=round(log10($diff));

if ((($pwr < -1) || ($pwr > 1))){
    foreach($x as $i=>$xi){$x[$i]=$xi/pow(10,$pwr);}
    $xtit=$xtit.' x '.pow(10,$pwr);
}

$diff=(max($y)-min($y));
$pwr=round(log10($diff));

if ((($pwr < -1) || ($pwr > 1))){
    foreach($y as $i=>$yi){$y[$i]=$yi/pow(10,$pwr);}
    $ytit=$ytit.' x '.pow(10,$pwr);
}

$xincr=$w/(max($x)-min($x));
$yincr=$h/(max($y)-min($y));
$xo=min($x);
$yo=min($y);

$tx=($x[0]-$xo)*$xincr+$wl;
$ty=$hei-($y[0]-$yo)*$yincr-$hl;

//draw the graph
foreach($x as $i=>$v){
    $cx=($x[$i]-$xo)*$xincr+$wl;
    $cy=$hei-($y[$i]-$yo)*$yincr-$hl;

    imageline($im,$tx,$ty-1,$cx,$cy-1,$red2);
    imageline($im,$tx,$ty+1,$cx,$cy+1,$red2);
    imageline($im,$tx-1,$ty,$cx,$cy-1,$red2);
    imageline($im,$tx+1,$ty,$cx,$cy+1,$red2);

    imageline($im,$tx,$ty,$cx,$cy,$red);
    $ty = $cy;
    $tx = $cx;
}

//draw x tick marks

$lblh=$fh;
$diff=(max($x)-min($x));
$pwr=round(log10($diff));
$step=pow(10,$pwr-1)*2.;
$prec=1-$pwr;
$ntck=$diff/$step;
$lblw=($fw * strlen(round(max($x),$prec)));
$mtck=2;
$skip=(($wid-$wl-$wh)/$lblw/2/$ntck);
if ($skip <= 0.7){
    $step=$step*2;
//    $prec=$prec;
    $ntck=$diff/$step;
    $mtck=4;
}
if ($skip >= 2.5){
    $step=$step/2;
//    $prec=$prec+1;
    $ntck=$diff/$step;
    $mtck=5;
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


//draw y tick marks

$diff=(max($y)-min($y));
$pwr=round(log10($diff));
$step=pow(10,$pwr-1)*2;
$prec=1-$pwr;
$ntck=$diff/$step;
$lblw=$fw * (strlen(round(max($y),$prec))+1);
$skip=(($hei-$hl-$hh)/$lblh/2/$ntck);
$mtck=2;
if ($skip <= 0.7){
    $step=$step*2;
    $prec=$prec;
    $ntck=$diff/$step;
    $mtck=4;
}
if ($skip >= 2.5){
    $step=$step/2;
    $prec=$prec;
    $ntck=$diff/$step;
    $mtck=5;
}

$starty=ceil(min($y)/$step)*$step;

//$lblw=(ImageFontWidth($fsz) * strlen(1+round(max($y),$prec)));

//$step=pow(10,round(log10(max($x)-min($x))));


    $cx1=$wl;
    $cx2=$wl+$lblh/2;
    $cx3=$wl+$lblh/4;

for ($xp=$starty;$xp<=max($y);$xp=$xp+$step){
//    $xpp=round($xp,$prec);

    $cy=$hei-($xp-$yo)*$yincr-$hl;
    $corr=$fw*strlen(number_format($xp,$prec));
    imageline($im,$cx1,$cy,$cx2,$cy,$black);
    imagestring($im,$fsz,$cx1-$corr,$cy-$lblh/2,number_format($xp,$prec),$black);

    for($j=1;(($xp+$step/$mtck*$j)<=max($y)) && ($j<=$mtck);$j++){
	$cy=$hei-($xp+$step*$j/$mtck-$yo)*$yincr-$hl;
	imageline($im,$cx1,$cy,$cx3,$cy,$black);

    }
}


//draw frame
imageline($im, $wl, $hh, $wid-$wh, $hh, $black);
imageline($im, $wl, $hei-$hl, $wid-$wh, $hei-$hl, $black);
imageline($im, $wl, $hh, $wl, $hei-$hl, $black);
imageline($im, $wid-$wh, $hh, $wid-$wh, $hei-$hl, $black);

//axis labels
imagestring($im,$fsz,$wl+($wid-$wl-$wh)/2-$fw*strlen($xtit)/2+1,$hei-$hl+1.3*$fh+1,$xtit,$gray);
imagestringup($im,$fsz,$wl-$lblw-$lblh*1.3+1,$hh+($hei-$hl-$hh)/2+$fw*strlen($ytit)/2+1,$ytit,$gray);
imagestring($im,$fsz,$wl+($wid-$wl-$wh)/2-$fw*strlen($xtit)/2,$hei-$hl+1.3*$fh,$xtit,$black);
imagestringup($im,$fsz,$wl-$lblw-$lblh*1.3,$hh+($hei-$hl-$hh)/2+$fw*strlen($ytit)/2,$ytit,$black);


//imageline($im, 20, $height-49, $width-10, $height-49, $black);

imagepng($im);
imageDestroy($im);


?>