<?php

// This fill will perform HTTP digest authentication. This is not the most secure form of authentication so be carefull when using this.
function authHttpDigest()
{
    global $config;

    $realm = 'phpRedisAdmin';

    // Using the md5 of the user agent and IP should make it a bit harder to intercept and reuse the responses.
    $opaque = md5('phpRedisAdmin'.$_SERVER['HTTP_USER_AGENT'].$_SERVER['REMOTE_ADDR']);


    if (!isset($_SERVER['PHP_AUTH_DIGEST']) || empty($_SERVER['PHP_AUTH_DIGEST'])) {
      header('HTTP/1.1 401 Unauthorized');
      header('WWW-Authenticate: Digest realm="'.$realm.'",qop="auth",nonce="'.uniqid().'",opaque="'.$opaque.'"');
      die;
    }

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

    if (!empty($needed_parts)) {
      header('HTTP/1.1 401 Unauthorized');
      header('WWW-Authenticate: Digest realm="'.$realm.'",qop="auth",nonce="'.uniqid().'",opaque="'.$opaque.'"');
      die;
    }

    if (!isset($config['login'][$data['username']])) {
      header('HTTP/1.1 401 Unauthorized');
      header('WWW-Authenticate: Digest realm="'.$realm.'",qop="auth",nonce="'.uniqid().'",opaque="'.$opaque.'"');
      die('Invalid username and/or password combination.');
    }

    $login         = $config['login'][$data['username']];
    $login['name'] = $data['username'];

    $password = md5($login['name'].':'.$realm.':'.$login['password']);

    $response = md5($password.':'.$data['nonce'].':'.$data['nc'].':'.$data['cnonce'].':'.$data['qop'].':'.md5($_SERVER['REQUEST_METHOD'].':'.$data['uri']));

    if ($data['response'] != $response) {
      header('HTTP/1.1 401 Unauthorized');
      header('WWW-Authenticate: Digest realm="'.$realm.'",qop="auth",nonce="'.uniqid().'",opaque="'.$opaque.'"');
      die('Invalid username and/or password combination.');
    }

    return $login;
}

// Perform auth using a standard HTML <form> submission and cookies to save login state
function authCookie()
{
    global $config;

    $generateCookieHash = function($username) use ($config) {
        if (!isset($config['login'][$username])) {
            throw new \RuntimeException("Invalid username");
        }

        // Storing this value client-side so we need to be careful that it
        //  doesn't reveal anything nor can be guessed.
        // Using SHA512 because MD5, SHA1 are both now considered broken
        return hash(
            'sha512',
            implode(':', array(
                $username,
                $_SERVER['HTTP_USER_AGENT'],
                $_SERVER['REMOTE_ADDR'],
                $config['login'][$username]['password'],
            ))
        );
    };

    if (!empty($_COOKIE['phpRedisAdminLogin'])) {
        // We have a cookie; is it correct?
        // Cookie value looks like "username:password-hash"
        $cookieVal = explode(':', $_COOKIE['phpRedisAdminLogin']);
        if (count($cookieVal) === 2) {
            list($username, $cookieHash) = $cookieVal;
            if (isset($config['login'][$username])) {
                $userData = $config['login'][$username];
                $expectedHash = $generateCookieHash($username);

                if ($cookieHash === $expectedHash) {
                    // Correct username & password
                    return $userData;
                }
            }
        }
    }

    if (isset($_POST['username'], $_POST['password'])) {
        // Login form submitted; correctly?
        if (isset($config['login'][$_POST['username']])) {
            $userData = $config['login'][$_POST['username']];
            if ($_POST['password'] === $userData['password']) {
                // Correct username & password. Set cookie and redirect to home page
                $cookieValue = $_POST['username'] . ':' . $generateCookieHash($_POST['username']);
                setcookie('phpRedisAdminLogin', $cookieValue);

                // This should be an absolute URL, but that's a bit of a pain to generate; this will work
                header("Location: index.php");
                die();
            }
        }
    }

    // If we're here, we don't have a valid login cookie and we don't have a
    //  valid form submission, so redirect to the login page if we aren't
    //  already on that page
    if (!defined('LOGIN_PAGE')) {
        header("Location: login.php");
        die();
    }

    // We must be on the login page without a valid cookie or submission
    return null;
}

if (!empty($config['cookie_auth'])) {
    $login = authCookie();
} else {
    $login = authHttpDigest();
}

?>
