<?

require('globals.php');
require('auth.php');
require('perms.php');

//Directory structure:

//Directory structure for data on a domain level has four levels: domain,location, project and data
//in the dirnames, only these characters are allowed A-z, 0-9, -_, length limited to 20 characters
//domain level contains dirs linked to contents of different domains, for now it is only local, untouchable
//location level are directories or symlinks that contain projects, can be located in linux home accounts or in this web root, it is untouchable, but editors can create projects
//project level defines the experiment, can be modified by all editors with appropriate rights
//data level contains directories with actual data in directories, they have to follow a strict naming convention YYYY-MM-DD_DESCRIPTION
//unconventional dirnames and filenames are not handled

//Permissions:

//files with permissions are stored under each project directory locally
//rights of editor for a project or data level can be: read (r), write (w), own (o)
//editor with o (creator) can access all data and modify it and assign editors for the project level, he can delete the projectm process the data
//editor with w can process data (create .flt files in quickview for example), he can add editors with r
//editor with r can only see data

//directory can be restricted, in that case, no other than people specified in the rights file can access its subdirs

//optionally (set in globals): for dirs with missing rights, any editor can add his/herself to the data with the w rights at data level

//structure of the permission file is generally:
//
//editor1$rights
//editor2$rights
//protect$o <--this restricts access to non-listed people to this dir and all subdirs
//

function spc2nbsp($whatever) 
{ 
    return str_replace(' ','&nbsp;',$whatever); 
}

function multiexplode ($delimiters,$string) {
    
    $ready = str_replace($delimiters, $delimiters[0], $string);
    $launch = explode($delimiters[0], $ready);
    return  $launch;
}


function myfnmatch($mask,$file){
$mmask=multiexplode(array(';',",","|",":"),$mask);

foreach ($mmask as $pmask){if (fnmatch($pmask,$file)){return TRUE;}}
return FALSE;
}

function masterlockmod($protect,$right){
if ($protect==='o'){$lk="lock";}else{$lk="unlock";}
if ($right==='o'){$yell="_y";}else{$yell="";}
return '<input type=image src="icons/'.$lk.$yell.'.gif"><input type="hidden" name="lock" value="'.$lk.'"> ';
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

function linkseq($path,$mode){
$res='';
if ($path!='.'){$path=dirname($path);}else{return $res;}
while($path!='.'){
$res='<a href=browser.php?path='.urlencode($path).'&mode='.$mode.'>'.basename($path).'</a>/'.$res;
$path=dirname($path);
}
return $res;
}

function sortbykey($data,$which,$ascend){

//print_r($data);
foreach ($data as $key => $row) {
    $mid[$key]  = $row[$which];
}

// Sort the data with mid descending
// Add $data as the last parameter, to sort by the common key
if (IsSet($mid)){if ($ascend) {array_multisort($mid, SORT_ASC, $data);}else{array_multisort($mid, SORT_DESC, $data);}}

return $data;
}

function extractzip($what,$where){
$zip = new ZipArchive;
if ($zip->open($what) === TRUE) {
    $zip->extractTo($where);
    $zip->close();
    return 1;
} else {
    return -1;
}

}

function list_dir($dir,$user) {
//reads directory and determines rights of a user
if (is_dir($dir)) {
	for ($list = array(),$handle = opendir($dir); (FALSE !== ($file = readdir($handle)));) {
		if (($file != '.' && $file != '..') && (file_exists($path = $dir.'/'.$file))) {
			$entry = array('filename' => $file);
			$entry['modtime'] = filemtime($path);
			
			if (is_dir($path)) {
				$entry['type']="dir";
				$chkrights=check_rights($path,$user);
				$entry['protect']=$chkrights[1];
				$entry['rights']=$chkrights[0];
			}else{
				$entry['type']="file";
			}
			$list[]=$entry;
		}
	}
	closedir($handle);
	return $list;
} else return FALSE;
}


//GET message and old directory

$msg[]="Logged in as ".$user; //error messages
$mp=0;     //message position



if (IsSet($_GET['msg'])){
$msg[$mp]=$_GET['msg'];
$mp++;
}

if (IsSet($_GET['oldpath'])){$oldpath=$_GET['oldpath'];}else{$oldpath="";}
if (IsSet($_POST['mode'])){$mode=$_POST['mode'];}else{if (IsSet($_GET['mode'])){$mode=$_GET['mode'];}else{$mode="File";}}



//RIGHTS FOR CURRENT PATH
$dirperms=check_rights($path,$user);
$dirrights=$dirperms[0];
$dirprotect=$dirperms[1];


//OWNER ACTIONS


if (IsSet($_POST['lock'])){

  if (($_POST['lock']==="unlock") && ($dirrights==="o")){

//	if (add_editor($path,$user,'o')  
	if (add_editor($path,'protect','o')){
		$msg[$mp]="Locked!";
		$mp++;
	}else{$msg[$mp]="Error!";$mp++;}
	$dirperms=check_rights($path,$user);
	$dirrights=$dirperms[0];
	$dirprotect=$dirperms[1];
 	
  }
  
  if (($_POST['lock']==="lock") && ($dirrights==="o")){
	//echo "owner";
	if (rm_editor($path,'protect')){
		$msg[$mp]="Unlocked!";
		$mp++;
	}else{$msg[$mp]="Error!";$mp++;}
	$dirperms=check_rights($path,$user);
	$dirrights=$dirperms[0];
	$dirprotect=$dirperms[1];
 
  }
}
 
if (IsSet($_POST['mkdir'])){
if (($_POST['mkdir']==="MkDir") && ($dirrights==="o") && (stripslashes(trim($_POST['newdir'])))!=""){
    $nwd=basename(stripslashes(trim($_POST['newdir'])));
    if (makeDir($path.'/'.$nwd) && $nwd!=""){$mesg="Created new directory ".$path.'/'.$_POST['newdir'];}else{$mesg="Unable to create new directory ".$path.'/'.$_POST['newdir'];}
//    if ($dirrights==="w"){add_editor($path.'/'.$nwd,$user,'o');}
    header('Location: browser.php?path='.urlencode($path).'&msg='.$mesg.'&mode='.$mode);
    exit;
    
}
}


if (IsSet($_POST['rmdir'])){
if (($_POST['rmdir']==="RmDir") && ($dirrights==="o")){
    $resultx = list_dir($path,$user);
//    print_r($resultx);
    if ((count($resultx)===1) && ($resultx[0]['filename']=='.rights.php')){
	Unlink($path.'/'.'.rights.php');
    }

    if (rmdir($path)){
	$mesg="Deleted directory ".$path;
	$path=dirname($path);
	header('Location: browser.php?path='.urlencode($path).'&msg='.$mesg.'&mode='.$mode);
	exit;
    }else{$msg[$mp]="Unable to delete directory ".$path;$mp++;}
}
}

if (IsSet($_POST['newdirname'])){
if (($_POST['newdirname']!=basename($path)) && ($dirrights==="o") && ($_POST['newdirname']!="") ){
	$nwd=dirname($path)."/".basename($_POST['newdirname']);
	if (!file_exists($nwd) && !is_dir($nwd)){
		if (rename($path,$nwd)){
			$mesg="Directory renamed";
			header('Location: browser.php?path='.urlencode($nwd).'&msg='.$mesg.'&mode='.$mode);
			exit;

		}else{
			$msg[$mp]="Unable to rename directory to ".$nwd;$mp++;
		}
	}else{
		$msg[$mp]="Directory/file already exists: ".$nwd;$mp++;
	}
}
}


//POST DATA FOR MASKING AND OPENING FILES
$mask="";
if (IsSet($_POST['mask'])){$mask=($_POST['mask']);}
//if (IsSet($_POST['apply'])){$apply=($_POST['apply']);}
if (IsSet($_POST['open'])){$open=($_POST['open']);}else{$open="";}
if (IsSet($_POST['del'])){$del=($_POST['del']);}else{$del="";}
if (IsSet($_POST['unzip'])){$unzip=($_POST['unzip']);}else{$unzip="";}
if (IsSet($_POST['upload'])){$upload=($_POST['upload']);}else{$upload='';}

if (IsSet($_POST['checkr'])){

	$checkr=($_POST['checkr']);

	if ($open=="Open"){
		//$open=($_POST['open']);
		unlink($userdir.$user."/mylist.lst");
		//foreach ($checkr as $elem) {$fullcheckr[]=realpath($path.'/'.$elem);}
		foreach ($checkr as $elem) {$fullcheckr[]=getcwd().'/'.$path.'/'.$elem;}
		file_put_contents($userdir.$user."/mylist.lst",Implode("\n",$fullcheckr));
		$msg[$mp]="Open failed (no files selected?)";
		$mp++;
		//write rights to session
		session_start();
		//$_SESSION['path']=$path;
		$_SESSION['rights']=$dirrights;
		session_write_close();
		header('Location: launcher.php?path='.urlencode($path));
		exit;

	}

	if ( ($del=="Del") && ($dirrights==='o') ){
		$count=0;
		foreach ($checkr as $elem) {
			{$fullcheckr[]=$path.'/'.basename($elem);}
		}
		foreach ($fullcheckr as $felem){
		if (Unlink($felem)){$count++;}
		//echo $felem.'<BR>';
		}
		$msg[$mp]=$count.' files deleted';
		$mp++;
	}
	

}


//$msg[$mp]=$mask." ".$check." ".$open." ".$upload." pressed";



//UPLOADING+OPTIONAL UNZIPPING
if ($upload=="Upload" && $dirrights==="o" && IsSet($_FILES['userfile'])){
	$msg[$mp]="Must be an owner to upload!";
	$filearr=$_FILES['userfile'];
	$filecount=0;
	foreach ($filearr['name'] as $key=>$fname) {
		if ($fname!="rights"){if (move_uploaded_file($_FILES['userfile']['tmp_name'][$key], $path."/".$fname)) {$filecount++;}}
		if ($unzip=="Unzip"){extractzip($path."/".$fname,$path."/");}
	}
	//prasarna na msg
	if($filecount!="0"){$mp=0; $msg[$mp]=$filecount." of ".count($filearr['name'])." files succesfully uploaded.";}else{$msg[$mp]="Upload desperately failed!";}
	$mp++;
}


//HEADER

require('head.php');



if ($dirrights===0){
	$result=Array('void');$msg[$mp]=$user.", you have no rights for this directory!";$mp++;
}else{
	$resultx = list_dir($path,$user);
	$result = sortbykey($resultx,'filename',FALSE);
}

echo "<div class=fill><TABLE>";
foreach ($msg as $submsg){echo "<TR><TD>".$submsg."</TR>";}
echo "</TABLE>";

echo '<div class="loc"><TABLE><TR><TD><FORM method=POST>'.masterlockmod($dirprotect,$dirrights).masterrightsmod($dirrights,$path).'</FORM>'.linkseq($path,$mode)."";
if ($dirrights==="o" && $path!="data/" && $path!="data"){
    echo '<FORM method=POST><input type=text size='.min(50,max(strlen(basename($path)),12)).' name=newdirname value="'.basename($path).'"></FORM>';
}else{echo ''.basename($path)."</TD>";}
echo "</TR></TABLE></div>";
echo '<TABLE class="twocolumn"><TR><TD>';
echo '<div class="dlist"><TABLE><TR><TH colspan=2>';


echo '<form id="dirs" method="post">';
//echo '<INPUT TYPE=SUBMIT name="refresh" value="Refresh">';
if ($dirrights==="o"){echo '<input type=submit name="mkdir" value="MkDir"><input type=text size=12 name=newdir placeholder="New Directory">';}else{echo '<INPUT TYPE=SUBMIT name="refresh" value="Refresh">';}

if ($dirrights==="o"){echo '<input type=submit name="rmdir" value="RmDir">';}


echo '</FORM><TABLE><TR><TD style="border:1px solid #888;background-color:#888;height:0px"></TR></TABLE></TR>';

$tr='<TR><TD>';
$ahrf1='<a href=browser.php?mode='.$mode.'&path=';
$ahrf1m='<a style="background:#888" href=browser.php?mode='.$mode.'&path=';
$ei="<img src=icons/nil.gif>";
echo $tr.$ei.$ei."&nbsp;".$ahrf1.urlencode(dirname($path).'/').'&oldpath='.urlencode(basename($path)).'>PARENT DIRECTORY</a><TD></TR>';
  
	foreach ($result as $entry) {
		if ($entry['type']=="dir"){
			if ($oldpath==$entry['filename']){
			    echo $tr.lockmod($entry['protect']).rightsmod($entry['rights']).'&nbsp;'.$ahrf1m.urlencode($path.'/'.$entry['filename'].'/').'>'.spc2nbsp($entry['filename']).'</a><TD align=right>'.date('Y-m-d',$entry['modtime']).'&nbsp;</TD></TR>';
			}else{
			    echo $tr.lockmod($entry['protect']).rightsmod($entry['rights']).'&nbsp;'.$ahrf1.urlencode($path.'/'.$entry['filename'].'/').'>'.spc2nbsp($entry['filename']).'</a><TD align=right>'.date('Y-m-d',$entry['modtime']).'&nbsp;</TD></TR>';
			}
		}
	}

echo '</TABLE></div><TD style="border:1px solid #888;background-color:#888;width:0px"><TD>';


if ($mode!='Img'){
?>
<div class="flist"><TABLE><TR><TH colspan=2>
<form id="basic" enctype="multipart/form-data" method="post">
<input type=submit name="mode" value="File" style="background:#bff"><input type=submit name="mode" value="Img">
<input list="masks" name="mask" size=5 value="<?echo $mask;?>" placeholder="Mask">
<?
//<input type=submit name="Apply" value="~">
?>

<datalist id="masks">
  <option value="*.par">Omicron</option>
  <option value="*.sxm">Nanonis</option>
  <option value="*.nc">GSXM</option>
  <option value="*.top,*.ch0,*.ch1,*.ch2">WSXM</option>
  <option value="*.dat">Createk</option>
  <option value="*.out">Fireball</option>
</datalist><input type=submit name="open" value="Open">
<?
if ($dirrights==="o"){
	echo '<input type=submit name="del" value="Del"> ';
	echo '<input tabindex=-1 type="submit" name="upload" value="Upload">';
	echo '<input name=userfile[] type="file" placeholder="..." multiple=multiple>';
	$chckd='UNCHECKED';
	echo '<input class=checkbox type=checkbox name="unzip" value="Unzip" '.$chckd.'><input type=submit name=unzp value="Unzip" style="background:#333;border-color:#333;color:#ccc">';
}

echo '<TABLE><TR><TD style="border:1px solid #888; background-color:#888;height:0px;"></TR></TABLE></TR>';


	$result = sortbykey($resultx,'filename',TRUE);


	foreach ($result as $entry) {
		if ($entry['type']=="file" && $entry['filename']!=".rights.php"){
			if(myfnmatch($mask,$entry['filename'])){$chked="CHECKED";}else{$chked="";}
			echo '<TR><TD><input class=checkbox type=checkbox name="checkr[]" value="'.$entry['filename'].'" '.$chked.'><a href="'.($path.'/'.$entry['filename']).'" target=_blank>'.$entry['filename'].'</a><TD align=right>'.date('Y-m-d H:i',$entry['modtime']).'</TR>';
		}
	}

    echo '</TABLE></form></div>';


}else{
    
    echo '<div class="flist"><TABLE><TR><TD><FORM id=basic>';
    echo '<input type=submit name="mode" value="File"><input type=submit name="mode" value="Img" style="background:#bff">';

    echo '</FORM></TABLE>';
    echo '<TABLE><TR><TD style="border:1px solid #888; background-color:#888;height:0px;"></TR></TABLE>';

    $handle=opendir($path);
    $pics=array();

    //	read directory into pics array
    $count=0;
    while (($file = readdir($handle))!==false) {
	//	filter for jpg, gif or png files...
//	echo $count;
	if (substr($file,-4) == ".jpg" || substr($file,-4) == ".gif" || substr($file,-4) == ".png" || substr($file,-4) == ".JPG" || substr($file,-4) == ".GIF" || substr($file,-4) == ".PNG"){
	// 	you can apply other filters here...
		$pics[$count] = $file;
		$count++;
	//	don't forget to close the filter conditions here!
	}
    }
    closedir($handle); 

    //	done reading, sort the filenames alphabetically, shade these lines if you want no sorting
    if (count($pics)===0){echo '<div style="display: inline-block;"></div>';}

    sort($pics);
    reset($pics);

    foreach ($pics as $pic){
	echo '<div style="display: inline-block;width:200px;padding:2px;overflow:hidden;text-align:center;position:relative;font-size:inherit;">';
	echo '<a class="decor" href="'.$path.'/'.$pic.'" target=_blank><img src="'.$path.'/'.$pic.'" style="max-height:200px;max-width:200px;">';
	echo '<div style="font-size:10pt">'.$pic.'</div></a></div>';
    }
    echo "</div>";
}



    echo '</TR></TABLE><TABLE><TR><TD style="border:1px solid #888; background-color:#888;height:0px;"></TR></TABLE></div><p align=right>last edit: 2021-02-02</p></div>';


?></body>
</html>
<?exit;?>
