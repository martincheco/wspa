<?

$origuserdir="users/";
$shm="/run/shm/wspa/";
//$shm="";
//location of shared memory filesystem, tmpfs in fstab, put $shm=""; if you run into troubles

$userdir=$shm.$origuserdir;
$userlink="users_link/";
$datadir="data/";
$readystring="READY\n"; //GDL sends this to announce finish of loading
$failstring='Execution halted';
$qout=1; //quickview default timeout in seconds, reload rate for launcher
$qtout=20; //timeout for quickview actions 
$maxw=400; //quickview max image size
$maxh=400;

$help_default=false;
$sts_default=true;

?>
