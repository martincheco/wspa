<?php
require_once('auth.php');
require_once('globals.php');

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = $_POST;
    if (empty($data)) {
        $raw = file_get_contents('php://input');
        $json = json_decode($raw, true);
        if (is_array($json)) {
            $data = $json;
        }
    }
    
    // Session-only keys from STS (Rule 20: dynamic channel selections & sweep states are session-bound)
    $session_only_keys = array(
        'sts_num_graphs', 'sts_plot_lines', 'sts_plot_points', 'sts_sync_x',
        'sts_autox', 'sts_autoy', 'sts_fwd', 'sts_bwd'
    );
    
    $cfg_to_save = array();
    foreach ($data as $k => $v) {
        $is_session_bound = in_array($k, $session_only_keys) || preg_match('/^sts_g[1-4]_/', $k);
        if ($is_session_bound) {
            $_SESSION[$k] = $v;
        } else {
            $cfg_to_save[$k] = $v;
        }
    }
    
    $res = true;
    if (!empty($cfg_to_save)) {
        if (isset($cfg_to_save['sts_conv_mode']) && $cfg_to_save['sts_conv_mode'] === 'mev') {
            $cfg_to_save['sts_conv_mode'] = 'ev';
        }
        $res = save_user_config($cfg_to_save, $user);
    }
    session_write_close();
    echo json_encode(array('success' => $res));
    exit;
}

echo json_encode(array('success' => false, 'error' => 'Invalid request method'));
exit;
