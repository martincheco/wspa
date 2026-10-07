<?

function normalize_path($path, $pwd = '/') {
//sanitizes path, taken from a website, no idea how this works, but it works
        if (!isset($path[0]) || $path[0] !== '/') {
                $result = explode('/', getcwd());
        } else {
                $result = array('');
        }
        $parts = explode('/', $path);
        foreach($parts as $part) {
            if ($part === '' || $part == '.') {
                    continue;
            } if ($part == '..') {
                    array_pop($result);
            } else {
                    $result[] = $part;
            }
        }
        return implode('/', $result);
}


session_start();
session_regenerate_id();
if(!IsSet($_SESSION['user']))      // if there is no valid session
{
    session_write_close();
    header("Location: cred.php");
    exit;
}else{
$user=$_SESSION['user'];
}

if (IsSet($_GET['path'])){
	$path=normalize_path($_GET['path']);

//echo $path."<BR>";

	
	while (!Is_Dir($path)){
		$path=dirname($path);
	}
	if (Is_Dir($path)){
		if(strpos($path,getcwd())===0){$path=substr($path,strlen(getcwd())+1);}else{$path="";}
	}else{$path=$datadir;}

	if($path==""){$path=$datadir;}
	$_SESSION['path']=$path;
}else{
$path=$_SESSION['path'];
}

if ($path==''){$path=$datadir;}


if (IsSet($_SESSION['rights'])){$rights=$_SESSION['rights'];}else{$rights="";}


session_write_close();

//echo $path;
?>
