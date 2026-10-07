<?php
require('globals.php');
require('auth.php');

$msg = array();
$msg[0] = "Logged in as " . $user;

if (isset($_GET['msg'])) {
    $msg[0] = $_GET['msg'];
}

$dirrights = is_writable($path) ? 'RW' : 'RO';

require('head.php');

echo "<TABLE>";
echo "<TR><TD>" . (isset($msg[0]) ? htmlspecialchars($msg[0], ENT_QUOTES, 'UTF-8') : '') . "</TD></TR>";
echo "</TABLE>";

echo '<div class="loc"><TABLE><TR><TD style="padding-left:5px;">Folder: ' . htmlspecialchars($path) . ' &nbsp; Status: ' . ($dirrights === 'RW' ? '<span class="badge-rw">RW</span> (Writable)' : '<span class="badge-ro">RO</span> (Read-Only)') . '</TD></TR></TABLE></div>';
?></body>
</html>
<?php exit; ?>