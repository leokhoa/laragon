<?php

require_once 'includes/common.inc.php';

if (!empty($config['cookie_auth'])) {
    // Cookie-based auth
    setcookie('phpRedisAdminLogin', '', 1);
    header("Location: login.php");
    die();
} else {
    // HTTP Digest auth
    $needed_parts = array(
      'nonce'    => 1,
      'nc'       => 1,
      'cnonce'   => 1,
      'qop'      => 1,
      'username' => 1,
      'uri'      => 1,
      'response' => 1
     );

    $data = array();
    $keys = implode('|', array_keys($needed_parts));

    preg_match_all('/('.$keys.')=(?:([\'"])([^\2]+?)\2|([^\s,]+))/', $_SERVER['PHP_AUTH_DIGEST'], $matches, PREG_SET_ORDER);

    foreach ($matches as $m) {
      $data[$m[1]] = $m[3] ? $m[3] : $m[4];
      unset($needed_parts[$m[1]]);
    }


    if (!isset($_GET['nonce'])) {
      header('Location: logout.php?nonce='.$data['nonce']);
      die;
    }


    if ($data['nonce'] == $_GET['nonce']) {
      unset($_SERVER['PHP_AUTH_DIGEST']);

      if (!empty($config['cookie_auth'])) {
          $login = authCookie();
      } else {
          $login = authHttpDigest();
      }
    }


    header('Location: logout.php');
}
