<?php
// takes care of user logins with sanitized authentication

require('globals.php');

function pauth($user, $pass, $userdir) {
    // Sanitize username to alphanumeric, underscore, and hyphen characters only
    $clean_user = preg_replace('/[^a-zA-Z0-9_\-]/', '', $user);
    if (empty($clean_user)) {
        return false;
    }

    $pfl = $userdir . $clean_user . "/profile.php";
    if (file_exists($pfl)) {
        $pflc = file($pfl);
        if (isset($pflc[1])) {
            $passs = rtrim($pflc[1]);
            // Support password_verify for bcrypt/argon2 hashes, with fallback to constant-time string comparison
            if (password_verify($pass, $passs) || hash_equals($passs, $pass)) {
                return true;
            }
        }
    }
    return false;
}

session_start();

if (isset($_POST['usename']) && isset($_POST['drowssap'])) {
    $clean_user = preg_replace('/[^a-zA-Z0-9_\-]/', '', $_POST['usename']);

    if (pauth($_POST['usename'], $_POST['drowssap'], $origuserdir)) {
        // Authenticated: regenerate session ID to prevent Session Fixation
        session_regenerate_id(true);
        $_SESSION['user'] = $clean_user;

        // Create user session directory natively without shell exec injection risk
        $target_user_dir = $userdir . $clean_user;
        if (!is_dir($target_user_dir)) {
            @mkdir($target_user_dir, 0775, true);
        }

        $tmpdat = $target_user_dir . "/tmp.dat";
        $lastpath = "";
        if (file_exists($tmpdat)) {
            $lastpath_lines = file($tmpdat);
            if (!empty($lastpath_lines)) {
                $lastpath = urlencode(dirname(trim($lastpath_lines[0])));
            }
        }
        header("Location: browser.php?path=" . $lastpath);
        exit;
    } else {
        // Authentication failed: redirect back to login
        header("Location: cred.php");
        exit;
    }
} else {
    // Username or password missing: redirect back to login
    header("Location: cred.php");
    exit;
}

exit;
?>