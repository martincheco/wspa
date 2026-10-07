<?
//takes care about user logins

require('globals.php');

function pauth($user,$pass,$userdir){
$pfl=$userdir.$user."/profile.php";
echo $pfl;
if (file_exists($pfl)){
    $pflc=file($pfl);
    $passs=rtrim($pflc[1]);
    if ($passs==$pass){
//	$_SESSION('path')=$pflc(1);
	return TRUE;
    }else{
	return FALSE;
    }
}else{
    return FALSE;
}

return FALSE;
}

session_start();
if( isset($_POST['usename']) && isset($_POST['drowssap']) )
{
    
    if( pauth($_POST['usename'], $_POST['drowssap'],$origuserdir) )
    {
        // auth okay, setup session, remove comm pipe
	$_SESSION['user'] = $_POST['usename'];
        // make user directory, redirect to required page
	exec('mkdir -p '.$userdir.$_POST['usename']);
	$tmpdat=$userdir.$_POST['usename']."/tmp.dat";
	if(file_exists($tmpdat)){$lastpath=file($tmpdat); $lastpath=urlencode(dirname($lastpath[0]));}
        header( "Location: browser.php?path=".$lastpath );
	exit;
     } else {
        // didn't auth go back to loginform
        header( "Location: cred.php" );
	exit;
     }
 } else {
     // username and password not given so go back to login
     header( "Location: index.html" );
    exit;
    echo "no";
 }
exit;
?>