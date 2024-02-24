<?php
define('LOGIN_PAGE', true);

require_once 'includes/common.inc.php';

$page['css'][] = 'login';

require 'includes/header.inc.php';

// Layout borrowed from http://getbootstrap.com/examples/signin/
?>

<h1 class="logo">phpRedisAdmin</h1>

<form class="form-signin" method="post" action="login.php">
    <h2 class="form-signin-heading">Please log in</h2>

    <?php if (isset($_POST['username']) || isset($_POST['password'])): ?>
        <div class="invalid-credentials">
            <h3>Invalid username/password</h3>
            <p>Please try again.</p>
        </div>
    <?php endif; ?>

    <label for="inputUser" class="sr-only">Username</label>
    <input type="text" name="username" id="inputUser" class="form-control"
           placeholder="Username"
           value="<?= isset($_POST['username']) ? htmlentities($_POST['username'], defined('ENT_SUBSTITUTE') ? (ENT_QUOTES | ENT_SUBSTITUTE) : ENT_QUOTES, 'utf-8') : '' ?>"
           required <?= isset($_POST['username']) ? '' : 'autofocus' ?>>

    <label for="inputPassword" class="sr-only">Password</label>
    <input type="password" name="password" id="inputPassword" class="form-control"
           placeholder="Password"
           required <?= isset($_POST['username']) ? 'autofocus' : '' ?>>

    <button class="btn btn-lg btn-primary btn-block" type="submit">Log in</button>
</form>

<?php

require 'includes/footer.inc.php';

?>
