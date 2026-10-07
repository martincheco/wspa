<?php
/**
 * WSPA User Creation & Management CLI Script
 * Usage: php create_user.php <username> <password> [--force]
 */

if (php_sapi_name() !== 'cli') {
    die("This script can only be run from the command line.\n");
}

if ($argc < 3) {
    echo "Usage: php create_user.php <username> <password> [--force|-f]\n";
    exit(1);
}

$username = trim($argv[1]);
$password = $argv[2];
$force = in_array('--force', $argv) || in_array('-f', $argv);

// Sanitize username
if (!preg_match('/^[a-zA-Z0-9_\-]+$/', $username)) {
    echo "Error: Username can only contain alphanumeric characters, underscores, and hyphens.\n";
    exit(1);
}

if (strlen($password) < 4) {
    echo "Error: Password must be at least 4 characters long.\n";
    exit(1);
}

$user_dir = __DIR__ . "/users/" . $username;
$shadow_dir = $user_dir . "/shadow";
$profile_file = $user_dir . "/profile.php";

$user_exists = file_exists($profile_file);

if ($user_exists && !$force) {
    echo "Error: User '{$username}' already exists!\n";
    echo "To update or reset the password for an existing user, add the --force (or -f) flag:\n";
    echo "  php create_user.php {$username} <new_password> --force\n";
    exit(1);
}

if (!is_dir($user_dir)) {
    if (!mkdir($user_dir, 0775, true)) {
        echo "Error: Failed to create user directory: {$user_dir}\n";
        exit(1);
    }
}

if (!is_dir($shadow_dir)) {
    mkdir($shadow_dir, 0775, true);
}

$hash = password_hash($password, PASSWORD_BCRYPT);
$profile_content = "<? header('HTTP/1.0 404 Not found');die(); ?>\n" . $hash . "\n";

if (file_put_contents($profile_file, $profile_content) !== false) {
    chmod($profile_file, 0664);
    if ($user_exists) {
        echo "Success: Password updated for existing user '{$username}'!\n";
    } else {
        echo "Success: User '{$username}' created successfully!\n";
    }
    echo "Profile: {$profile_file}\n";
} else {
    echo "Error: Failed to write profile file.\n";
    exit(1);
}
?>
