<?php

// System-wide configuration variables

$origuserdir = "users/";
$shm = "/run/shm/wspa/";
// Location of shared memory filesystem (tmpfs in fstab). Put $shm="" if you run into troubles.

$userdir = $shm . $origuserdir;
$userlink = "users_link/";
$datadir = "data/";
$readystring = "READY\n"; // GDL sends this to announce finish of loading
$failstring = 'Execution halted';
$qout = 1; // Quickview default timeout in seconds (reload rate for launcher)
$qtout = 20; // Timeout for quickview actions
$maxw = 400; // Quickview max image size
$maxh = 400;

$help_default = false;
$sts_default = true;
$sts_max_curves = 16; // Maximum simultaneously plottable spectroscopy curves in sts.php

require_once('functions.php');

?>
