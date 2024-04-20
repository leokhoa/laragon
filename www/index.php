<?php
$protocol = isset($_POST['protocol']) ? $_POST['protocol'] : 'https';
$top_lvl_domain = isset($_POST['top_lvl_domain']) ? $_POST['top_lvl_domain'] : '.test';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
  header("Location: " . $_SERVER['PHP_SELF'] . "?protocol=" . urlencode($protocol) . "&top_lvl_domain=" . urlencode($top_lvl_domain));
  exit;
}

if (isset($_GET['protocol'])) {
  $protocol = $_GET['protocol'];
}
if (isset($_GET['top_lvl_domain'])) {
  $top_lvl_domain = $_GET['top_lvl_domain'];
}

if (!empty($_GET['q'])) {
  switch ($_GET['q']) {
    case 'info':
      phpinfo();
      exit;
      break;
  }
}
?>
<!DOCTYPE html lang="en">
<html>

<head>
  <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Laragon</title>
  <link href="https://fonts.googleapis.com/css?family=Karla:400" rel="stylesheet" type="text/css">
  <link rel="shortcut icon" href="https://i.imgur.com/ky9oqct.png" type="image/png">
  <style>
    :root {
      --theme0: #36a2ff;
      --theme1: #08314D;
      --theme1--hover: hsl(204, 100%, 51%);
      --light: #E6F5FF;
      --dark: #08314D;
    }

    *,
    :before *,
    :after * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      font-weight: 100;
      font-family: 'Karla';
      font-size: large;
    }

    img {
      max-width: 100%;
      height: auto;
    }

    nav,
    aside {
      margin: 1rem auto;
      max-width: 1200px;
      text-align: center;
    }

    main {
      background-image: linear-gradient(323deg, rgba(255, 255, 255, 0.01) 0%, rgba(255, 255, 255, 0.01) 16.667%, rgba(46, 46, 46, 0.01) 16.667%, rgba(46, 46, 46, 0.01) 33.334%, rgba(226, 226, 226, 0.01) 33.334%, rgba(226, 226, 226, 0.01) 50.001000000000005%, rgba(159, 159, 159, 0.01) 50.001%, rgba(159, 159, 159, 0.01) 66.668%, rgba(149, 149, 149, 0.01) 66.668%, rgba(149, 149, 149, 0.01) 83.33500000000001%, rgba(43, 43, 43, 0.01) 83.335%, rgba(43, 43, 43, 0.01) 100.002%), linear-gradient(346deg, rgba(166, 166, 166, 0.03) 0%, rgba(166, 166, 166, 0.03) 25%, rgba(240, 240, 240, 0.03) 25%, rgba(240, 240, 240, 0.03) 50%, rgba(121, 121, 121, 0.03) 50%, rgba(121, 121, 121, 0.03) 75%, rgba(40, 40, 40, 0.03) 75%, rgba(40, 40, 40, 0.03) 100%), linear-gradient(347deg, rgba(209, 209, 209, 0.01) 0%, rgba(209, 209, 209, 0.01) 25%, rgba(22, 22, 22, 0.01) 25%, rgba(22, 22, 22, 0.01) 50%, rgba(125, 125, 125, 0.01) 50%, rgba(125, 125, 125, 0.01) 75%, rgba(205, 205, 205, 0.01) 75%, rgba(205, 205, 205, 0.01) 100%), linear-gradient(84deg, rgba(195, 195, 195, 0.01) 0%, rgba(195, 195, 195, 0.01) 14.286%, rgba(64, 64, 64, 0.01) 14.286%, rgba(64, 64, 64, 0.01) 28.572%, rgba(67, 67, 67, 0.01) 28.572%, rgba(67, 67, 67, 0.01) 42.858%, rgba(214, 214, 214, 0.01) 42.858%, rgba(214, 214, 214, 0.01) 57.144%, rgba(45, 45, 45, 0.01) 57.144%, rgba(45, 45, 45, 0.01) 71.42999999999999%, rgba(47, 47, 47, 0.01) 71.43%, rgba(47, 47, 47, 0.01) 85.71600000000001%, rgba(172, 172, 172, 0.01) 85.716%, rgba(172, 172, 172, 0.01) 100.002%), linear-gradient(73deg, rgba(111, 111, 111, 0.03) 0%, rgba(111, 111, 111, 0.03) 16.667%, rgba(202, 202, 202, 0.03) 16.667%, rgba(202, 202, 202, 0.03) 33.334%, rgba(57, 57, 57, 0.03) 33.334%, rgba(57, 57, 57, 0.03) 50.001000000000005%, rgba(197, 197, 197, 0.03) 50.001%, rgba(197, 197, 197, 0.03) 66.668%, rgba(97, 97, 97, 0.03) 66.668%, rgba(97, 97, 97, 0.03) 83.33500000000001%, rgba(56, 56, 56, 0.03) 83.335%, rgba(56, 56, 56, 0.03) 100.002%), linear-gradient(132deg, rgba(88, 88, 88, 0.03) 0%, rgba(88, 88, 88, 0.03) 20%, rgba(249, 249, 249, 0.03) 20%, rgba(249, 249, 249, 0.03) 40%, rgba(2, 2, 2, 0.03) 40%, rgba(2, 2, 2, 0.03) 60%, rgba(185, 185, 185, 0.03) 60%, rgba(185, 185, 185, 0.03) 80%, rgba(196, 196, 196, 0.03) 80%, rgba(196, 196, 196, 0.03) 100%), linear-gradient(142deg, rgba(160, 160, 160, 0.03) 0%, rgba(160, 160, 160, 0.03) 12.5%, rgba(204, 204, 204, 0.03) 12.5%, rgba(204, 204, 204, 0.03) 25%, rgba(108, 108, 108, 0.03) 25%, rgba(108, 108, 108, 0.03) 37.5%, rgba(191, 191, 191, 0.03) 37.5%, rgba(191, 191, 191, 0.03) 50%, rgba(231, 231, 231, 0.03) 50%, rgba(231, 231, 231, 0.03) 62.5%, rgba(70, 70, 70, 0.03) 62.5%, rgba(70, 70, 70, 0.03) 75%, rgba(166, 166, 166, 0.03) 75%, rgba(166, 166, 166, 0.03) 87.5%, rgba(199, 199, 199, 0.03) 87.5%, rgba(199, 199, 199, 0.03) 100%), linear-gradient(238deg, rgba(116, 116, 116, 0.02) 0%, rgba(116, 116, 116, 0.02) 20%, rgba(141, 141, 141, 0.02) 20%, rgba(141, 141, 141, 0.02) 40%, rgba(152, 152, 152, 0.02) 40%, rgba(152, 152, 152, 0.02) 60%, rgba(61, 61, 61, 0.02) 60%, rgba(61, 61, 61, 0.02) 80%, rgba(139, 139, 139, 0.02) 80%, rgba(139, 139, 139, 0.02) 100%), linear-gradient(188deg, rgba(227, 227, 227, 0.01) 0%, rgba(227, 227, 227, 0.01) 20%, rgba(105, 105, 105, 0.01) 20%, rgba(105, 105, 105, 0.01) 40%, rgba(72, 72, 72, 0.01) 40%, rgba(72, 72, 72, 0.01) 60%, rgba(33, 33, 33, 0.01) 60%, rgba(33, 33, 33, 0.01) 80%, rgba(57, 57, 57, 0.01) 80%, rgba(57, 57, 57, 0.01) 100%), linear-gradient(90deg, rgb(230, 245, 255), rgb(230, 245, 255));

    }

    header {
      max-width: 1200px;
      margin: 0 auto;
      text-align: center;

    }

    .header__title {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      align-items: center;
      gap: 1rem;
    }

    .header__description {
      max-width: 600px;
      margin: 0 auto;
      font-size: 1.6rem;
    }

    h1 {
      font-size: clamp(24px, 20vw, 8rem);
    }

    a {
      color: var(--theme1);
      font-weight: 900;
      text-decoration: none;
    }

    a:hover {
      color: var(--theme1--hover);
      font-weight: 900;
      transition: 300ms;
    }

    .alert {
      color: red;
      font-weight: 900;
    }

    .info {
      max-width: 1200px;
      margin: 0 auto;
      padding: 1rem;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      grid-gap: 1rem;
      text-align: center;
    }

    .info__item {
      padding: 0.5rem;
      flex: 1;
      background-color: #08314D;
      color: var(--light);
      display: flex;
      justify-content: center;
      align-items: center;
      box-shadow: 0 0 20px 0 rgba(0, 0, 0, 0.2), 0 5px 5px 0 rgba(0, 0, 0, 0.24);
      font-size: 1rem;
      border-radius: 5px;
    }

    .info__item a {
      color: var(--light);
    }

    .settings {
      max-width: 1200px;
      margin: 0 auto;
      padding: 1rem;
      display: flex;
      gap: 0.5rem;
      flex-direction: column;
      justify-content: center;
      align-items: center;
    }

    .settings>* {
      margin: 0;
    }

    .settings form {
      display: flex;
      flex-wrap: wrap;
      gap: 1rem;
    }


    .php-my-admin__link {
      display: inline-block;
      padding: 1rem;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .php-my-admin__link>* {
      margin: 0 0.2rem;
    }

    .header__item {
      margin: 0;
      padding: 1rem;
    }

    .header--logo {
      height: 8rem;
    }

    .project__ul {
      margin: 0;
      padding: 0;
      list-style: none;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      grid-gap: 1rem;
    }

    .project__li {
      display: block;
      background-color: var(--light);
      padding: 0.5rem;
      font-size: 0.8rem;
      border-radius: 5px;
    }

    .project__link {
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 0.5rem;
    }

    .project__link>* {
      margin: 0 0.4rem;
    }

    .no-project {
      margin: 0 auto;
      text-align: center;
      max-width: 1200px;
    }

    .btn {
      display: inline-block;
      background-color: var(--theme0);
      color: var(--light);
      padding: 0.5rem 1rem;
      transition: 300ms;
      border-radius: 5px;
    }

    .btn:hover {
      background-color: var(--theme0);
      color: var(--light);
      padding: 0.5rem 1rem;
      background-color: var(--theme1--hover);
    }

    .time {
      position: absolute;
      top: 1rem;
      right: 1rem;
      opacity: 0.5;
    }
  </style>
</head>

<body>
  <time class="time"></time>
  <main>
    <header>
      <div class="header__title">
        <img class="header__item header--logo" src="https://i.imgur.com/ky9oqct.png" alt="Offline">
        <h1 class="header__item header--title" title="Laragon">Laragon</h1>
      </div>
      <div class="header__description">
        <p>Modern & Powerful - Easy Operation Productive. Portable. Fast. Effective. Awesome!</p>
      </div>
      <div class="header__links">
        <p>
          <a class="btn" title="Getting Started" href="https://laragon.org/docs" target="_blank"><i class="fa-solid fa-book"></i> Documentation</a>
          <a class="btn" title="Getting Started" href="https://github.com/leokhoa/laragon" target="_blank"><i class="fa-brands fa-github"></i> Github</a>
        </p>
      </div>
    </header>

    <div class="info">
      <div class="info__item">
        <p class="info__text">
          <?php print($_SERVER['SERVER_SOFTWARE']); ?>
        </p>
      </div>
      <a class="info__item" title="phpinfo()" href="/?q=info">
        <p>
          PHP version: <?php print phpversion(); ?> <span>info</span>
        </p>
      </a>
      <div class="info__item">
        <p>
          Document Root:<br><strong><?php print($_SERVER['DOCUMENT_ROOT']); ?></strong>
        </p>
      </div>
      <?php
      $phpMyAdmin = 'http://localhost/phpmyadmin/';
      $file_headers = @get_headers($phpMyAdmin);
      if (!$file_headers || $file_headers[0] == 'HTTP/1.1 404 Not Found') :
        $exists = false;
      ?>
        <div class="info__item">
          <p class="alert">There is no phpMyAdmin installed</p>
        </div>
      <?php
      else :
        $exists = true;
      ?>
        <!-- ANCHOR Lien vers phpMyAdmin  -->
        <a class="info__item" href="<?php echo $phpMyAdmin; ?>" target="_blank">
          <p class="php-my-admin">phpmyadmin</p>
        </a>
      <?php
      endif;
      ?>
    </div>
    <div class="settings">
      <form action="#" method="post">
        <div class="settings__item">
          <label for="protocol">Choose protocol:</label>
          <select name="protocol" id="protocol">
            <option value="http" <?php echo ($protocol === 'http') ? 'selected' : ''; ?>>HTTP</option>
            <option value="https" <?php echo ($protocol === 'https') ? 'selected' : ''; ?>>HTTPS</option>
          </select>
        </div>
        <div class="settings__item">
          <label for="top_lvl_domain">Top-level domain:</label>
          <input type="text" name="top_lvl_domain" id="top_lvl_domain" value="<?php echo htmlspecialchars($top_lvl_domain); ?>">
        </div>
        <button type="submit">Update Settings</button>
      </form>
      <p><small><em>Select the protocol and domain to match Laragon settings.</em></small></p>
    </div>
  </main>
  <div class="main-container">
    <?php
    // 
    $dirList = glob('*', GLOB_ONLYDIR);
    usort($dirList, function ($a, $b) {
      return filemtime($b) - filemtime($a);
    });

    if ($dirList != NULL) :
    ?>
      <nav class="project">
        <ul class="project__ul">
          <?php

          foreach ($dirList as $key => $value) :
            $link1 = strtolower($protocol . '://' . $value . $top_lvl_domain);
            $link2 = strtolower($value);
            $lastModifiedTime = date("d-m-Y H:i", filemtime($value));
            if ($value !== '_images') :

          ?>
              <li class="project__li">
                <div>
                  <a class="project__link" href="<?php echo $link1; ?>" target="_blank">
                    <?php echo $link1; ?> <i class="fas fa-external-link-alt"></i>
                  </a>
                </div>
                <div>
                  <span>Last modified: <?php echo $lastModifiedTime; ?></span>
                </div>
                <div>
                  <a class="project__link" href="<?php echo $link2; ?>" target="_blank">
                    <small><?php echo 'localhost/' . $link2; ?></small>
                  </a>
                </div>
              </li>
          <?php
            endif;
          endforeach;
          ?>
        </ul>
      </nav>
    <?php
    else :
    ?>
      <div class="no-project">
        <p class="alert">There are no directories, create your first project now</p>
        <div>
          <img src="https://i.imgur.com/3Sgu8XI.png" alt="Offline">
        </div>
      </div>
    <?php
    endif;
    ?>

  </div>
  <script>
    const timeElement = document.querySelector('.time');

    function displayTime() {
      const now = new Date();
      const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
      const formattedDate = now.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
        timeZone: timeZone
      });

      timeElement.innerText = formattedDate;
      timeElement.setAttribute('datetime', now.toISOString());
    }

    setInterval(displayTime, 1000);
    displayTime();
  </script>
</body>

</html>