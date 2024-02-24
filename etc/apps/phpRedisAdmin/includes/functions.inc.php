<?php

function format_html($str) {
  global $server;

  if (isset($server['charset']) && $server['charset']) {
    $res = mb_convert_encoding($str, 'utf-8', $server['charset']);
  } else {
    $res = $str;
  }

  $res = htmlentities($res, defined('ENT_SUBSTITUTE') ? (ENT_QUOTES | ENT_SUBSTITUTE) : ENT_QUOTES, 'utf-8');

  return ($res || !$str) ? $res :  '(' . strlen($str) . ' bytes)';
}


function input_convert($str) {
  global $server;

  if (isset($server['charset']) && $server['charset']) {
    return mb_convert_encoding($str, $server['charset'], 'utf-8');
  } else {
    return $str;
  }
}


function format_time($time) {
  $minute = 60;
  $hour   = $minute * 60;
  $day    = $hour   * 24;

  $when = $time;

  if ($when > $day) {
    $tmpday = floor($when / $day);
    $tmphour = floor(($when / $hour) - (24*$tmpday));
    $tmpminute = floor(($when / $minute) - (24*60*$tmpday) - ($tmphour * 60));
    $tmpsec = floor($when - (24*60*60*$tmpday) - ($tmphour * 60 * 60) - ($tmpminute * 60));
    return sprintf("%d day%s %d hour%s %d min%s %d sec%s",$tmpday,($tmpday != 1) ? 's' : '',$tmphour,($tmphour != 1) ? 's' : '',$tmpminute,($tmpminute != 1) ? 's' : '',$tmpsec,($tmpsec != 1) ? 's' : '');
  } else if ($when > $hour) {
    $tmphour = floor($when / $hour);
    $tmpminute = floor(($when / $minute) - ($tmphour * 60));
    $tmpsec = floor($when - ($tmphour * 60 * 60) - ($tmpminute * 60));
    return sprintf("%d hour%s %d min%s %d sec%s",$tmphour,($tmphour != 1) ? 's' : '',$tmpminute,($tmpminute != 1) ? 's' : '',$tmpsec,($tmpsec != 1) ? 's' : '');
  } else if ($when > $minute) {
    $tmpminute = floor($when / $minute);
    $tmpsec = floor($when - ($tmpminute * 60));
    return sprintf("%d min%s %d sec%s",$tmpminute,($tmpminute != 1) ? 's' : '',$tmpsec,($tmpsec != 1) ? 's' : '');
  } else {
    return sprintf("%d sec%s",$when,($when != 1) ? 's' : '');
  }
}


function format_size($size) {
  $sizes = array('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB');

  if ($size == 0) {
    return '0 B';
  } else {
    return round($size / pow(1024, ($i = floor(log($size, 1024)))), 1).' '.$sizes[$i];
  }
}


function format_ttl($seconds) {
	if ($seconds > 60) {
		return sprintf('%d (%s)', $seconds, format_time($seconds));
	} else {
		return $seconds;
	}
}


function str_rand($length) {
  $r = '';

  for (; $length > 0; --$length) {
    $r .= chr(rand(32, 126)); // 32 - 126 is the printable ascii range
  }

  return $r;
}


function encodeOrDecode($action, $key, $data) {
  global $server;

  if (isset($_GET['raw']) || !isset($server['serialization'])) {
    return $data;
  }

  foreach ($server['serialization'] as $pattern => $closures) {
    if (fnmatch($pattern, $key)) {
      return $closures[$action]($data);
    }
  }

  return $data;
}

function getRelativePath($base) {
  return substr($_SERVER['REQUEST_URI'], strpos($_SERVER['REQUEST_URI'], $base));
}
