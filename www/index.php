<?php
if (!empty($_GET['q'])) {
  switch ($_GET['q']) {
    case 'info':
      phpinfo();
      exit;
      break;
  }
}
?>
<!DOCTYPE html>
<html>

<head>
  <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Laragon</title>
  <link href="https://fonts.googleapis.com/css?family=Karla:400" rel="stylesheet" type="text/css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.1/css/all.min.css" integrity="sha512-+4zCK9k+qNFUR5X+cKL9EIR+ZOhtIloNl9GIKS57V1MyNsYpYcUrUeQc9vNfzsWfV28IaLL3i96P9sdNyeRssA==" crossorigin="anonymous" />
  <style>
    *,
    :before *,
    :after * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      min-height: 100vh;
      font-weight: 100;
      font-family: 'Karla';
      font-size: 18px;
    }

    header,
    main,
    nav {
      padding: 1rem;
      margin: auto;
      max-width: 1200px;
      text-align: center;
    }

    header {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      align-items: center;
    }

    .header__item {
      margin: 0;
      padding: 1rem;
    }

    .header--logo {
      height: 8rem;
    }

    h1 {
      font-size: 5rem;
    }

    main {
      background-color: #f5f5f5;
    }

    nav {
      width: 100%;
    }

    ul {
      list-style: none;
      padding: 0;
      margin: auto;
    }

    a {
      color: #37ADFF;
      font-weight: 900;
    }

    a:hover {
      color: red;
    }

    a:after {
      font-family: 'Font Awesome 5 Free';
      font-weight: 900;
      margin-left: 1rem;
      content: '\f35d';
    }

    main a {
      color: grey;
    }

    nav a {
      display: block;
      margin: 1rem 0;
    }

    @media (min-width: 650px) {
      h1 {
        font-size: 10rem;
      }
    }
  </style>
</head>

<body>
  <header>
    <img class="header__item header--logo" src="https://i.imgur.com/ky9oqct.png" alt="Laragon logo">
    <h1 class="header__item header--title" title="Laragon">Laragon</h1>
  </header>
  <main>
    <p>
      <?php print($_SERVER['SERVER_SOFTWARE']); ?>
    </p>
    <p>
      PHP version: <?php print phpversion(); ?> <span><a title="phpinfo()" href="/?q=info">info</a></span>
    </p>
    <p>
      Document Root: <?php print($_SERVER['DOCUMENT_ROOT']); ?>
    </p>
    <p>
      <a title="Getting Started" href="https://laragon.org/docs">Getting Started</a>
    </p>
  </main>
  <nav>
    <ul>
      <?php
      $variable = scandir('.');
      foreach ($variable as $key => $value) :
        if ($value != 'desktop.ini' && $value != '.' && $value != '..') :
          $link = 'https://' . $value . '.test';
      ?>
          <a href="<?php echo $link; ?>" target="_blank"><?php echo $link; ?></a>
      <?php
        endif;
      endforeach;
      ?>
    </ul>
  </nav>
</body>

</html>
