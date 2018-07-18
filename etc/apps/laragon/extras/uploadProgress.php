<?php

/**
* Simple Ajax Uploader
* Version 2.0
* https://github.com/LPology/Simple-Ajax-Uploader
*
* Copyright 2012-2015 LPology, LLC
* Released under the MIT license
*
* Returns upload progress updates for browsers that don't support the HTML5 File API.
* Falling back to this method allows for upload progress support across virtually all browsers.
*
*/

// This "if" statement is only necessary for CORS uploads -- if you're
// only doing same-domain uploads then you can delete it if you want
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');    // cache for 1 day
}

if (isset($_REQUEST['progresskey'])) {
    $status = apc_fetch('upload_'.$_REQUEST['progresskey']);
} else {
    exit(json_encode(array('success' => false)));
}

$pct = 0;
$size = 0;

if (is_array($status)) {

    if (array_key_exists('total', $status) && array_key_exists('current', $status)) {

        if ($status['total'] > 0) {
            $pct = round(($status['current'] / $status['total']) * 100);
            $size = round($status['total'] / 1024);
        }
    }
}

echo json_encode(array('success' => true, 'pct' => $pct, 'size' => $size));
