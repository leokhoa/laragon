<?php
if (!empty($_GET['q']) && $_GET['q'] === 'info') {
    phpinfo();
    exit;
}

function getPrettyDomain()
{
    $iniContents = file_get_contents(__DIR__ . '/../usr/laragon.ini');
    if (!$iniContents) {
        return 'test';
    }
    preg_match('/HostnameFormat=\{name\}\.(.*?)\s/', $iniContents, $hostnameFormat);
    return $hostnameFormat ? $hostnameFormat[1] : 'test';
}

$dirList = glob('*', GLOB_ONLYDIR);

$prettyDomain = getPrettyDomain();

?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laragon</title>
    <link href="https://fonts.googleapis.com/css?family=Karla:400" rel="stylesheet" type="text/css">
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
            color: #6f6f6f;
            font-weight: 900;
            text-decoration: none;
        }

        a:hover {
            color: red;
            font-weight: 900;
            transition: 300ms;
        }

        nav a {
            display: block;
            margin: 0.5rem 0;
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
    <p>
        <?= $_SERVER['SERVER_SOFTWARE'] ?>
    </p>
    <p>
        PHP version: <?= PHP_VERSION ?> <span><a title="phpinfo()" href="/?q=info">info</a></span>
    </p>
    <p>
        Document Root: <?= $_SERVER['DOCUMENT_ROOT'] ?>
    </p>
    <p>
        <a title="Getting Started" href="https://laragon.org/docs" target="_blank">Getting Started</a>
    </p>
    <?php
    if (!empty($dirList)) :
        ?>
        <nav>
            <ul>
                <?php
                foreach ($dirList as $key => $value) :
                    $link = $_SERVER['REQUEST_SCHEME'] . '://' . $value . '.' . $prettyDomain;
                    ?>
                    <li>
                        <a href="<?= $link ?>" target="_blank"><?= $value ?></a>
                    </li>
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
</main>
</body>

</html>