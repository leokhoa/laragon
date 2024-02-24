<?php

$version = '1-1-1';

header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: private');

?><!DOCTYPE html>
<html lang=en>
<head>
<meta charset=utf-8>

<?php if (is_ie()) {
  // Always force latest IE rendering engine and chrome frame (also hides compatibility mode button)
  ?><meta http-equiv=X-UA-Compatible content="IE=edge,chrome=1"><?php
} ?>

<?php /* Disable phone number detection on apple devices. */?>
<meta name=format-detection content="telephone=no">

<?php /* I don't think we ever want this to be indexed*/ ?>
<meta name=robots content="noindex,nofollow,noarchive">

<meta name=author content="https://github.com/ErikDubbelboer/">

<title><?php echo format_html($server['host'])?> - phpRedisAdmin</title>

<?php foreach ($page['css'] as $css) { ?>
<link rel=stylesheet href="css/<?php echo $css; ?>.css?v<?=$version?>" media=all>
<?php } ?>

<link rel="shortcut icon" href="images/favicon.png">

<?php foreach ($page['js'] as $js) { ?>
<script src="js/<?php echo $js; ?>.js?v<?=$version?>"></script>
<?php } ?>

</head>
<body>
