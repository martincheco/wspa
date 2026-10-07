<?

require('globals.php');
require('auth.php');
require('perms.php');

function masterlockmod($protect,$right){
if ($protect==='o'){$lk="lock";}else{$lk="unlock";}
if ($right==='o'){$yell="_y";}else{$yell="";}
return '<input name="lock" value="'.$lk.'" type=image src="icons/'.$lk.$yell.'.gif">';
}
function lockmod($protect){
if ($protect==='o'){return '<img src="icons/lock.gif">';}else
return '<img src="icons/nil.gif">';
}

function masterrightsmod($rights,$path){
if ($rights==='w'){$res='<img src="icons/yes.gif">';}
if ($rights==='o'){$res='<a href=edituser.php?='.urlencode($path).'><img src="icons/own.gif"></a>';}
if ($rights===0){$res='<img type=image src="icons/ban.gif">';}
if ($rights==='r'){$res='<img type=image src="icons/eye.gif">';}
return $res;
}


function rightsmod($rights){
if ($rights==='w'){$res='<img src="icons/yes.gif">';}
if ($rights==='o'){$res='<img src="icons/own.gif">';}
if ($rights===0){$res='<img type=image src="icons/ban.gif">';}
if ($rights==='r'){$res='<img type=image src="icons/eye.gif">';}
return $res;
}

function linkseq($path){
$res='';
if ($path!='.'){$path=dirname($path);}else{return $res;}
while($path!='.'){
$res='<a href=browser.php?path='.urlencode($path).'>'.basename($path).'</a>/'.$res;
$path=dirname($path);
}
return $res;
}

//GET A SESSION USER etc.

$msg[]="Logged in as ".$user; //error messages
$mp=0;     //message position

if (IsSet($_GET['msg'])){
$msg[$mp]=$_GET['msg'];
$mp++;
}


//RIGHTS FOR CURRENT PATH
$dirperms=check_rights($path,$user);
$dirrights=$dirperms[0];
$dirprotect=$dirperms[1];


//OWNER ACTIONS
if (($_POST['lock']==="unlock") && ($dirrights==="o")){
	if (add_editor($path,$user,'o') && add_editor($path,'protect','o')){
		$msg[$mp]="Locked!";
		$mp++;
	}
	$dirperms=check_rights($path,$user);
	$dirrights=$dirperms[0];
	$dirprotect=$dirperms[1];
	
}
if (($_POST['lock']==="lock") && ($dirrights==="o")){
	if (rm_editor($path,'protect')){
		$msg[$mp]="Unlocked!";
		$mp++;
	}
	$dirperms=check_rights($path,$user);
	$dirrights=$dirperms[0];
	$dirprotect=$dirperms[1];
}

//HEADER

require('head.php');

if ($dirrights===0){
	$result=Array('void');$msg[$mp]=$user.", you have no rights for this directory!";$mp++;
}else{
}

echo "<TABLE>";
foreach ($msg as $submsg){echo "<TR><TD>".$submsg."</TR>";}
echo "</TABLE>";

echo '<div class="loc"><TABLE><TR><TD><FORM method=POST>'.masterlockmod($dirprotect,$dirrights).rightsmod($dirrights).'</FORM></TD><TD>'.($path)."</TD>";
//echo '<TD>'.basename($path)."</TD>";
echo "</TR></TABLE></div>";
if ($dirrights==='o'){print_r(get_rights($path));}
?></body>
</html>
<?exit;?>