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
?>