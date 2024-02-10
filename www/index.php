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
<html lang="en">

<head>
  <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to Laragon !</title>
  <link href="https://fonts.googleapis.com/css?family=Karla:400" rel="stylesheet" type="text/css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/css/bootstrap.min.css" integrity="sha512-b2QcS5SsA8tZodcDtGRELiGv5SaKSk1vDHDaQRda0htPYWZ6046lr3kJ5bAAQdpV2mmA/4v0wQF9MyU6/pDIAg==" crossorigin="anonymous" referrerpolicy="no-referrer" />
  <link rel="shortcut icon" href="https://i.imgur.com/ky9oqct.png" type="image/png">
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
        font-family: 'Karla', sans-serif;
      font-size: 18px;
    }

    header,
    main,
    nav,
    aside {
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
      text-decoration: none;
    }

    a:hover {
      color: red;
      font-weight: 900;
      transition: 300ms;
    }

    main a {
      color: grey;
    }

    nav a {
      display: block;
      margin: 1rem 0;
    }

    nav a:after {
      content: '→';
      margin-left: 0.5rem;
    }

    .alert {
      color: red;
      font-weight: 900;
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
    <img class="header__item header--logo" src="https://i.imgur.com/ky9oqct.png" alt="Offline">
    <h1 class="header__item header--title" title="Laragon">Laragon</h1>
  </header>
    <main>
    <h4>
     Congratulations, you have successfully installed Laragon!
    </h4>
    <p>
      Now you can create a new project with Laragon. Or you can also install several additional packages to support your project.
    </p>
  </main>
  <main>
    <p>
      <?php print($_SERVER['SERVER_SOFTWARE']); ?>
    </p>
    <p>
      PHP version: <?php print PHP_VERSION; ?> <span><a title="phpinfo()" href="/?q=info">info</a></span>
    </p>
    <p>
      Document Root: <?php print($_SERVER['DOCUMENT_ROOT']); ?>
    </p>
    <p>
      <a title="Getting Started" href="https://laragon.org/docs">Getting Started</a>
    </p>
    <p>
      <a title="Forum" href="https://github.com/leokhoa/laragon/discussions">Forum</a>
    </p>
  </main>
  <?php
  $dirList = glob('*', GLOB_ONLYDIR);
  if (!empty($dirList)) :  
  ?>
    <nav>
      <h4>Your Project</h4>
      <ul>
        <?php
        foreach ($dirList as $key => $value) :
          $link = 'https://' . $value . '.test';
        ?>
          <a href="<?php echo $link; ?>" target="_blank"><?php echo $link; ?></a>
        <?php
        endforeach;
        ?>
      </ul>
    </nav>
  <?php
  else :
  ?>
    <aside>
      <p class="alert">There are no directories, create your first project now</p>
      <div>
        <img src="https://i.imgur.com/3Sgu8XI.png" alt="Offline">
      </div>
    </aside>
  <?php
  endif;
  ?>
</body>

</html>