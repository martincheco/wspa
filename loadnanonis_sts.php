<?php
/**
 * WSPA Nanonis Spectroscopy Data Parser
 *
 * Reads Nanonis .dat spectroscopy files, extracting:
 * - 'header': Raw header lines
 * - 'params': Structured associative key-value parameter map (Bias, Z, Lock-In, etc.)
 * - 'chan':   List of channel column names
 * - 'data':   Associative array: channel_name => array of float values
 */

if (!function_exists('transpose')) {
	function transpose($array) {
		if (empty($array)) return array();
		array_unshift($array, null);
		return call_user_func_array('array_map', $array);
	}
}

function loadnanonis_sts($fnm) {
	$fnm = trim($fnm);
	if (!file_exists($fnm) || !is_file($fnm)) {
		return false;
	}

	$lines = @file($fnm);
	if ($lines === false || empty($lines)) {
		return false;
	}

	$is_hdr = true;
	$is_next_chan = false;
	$header_raw = array();
	$params = array();
	$chan = array();
	$data_rows = array();

	foreach ($lines as $row) {
		$trim_row = trim($row);
		if ($trim_row === '') continue;

		// Check for [DATA] boundary
		if (strpos($trim_row, '[DATA]') !== false || strpos($trim_row, 'DATA') === 0) {
			$is_hdr = false;
			$is_next_chan = true;
			continue;
		}

		if ($is_hdr) {
			$header_raw[] = $row;
			// Parse key-value parameters separated by tab
			$p = explode("\t", $trim_row, 2);
			if (count($p) >= 2) {
				$k = trim($p[0]);
				$v = trim($p[1]);
				if ($k !== '') {
					$params[$k] = $v;
				}
			} elseif (strpos($trim_row, ':') !== false) {
				$p = explode(':', $trim_row, 2);
				$params[trim($p[0])] = trim($p[1]);
			}
		} else {
			if ($is_next_chan) {
				// Parse channel headers
				$chan_candidates = preg_split("/\t+/", $trim_row);
				if (count($chan_candidates) <= 1) {
					$chan_candidates = preg_split("/[\t,]+/", $trim_row);
				}
				$chan = array();
				foreach ($chan_candidates as $cn) {
					$cn = trim($cn);
					if ($cn !== '') $chan[] = $cn;
				}
				$is_next_chan = false;
			} else {
				// Data row values (Fast path: Nanonis .dat files are tab-delimited)
				if (strpos($trim_row, "\t") !== false) {
					$row_vals = explode("\t", $trim_row);
				} else {
					$row_vals = preg_split("/\s+/", $trim_row);
				}
				$numeric_vals = array();
				foreach ($row_vals as $rv) {
					$rv = trim($rv);
					if ($rv === '') continue;
					$numeric_vals[] = is_numeric($rv) ? floatval($rv) : $rv;
				}
				if (!empty($numeric_vals)) {
					$data_rows[] = $numeric_vals;
				}
			}
		}
	}

	$header_text = is_array($header_raw) ? implode('', $header_raw) : $header_raw;

	$n_chans = count($chan);
	if ($n_chans === 0 || empty($data_rows)) {
		return array(
			'header' => $header_text,
			'params' => $params,
			'chan'   => $chan,
			'data'   => array()
		);
	}

	// Align data columns to channels
	$col_data = array();
	for ($c = 0; $c < $n_chans; $c++) {
		$ch_name = $chan[$c];
		$col_data[$ch_name] = array();
	}

	foreach ($data_rows as $row) {
		for ($c = 0; $c < $n_chans; $c++) {
			$ch_name = $chan[$c];
			$val = isset($row[$c]) ? $row[$c] : 0.0;
			$col_data[$ch_name][] = $val;
		}
	}

	return array(
		'header' => $header_text,
		'params' => $params,
		'chan'   => $chan,
		'data'   => $col_data
	);
}
?>
