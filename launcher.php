<?php

require('globals.php');
require('auth.php');

$path = isset($_GET['path']) ? $_GET['path'] : (isset($_POST['path']) ? $_POST['path'] : '');

if (isset($_GET['log'])) {
    $log = "yes";
} else {
    // Create session directories natively
    if (!is_dir($userdir . $user)) {
        @mkdir($userdir . $user, 0775, true);
    }

    if ($shm != '') {
        @unlink($userlink . $user);
        @symlink($userdir . $user . '/', $userlink . $user);
    }

    // Cleanly wipe active session state files (strictly preserving mylist.lst)
    wipe_user_session_dir($userdir, $user);

    // Pre-populate tmp<N>.png symlinks from process/ cache if present
    if (!empty($path)) {
        populate_workspace_tmp_links($path, $userdir, $user);
    }

    // Attempt start via GDL Session Manager Daemon
    $res = gdl_session_request('start', array(
        'user' => $user,
        'session_dir' => $userdir . $user,
        'work_dir' => getcwd()
    ));

    if (!$res || (isset($res['status']) && $res['status'] !== 'ok')) {
        // Fallback: spawn launcher via shell command
        exec('./main_launcher ' . escapeshellarg($userdir . $user) . ' ' . escapeshellarg(getcwd()) . ' >> ' . escapeshellarg($userdir . $user . '/main_launcher.log') . ' 2>&1 &');
    }

    $log = "";
}

if ($log != "") {
    $gdllogfile = $userdir . $user . '/gdl.log';
    $fcs = @file_get_contents($gdllogfile, false, null, -10000);
    if (empty($fcs)) {
        $fcs = @file_get_contents($gdllogfile);
    }

    if (stripos($fcs, $readystring) !== false) {
        if (!empty($path)) {
            sync_process_preview_dir($path, $userdir, $user);
        }
        header('Location: quickview.php?path=' . urlencode($path));
        exit;
    }
    if (stripos($fcs, $failstring) !== false) {
        header('Location: err.php?path=' . urlencode($path));
        exit;
    }

    $fc = $fcs;
}

if (isset($fcs) && strpos($fcs, "processing image", -1000) !== false) {
    $ps = strpos($fcs, 'processing image', -1000);
    $snip = substr($fcs, $ps + 16, 40);
    $snip = preg_replace('/\s+/', ' ', trim($snip));
    $esnip = explode(" ", $snip);
    if (isset($esnip[0]) && isset($esnip[2]) && (float)$esnip[2] > 0) {
        $prog = ($esnip[0] / $esnip[2]);
    }
    if (!isset($prog) || $prog < 0.01) {
        $prog = 0.01;
    }
}

if (!isset($prog)) {
    $prog = 0.01;
}

header('Refresh: ' . ($qout) . '; url=launcher.php?path=' . urlencode($path) . '&log=reload', true, 303);

require('head.php');

echo "<FORM method=GET>";

?>
<div class="fill">
<TABLE><TR><TD>Loading and processing files - <b><span id="progress"><?php echo number_format($prog * 100, 0) . "%";?></span></b> done</TR>
<TR><TD><span style="float:left; width:<?php echo ($prog * 100);?>%; background-color:#a00">&nbsp;</span>

	<TR><TD><TABLE><TR><TD>

<FORM method=POST>
<TEXTAREA readonly tabindex=-1 id="filldebug" NAME="log" rows=30>
<?php if (isset($fcs)) { echo htmlspecialchars($fcs); } ?></TEXTAREA></FORM>
</TR></TABLE></TR></TABLE>
</div>
	<script>
		var textArea = document.getElementById("filldebug");
		if (textArea) {
			textArea.scrollTop = textArea.scrollHeight;
		}
	</script>

</body>
</html>
<?php exit; ?>
