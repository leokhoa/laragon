<?php

/**
 * Application: Laragon | Server Index Page
 * Description: This is the main index page for the Laragon server, displaying server info, server vitals, sendmail
 * mailbox and applications Author: Tarek Tarabichi <tarek@2tinteractive.com> Contributors: @LrkDev in v.2.1.2
 * improved CakePHP and Joomla detection Contributors: @luisAntonioLAGS in v.2.2.1 Spanish Language Version: 2.3.0
 */

//-----------------------------------------------------------------------------------
// Load language files
//-----------------------------------------------------------------------------------
function loadLanguage($lang)
{
	$langFile = __DIR__ . "/assets/languages/{$lang}.json";
	if (file_exists($langFile)) {
		return json_decode(file_get_contents($langFile), true);
	}
	return [];
}

//-----------------------------------------------------------------------------------
// Detect language preference (example: default to English)
//-----------------------------------------------------------------------------------
$lang = isset($_GET['lang']) ? $_GET['lang'] : 'en';
$translations = loadLanguage($lang);

const SERVER_TYPES = [
	'php' => 'php',
	'apache' => 'apache',
];
//-----------------------------------------------------------------------------------
// Displays server status including uptime, memory usage, and disk usage.
//-----------------------------------------------------------------------------------
function showServerStatus(): void
{
	echo '<h1>Server Status</h1>';
	// Display server uptime
	$uptime = shell_exec('uptime');
	echo '<h2>Uptime</h2>';
	echo '<p>' . htmlspecialchars($uptime) . '</p>';

	// Display memory usage
	$free = shell_exec('free -m'); // memory in MB
	echo '<h2>Memory Usage (in MB)</h2>';
	echo '<pre>' . htmlspecialchars($free) . '</pre>';

	// Display disk usage
	$df = shell_exec('df -h'); // disk usage in human-readable format
	echo '<h2>Disk Usage</h2>';
	echo '<pre>' . htmlspecialchars($df) . '</pre>';
}

//-----------------------------------------------------------------------------------
// Handles incoming query parameters and executes corresponding functionality.
//-----------------------------------------------------------------------------------
function handleQueryParameter(string $param): void
{
	switch ($param) {
		case 'info':
			phpinfo();
			break;
		case 'status':
			showServerStatus();
			break;
		default:
			throw new InvalidArgumentException("Unsupported parameter: " . htmlspecialchars($param));
	}
}

// Check if 'q' parameter is set and sanitize it
if (isset($_GET['q'])) {
	$queryParam = filter_input(INPUT_GET, 'q', FILTER_SANITIZE_STRING);
	try {
		handleQueryParameter($queryParam);
	} catch (InvalidArgumentException $e) {
		echo 'Error: ' . htmlspecialchars($e->getMessage());
	}
}

const SERVER_PHP = 'php';
const SERVER_APACHE = 'apache';
//-----------------------------------------------------------------------------------
// Retrieves a list of PHP extensions or Apache modules based on the specified server type.
//-----------------------------------------------------------------------------------
function getServerExtensions(string $server, int $columns = 2): array
{
	switch ($server) {
		case SERVER_PHP:
			$extensions = get_loaded_extensions();
			break;
		case SERVER_APACHE:
			if (function_exists('apache_get_modules')) {
				$extensions = apache_get_modules();
			} else {
				throw new Exception('Apache modules are not available on this server.');
			}
			break;
		default:
			throw new InvalidArgumentException('Invalid server name: ' . htmlspecialchars($server));
	}

	sort($extensions, SORT_STRING);
	$extensions = array_chunk($extensions, $columns);

	return $extensions;
}

//-----------------------------------------------------------------------------------
// Fetches the latest PHP version from the official PHP website and compares it with the current PHP version running on the server.
//-----------------------------------------------------------------------------------
function getPhpVersion(): array
{
	$url = 'https://www.php.net/releases/index.php?json&version=7';
	$options = [
		"ssl" => [
			"verify_peer" => false,
			"verify_peer_name" => false,
		],
	];
	$json = file_get_contents($url, false, stream_context_create($options));
	if ($json === false) {
		throw new Exception("Unable to retrieve PHP version info from the official PHP site.");
	}

	$data = json_decode($json, true);
	if ($data === null || !isset($data['version'])) {
		throw new Exception("Invalid JSON or 'version' missing in the data.");
	}

	$lastVersion = $data['version'];
	$currentVersion = phpversion();

	return [
		'lastVersion' => htmlspecialchars($lastVersion),
		'currentVersion' => htmlspecialchars($currentVersion),
		'isUpToDate' => version_compare($currentVersion, $lastVersion, '>='),
	];
}

//-----------------------------------------------------------------------------------
// Ensure $serverInfo is defined and initialized with serverInfo() function call
//-----------------------------------------------------------------------------------
$serverInfo = serverInfo(); // Make sure this line is placed before you try to access $serverInfo

// Before accessing an array offset, check if the variable is an array and not null
if (is_array($serverInfo) && isset($serverInfo['httpdVer'])) {
	//echo $serverInfo['httpdVer']; // Safely access the 'httpdVer' index
} else {
	// Handle the case where $serverInfo is not an array or the index 'httpdVer' is not set
	echo "Server information is not available.";
}

//-----------------------------------------------------------------------------------
// Gathers information about the server environment including versions of HTTP server, OpenSSL, PHP, and Xdebug, as well as document root and server name.
//-----------------------------------------------------------------------------------
function serverInfo(): array
{
	$serverSoftware = $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown Server Software';
	$serverParts = explode(' ', $serverSoftware);

	$httpdVer = $serverParts[0] ?? 'Unknown';
	$openSslVer = isset($serverParts[2]) && strpos($serverParts[2], 'OpenSSL/') === 0 ? substr($serverParts[2], 8) : 'Not available';

	$phpInfo = getPhpVersion();
	$xdebugVersion = extension_loaded('xdebug') ? phpversion('xdebug') : 'Not installed';

	return [
		'httpdVer' => htmlspecialchars($httpdVer),
		'openSsl' => htmlspecialchars($openSslVer),
		'phpVer' => htmlspecialchars($phpInfo['currentVersion']),
		'xDebug' => htmlspecialchars($xdebugVersion),
		'docRoot' => htmlspecialchars($_SERVER['DOCUMENT_ROOT'] ?? '/var/www/html'),
		'serverName' => htmlspecialchars($_SERVER['HTTP_HOST'] ?? 'localhost'),
	];
}

//-----------------------------------------------------------------------------------
// Retrieves the MySQL version by executing a shell command.
//-----------------------------------------------------------------------------------
function getSQLVersion(): string
{
	$output = shell_exec('mysql -V');
	if ($output === null) {
		return "Unknown"; // Command failed to execute, possibly not installed or not in PATH
	}

	if (preg_match('@[0-9]+\.[0-9]+\.[0-9-\w]+@', $output, $version)) {
		return htmlspecialchars($version[0]);
	}

	return "Unknown";
}

//-----------------------------------------------------------------------------------
// Generates download and changelog links for a specific PHP version.
//-----------------------------------------------------------------------------------
function phpDlLink(string $version, string $branch = '7', string $architecture = 'x64'): array
{
	$versionEscaped = htmlspecialchars($version, ENT_QUOTES, 'UTF-8');
	$branchEscaped = htmlspecialchars($branch, ENT_QUOTES, 'UTF-8');
	$architectureEscaped = htmlspecialchars($architecture, ENT_QUOTES, 'UTF-8');

	return [
		'changeLog' => "https://www.php.net/ChangeLog-$branchEscaped.php#$versionEscaped",
		'downLink' => "https://windows.php.net/downloads/releases/php-$versionEscaped-Win32-VC15-$architectureEscaped.zip",
	];
}

//-----------------------------------------------------------------------------------
// Determines the directory path for server-specific site configuration based on the server software.
//-----------------------------------------------------------------------------------
function getSiteDir(): string
{
	// Check if laragon is installed on C or D drive and this then checks whichever works and uses it
	// so it would be $rootDir = 'C:/laragon/etc/apache2/sites-enabled'; or $rootDir = 'D:/laragon/etc/apache2/sites-enabled';
	$drive = strtoupper(substr(PHP_OS, 0, 1));
	$rootDir = $drive . ':/laragon/etc/apache2/sites-enabled';
	if (strpos(strtolower($rootDir), 'c:') !== false) {
		$laragonDir = str_replace('D:', 'C:', $rootDir);
	} else {
		$laragonDir = $rootDir;
	}
	$rootDir = 'D:/laragon/etc/apache2/sites-enabled';

	if ($rootDir === false) {
		throw new RuntimeException("Unable to determine the root directory.");
	}

	// Ensures that SERVER_SOFTWARE is set and not empty
	if (!isset($_SERVER['SERVER_SOFTWARE']) || trim($_SERVER['SERVER_SOFTWARE']) === '') {
		throw new InvalidArgumentException("Server software is not defined in the server environment.");
	}

	$serverSoftware = strtolower($_SERVER['SERVER_SOFTWARE']);

	if (strpos($serverSoftware, 'apache') !== false) {
		return $rootDir;
	} elseif (strpos($serverSoftware, 'nginx') !== false) {
		return $rootDir; // Adjust this if needed
	}

	throw new InvalidArgumentException("Unsupported server type: " . htmlspecialchars($serverSoftware));
}

//-----------------------------------------------------------------------------------
// Fetches configuration details for local sites based on server configuration files.
//-----------------------------------------------------------------------------------
function getLocalSites($server = 'apache', $ignoredFiles = ['.', '..', '00-default.conf']): array
{
	try {
		$sitesDir = getSiteDir(); // Assume getSiteDir() throws an exception if unable to determine the directory
		$files = scandir($sitesDir);
		if ($files === false) {
			throw new Exception("Failed to scan directory: " . htmlspecialchars($sitesDir));
		}
	} catch (Exception $e) {
		error_log($e->getMessage()); // Log the error to PHP's error log
		return []; // Return an empty array to indicate failure gracefully
	}

	$scanDir = array_diff($files, $ignoredFiles);
	$sites = [];

	foreach ($scanDir as $filename) {
		$path = realpath("$sitesDir/$filename");
		if ($path === false || !is_file($path)) {
			continue; // Skip invalid paths or directories
		}

		$config = file_get_contents($path);
		if ($config === false) {
			continue; // Skip files that can't be read
		}

		if (
			preg_match('/^\s*ServerName\s+(.+)$/m', $config, $domainMatches) &&
			preg_match('/^\s*DocumentRoot\s+(.+)$/m', $config, $documentRootMatches)
		) {
			$sites[] = [
				'filename' => htmlspecialchars($filename),
				'path' => htmlspecialchars($path),
				'domain' => htmlspecialchars(str_replace(['auto.', '.conf'], '', $domainMatches[1])),
				'documentRoot' => htmlspecialchars($documentRootMatches[1]),
			];
		}
	}

	return $sites;
}

//--------------------------------------------------------
// Renders HTML links for local sites with XSS prevention.
//--------------------------------------------------------
function renderLinks(): string
{
	ob_start();
	$sites = getLocalSites();

	foreach ($sites as $site) {
		$httpLink = "http://" . htmlspecialchars($site['domain'], ENT_QUOTES, 'UTF-8');
		$httpsLink = "https://" . htmlspecialchars($site['domain'], ENT_QUOTES, 'UTF-8');

		echo "<div class='row w800 my-2'>";
		echo "<div class='col-md-5 text-truncate tr'><a href='" . $httpLink . "'>" . $httpLink . "</a></div>";
		echo "<div class='col-2 arrows'>&xlArr; &sext; &xrArr;</div>";
		echo "<div class='col-md-5 text-truncate tl'><a href='" . $httpsLink . "'>" . $httpsLink . "</a></div>";
		echo "</div><hr>";
	}

	return ob_get_clean();
}

$rootPath = realpath(__DIR__);
$folders = array_filter(glob($rootPath . '/*'), 'is_dir');
$ignore_dirs = array('.', '..', 'logs', 'access-logs', 'vendor', 'favicon_io', 'ablepro-90', 'assets');

foreach ($folders as $folderPath) {
	$host = basename($folderPath);
	if (in_array($host, $ignore_dirs)) {
		continue; // Skip ignored directories
	}
}

// defaults and opens servers tab as default view on initialisation
$activeTab = isset($_GET['tab']) ? $_GET['tab'] : 'servers';

?>
<!DOCTYPE html>
<html lang="<?php echo $lang; ?>">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="icon" type="image/x-icon" href="assets/favicon.ico">
    <title><?php echo $translations['title'] ?? 'Welcome to the Laragon Dashboard'; ?></title>

    <link href="https://fonts.googleapis.com/css?family=Pt+Sans&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Poppins:300,400,500,700&display=swap">
    <link rel="stylesheet" href="assets/style.css">

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap-grid.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap-reboot.min.css" />

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/brands.min.css" />

    <!----- Javascript Library over CDN -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/js/bootstrap.min.js"></script>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/all.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/js/fontawesome.min.js"></script>

    <!--- Chart.js v4.4.3 CDN----->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
		
		<!--- Favicon -------->
	<link rel="icon" href="assets/favicon/favicon.ico" type="image/x-icon">
	<link rel="icon" type="image/png" href="assets/favicon/favicon-16x16.png" sizes="16x16">
	<link rel="icon" type="image/png" href="assets/favicon/favicon-32x32.png" sizes="32x32">
	<link rel="icon" type="image/png" href="assets/favicon/android-chrome-192x192.png" sizes="192x192">
	<link rel="icon" type="image/png" href="assets/favicon/android-chrome-512x512.png" sizes="512x512">
	<link rel="icon" type="apple-touch-icon" href="assets/favicon/apple-touch-icon.png">
	<link rel="manifest" href="assets/favicon/site.webmanifest">
	
	
	<script>
    $(document).ready(function() {
        $('.tab').click(function() {
            var tab_id = $(this).attr('data-tab');

            $('.tab').removeClass('active');
            $('.tab-content').removeClass('active');

            $(this).addClass('active');
            $("#" + tab_id).addClass('active');
        });

        $('#language-selector').change(function() {
            var lang = $(this).val();
            window.location.href = "?lang=" + lang;
        });
    });
    </script>
    <style>
    /*----------------------------------------*/
    /* ===== Scrollbar CSS ===== */
    /*----------------------------------------*/
    /* Firefox */
    * {
        scrollbar-width: auto;
        scrollbar-color: #ec1c7e #ffffff;
    }

    /* Chrome, Edge, and Safari */
    *::-webkit-scrollbar {
        width: 16px;
    }

    *::-webkit-scrollbar-track {
        background: #ffffff;
    }

    *::-webkit-scrollbar-thumb {
        background-color: #ec1c7e;
        border-radius: 10px;
        border: 3px solid #ffffff;
    }

    /*---------------------------*/
    /* Main Page Container Styling */
    /*---------------------------*/
    .grid-container {
        grid-area: main;
        background: url(assets/background2.jpg) no-repeat center center fixed;
        -webkit-background-size: cover;
        -moz-background-size: cover;
        -o-background-size: cover;
        background-size: cover;
    }

    /*---------------------------*/
    /* Navigation Styling */
    /*---------------------------*/
    nav {
        grid-area: nav;
        align-items: start;
        justify-content: space-between;
        padding: 0 20px;
        background-color: #0B162C !important;
        color: #ffffff !important;
        font-family: "Poppins", Sans-serif, serif !important;
    }

    /*---------------------------*/
    /* Tabs Styling */
    /*---------------------------*/
    .tab {
        align-items: center;
        background-color: #0A66C2;
        border: 0;
        border-radius: 100px;
        box-sizing: border-box;
        color: #ffffff;
        cursor: pointer;
        display: inline-flex;
        font-family: "Poppins", Sans-serif, serif !important;
        font-size: 16px;
        font-weight: 600;
        justify-content: center;
        line-height: 20px;
        max-width: 480px;
        min-height: 40px;
        min-width: 0;
        overflow: hidden;
        padding: 0 20px;
        text-align: center;
        touch-action: manipulation;
        transition: background-color 0.167s cubic-bezier(0.4, 0, 0.2, 1) 0s, box-shadow 0.167s cubic-bezier(0.4, 0, 0.2, 1) 0s, color 0.167s cubic-bezier(0.4, 0, 0.2, 1) 0s;
        user-select: none;
        -webkit-user-select: none;
        vertical-align: middle;
    }

    .tab:hover,
    .tab:focus,
        {
        background-color: #16437E;
        color: #ffffff;

    }

    .tab:disabled {
        cursor: not-allowed;
        background: rgba(0, 0, 0, .08);
        color: rgba(0, 0, 0, .3);
    }

    .tab.active {
        background: #09223b;
        color: rgb(255, 255, 255, .7);
    }

    .tab-content {
        display: none;
    }

    .tab-content.active {
        display: block;
    }

    /*---------------------------*/
    /* Language Selector Styling */
    /*---------------------------*/
    select#language-selector {
        background-color: #fff;
        padding: 5px;
        border-radius: 25px;
        border: 1px solid #ccc;
    }

    .main-overview {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(265px, 1fr));
        grid-auto-rows: 71px;
        grid-gap: 20px;
        margin: 10px;
    }


    .wrapper {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 10px;
    }

    /*----------------------------------------*/
    /*-------OVERVIEW CARDS--------------*/
    /*----------------------------------------*/
    .overviewcard {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 15px;
        background-color: #00adef;
        font-family: "Rubik", Sans-serif, serif;
        border-radius: 5px 5px;
        font-size: 16px;
        color: #FFFFFF !important;
        line-height: 1;
        height: 31px;
    }

    .overviewcard_sites {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 15px;
        background-color: #023e8a;
        /*-----00adef    -----*/
        font-family: "Rubik", Sans-serif, serif;
        border-radius: 5px 5px;
        font-size: 16px;
        color: #FFFFFF !important;
        line-height: 1;
        height: 31px;
    }

    .overviewcard_info {
        font-family: "Rubik", Sans-serif, serif;
        text-transform: uppercase;
        font-size: 16px !important;
        color: #FFFFFF !important;
    }

    .overviewcard_icon {
        font-family: "Rubik", Sans-serif, serif;
        text-transform: uppercase;
        font-size: 16px !important;
        color: #FFFFFF !important;
    }


    .overviewcard4 {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 15px;
        background-color: #031A24;
        /*-----00adef    -----*/
        font-family: "Rubik", Sans-serif, serif;
        border-radius: 5px 5px;
        font-size: 16px;
        color: #FFFFFF !important;
        line-height: 1;
        height: 31px;
    }

    /*----------------------------------------*/
    /*------CARDS STYLING----------*/
    /*----------------------------------------*/
    .main-cards {
        column-count: 0;
        column-gap: 20px;
        margin: 20px;
    }

    .card {
        display: flex;
        flex-direction: column;
        align-items: center;
        width: 100%;
        background-color: #f1faee;
        margin-bottom: 20px;
        -webkit-column-break-inside: avoid;
        padding: 24px;
        box-sizing: border-box;
    }

    /* Force varying heights to simulate dynamic content */
    .card:first-child {
        height: 300px;
    }

    .card:nth-child(2) {
        height: 200px;
    }

    .card:nth-child(3) {
        height: 265px;
    }

    /*----------------------------------------*/
    /*Image Filter styles*/
    /*----------------------------------------*/
    .saturate {
        filter: saturate(3);
    }

    .grayscale {
        filter: grayscale(100%);
    }

    .contrast {
        filter: contrast(160%);
    }

    .brightness {
        filter: brightness(0.25);
    }

    .blur {
        filter: blur(3px);
    }

    .invert {
        filter: invert(100%);
    }

    .sepia {
        filter: sepia(100%);
    }

    .huerotate {
        filter: hue-rotate(180deg);
    }

    .rss.opacity {
        filter: opacity(50%);
    }

    /*----------------------------------------*/
    /*-- Sites Styling -----*/
    /*----------------------------------------*/
    .sites {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(275px, 1fr));
        grid-gap: 20px;
        margin: 20px;
    }

    .sites li {
        display: flex;
        flex-direction: column;
        align-items: center;
        width: 100%;
        background: #560bad;
        color: #ffffff;
        font-family: 'Rubik', sans-serif;
        font-size: 14px;
        text-align: left;
        text-transform: uppercase;
        margin-bottom: 20px;
        -webkit-column-break-inside: avoid;
        padding: 24px;
        box-sizing: border-box;
    }


    .sites li:hover {
        box-shadow: 0 0 15px 0 #bbb;
    }

    .sites li:hover svg {
        fill: #ffffff;
    }

    .sites li:hover a {
        color: #ffffff;
    }

    .sites li a {
        display: block;
        padding-left: 48px;
        color: #f2f2f2;
        transition: color 250ms ease-in-out;
    }

    .sites img {
        position: absolute;
        margin: 8px 8px 8px -40px;
        fill: #f2f2f2;
        transition: fill 250ms ease-in-out;
    }

    .sites svg {
        position: absolute;
        margin: 16px 16px 16px -40px;
        fill: #f2f2f2;
        transition: fill 250ms ease-in-out;
    }
    </style>
</head>

<body>
    <header class="header">
        <h4><?php echo $translations['header'] ?? 'Header'; ?></h4>

        <?php
        // Get the current time
        $currentTime = new DateTime();
        $hours = $currentTime->format('H');

        // Get the greeting based on the time of day
        if ($hours < 12) {
            $greeting = $translations['good_morning'] ?? 'Good morning';
        } elseif ($hours < 18) {
            $greeting = $translations['good_afternoon'] ?? 'Good afternoon';
        } else {
            $greeting = $translations['good_evening'] ?? 'Good evening';
        }

        // Display the greeting
        echo "<h4>" . $greeting . "!</h4>";
        ?>

        <div>
            <select id="language-selector">
                <?php
                $langFiles = glob(__DIR__ . "/assets/languages/*.json");
                foreach ($langFiles as $file) {
                    $langCode = basename($file, ".json");
                    $selected = $lang === $langCode ? "selected" : "";
                    echo "<option value='$langCode' $selected>$langCode</option>";
                }
                ?>
            </select>
        </div>
    </header>
    <nav>
        <div class="tab <?php echo $activeTab === 'servers' ? 'active' : ''; ?>" data-tab="servers"><?php echo $translations['servers_tab'] ?? 'Servers'; ?></div>
        <div class="tab <?php echo $activeTab === 'mailbox' ? 'active' : ''; ?>" data-tab="mailbox"><?php echo $translations['inbox_tab'] ?? 'Mailbox'; ?></div>
        <div class="tab <?php echo $activeTab === 'vitals' ? 'active' : ''; ?>" data-tab="vitals"><?php echo $translations['vitals_tab'] ?? 'Server Vitals'; ?></div>
    </nav>

    <!------- Main Container ------------->
    <div class="grid-container">

        <!--------------------------------------------->
        <!------ Servers Tab -------------------------->
        <!--------------------------------------------->
        <div class="tab-content <?php echo $activeTab === 'servers' ? 'active' : ''; ?>" id="servers">
            <header class="header">
                <div class="header__search"><?php echo $translations['breadcrumb_server_servers'] ?? 'My Development Server Servers & Applications'; ?></div>
                <div class="header__avatar"><?php echo $translations['welcome_back'] ?? 'Welcome Back!'; ?></div>
            </header>
            <div class="main-overview">
                <div class="overviewcard4">
                    <div class="overviewcard_icon"></div>
                    <div class="overviewcard_info"><img src="assets/Server.png" style="width:64px;"></div>
                </div>

                <div class="overviewcard">
                    <div class="overviewcard_icon"></div>
                    <div class="overviewcard_info">
                        <?php echo htmlspecialchars($_SERVER['SERVER_SOFTWARE']); ?>
                    </div>
                </div>
                <div class="overviewcard">
                    <div class="overviewcard_icon"></div>
                    <div class="overviewcard_info">
                        <?= $serverInfo['openSsl']; ?>
                    </div>
                </div>
                <div class="overviewcard">
                    <div class="overviewcard_icon">PHP</div>
                    <div class="overviewcard_info">
                        <?php echo htmlspecialchars(phpversion()); ?>
                    </div>
                </div>
            </div>
            <div class="main-overview">
                <div class="overviewcard">
                    <div class="overviewcard_icon">MySQL</div>
                    <div class="overviewcard_info">
                        <?php
                        error_reporting(0);
                        $laraconfig = parse_ini_file('../usr/laragon.ini');

                        $link = mysqli_connect('localhost', 'root', $laraconfig['MySQLRootPassword']);
                        if (!$link) {
                            $link = mysqli_connect('localhost', 'root', '');
                        }
                        if (!$link) {
                            echo 'MySQL not running!';
                        } else {
                            printf("server version: %s\n", htmlspecialchars(mysqli_get_server_info($link)));
                        }
                        ?>
                    </div>
                </div>

                <div class="overviewcard">
                    <div class="overviewcard_icon"><?php echo $translations['document_root'] ?? 'Document Root'; ?></div>
                    <div class="overviewcard_info">
                        <?php echo htmlspecialchars($_SERVER['DOCUMENT_ROOT']); ?><br>
                        <small><span><?php echo htmlspecialchars($_SERVER['HTTP_HOST']); ?></span></small>
                    </div>
                </div>

                <div class="overviewcard">
                    <div class="overviewcard_icon">PhpMyAdmin</div>
                    <div class="overviewcard_info">
                        <a href="http://localhost/phpmyadmin" target="_blank">
                            <?php echo $translations['manage_mysql'] ?? 'Manage MySQL'; ?>
                        </a>
                    </div>
                </div>

                <div class="overviewcard">
                    <div class="overviewcard_icon">
                        Laragon
                    </div>
                    <div class="overviewcard_info">
                        Full 6.0.220916
                    </div>
                </div>
            </div>

            <div class="main-overview wrapper">
                <?php
                $ignored = array('favicon_io');
                $folders = array_filter(glob('*'), 'is_dir');

                if ($laraconfig['SSLEnabled'] == 0 || $laraconfig['Port'] == 80) {
                    $url = 'http';
                } else {
                    $url = 'https';
                }
                $ignore_dirs = array('.', '..', 'logs', 'access-logs', 'vendor', 'favicon_io', 'ablepro-90', 'assets');
                foreach ($folders as $host) {
                    if (in_array($host, $ignore_dirs) || !is_dir($host)) {
                        continue;
                    }

                    $admin_link = '';
                    $app_name = '';
                    $avatar = '';

                    switch (true) {
                        case (file_exists($host . '/core') || file_exists($host . '/web/core')):
                            $app_name = ' Drupal ';
                            $avatar = 'assets/Drupal.svg';
                            $admin_link = '<a href="' . $url . '://' . htmlspecialchars($host) . '.local/user" target="_blank"><small style="font-size: 8px; color: #cccccc;">' . $app_name . '</small><br>Admin</a>';
                            break;
                        case file_exists($host . '/wp-admin'):
                            $app_name = ' Wordpress ';
                            $avatar = 'assets/Wordpress.png';
                            $admin_link = '<a href="' . $url . '://' . htmlspecialchars($host) . '.local/wp-admin" target="_blank"><small style="font-size: 8px; color: #cccccc;">' . $app_name . '</small><br>Admin</a>';
                            break;
                        case file_exists($host . '/administrator'):
                            $app_name = ' Joomla ';
                            $avatar = 'assets/Joomla.png';
                            $admin_link = '<a href="' . $url . '://' . htmlspecialchars($host) . '.local/administrator" target="_blank"><small style="font-size: 8px; color: #cccccc;">' . $app_name . '</small><br>Admin</a>';
                            break;
                        case file_exists($host . '/public/index.php') && is_dir($host . '/app') && file_exists($host . '/.env'):
                            $app_name = ' Laravel ';
                            $avatar = 'assets/Laravel.png';
                            $admin_link = '';
                            break;
                        case file_exists($host . '/bin/console'):
                            $app_name = ' Symfony ';
                            $avatar = 'assets/Symfony.png';
                            $admin_link = '<a href="' . $url . '://' . htmlspecialchars($host) . '.local/admin" target="_blank"><small style="font-size: 8px; color: #cccccc;">' . $app_name . '</small><br>Admin</a>';
                            break;
                        case (file_exists($host . '/') && is_dir($host . '/app.py') && is_dir($host . '/static') && file_exists($host . '/.env')):
                            $app_name = ' Python ';
                            $avatar = 'assets/Python.png';
                            $admin_link = '<a href="' . $url . '://' . htmlspecialchars($host) . '.local/Public" target="_blank"><small style="font-size: 8px; color: #cccccc;">' . $app_name . '</small><br>Public Folder</a>';

                            $command = 'python ' . htmlspecialchars($host) . '/app.py';
                            exec($command, $output, $returnStatus);
                            break;
                        case file_exists($host . '/bin/cake'):
                            $app_name = ' CakePHP ';
                            $avatar = 'assets/CakePHP.png';
                            $admin_link = '<a href="' . $url . '://' . htmlspecialchars($host) . '.local/admin" target="_blank"><small style="font-size: 8px; color: #cccccc;">' . $app_name . '</small><br>Admin</a>';
                            break;
                        default:
                            $admin_link = '';
                            $avatar = 'assets/Unknown.png';
                            break;
                    }

                    echo '<div class="overviewcard_sites"><div class="overviewcard_avatar"><img src="' . $avatar . '" style="width:20px; height:20px;"></div><div class="overviewcard_icon"><a href="' . $url . '://' . htmlspecialchars($host) . '.local">' . htmlspecialchars($host) . '</a></div><div class="overviewcard_info">' . $admin_link . '</div></div>';
                }
                ?>
            </div>
        </div>

        <!--------------------------------------------->
        <!------ Mailbox Tab -------------------------->
        <!--------------------------------------------->
        <div class="tab-content <?php echo $activeTab === 'mailbox' ? 'active' : ''; ?>" id="mailbox">
            <header class="header">
                <div class="header__search"><?php echo $translations['breadcrumb_server_mailbox'] ?? 'My Development Server Mailbox'; ?></div>
                <div class="header__avatar"><?php echo $translations['welcome_back'] ?? 'Welcome Back!'; ?></div>
            </header>
            <?php include 'assets/inbox/inbox.php'; ?>
        </div>

        <!--------------------------------------------->
        <!------ Server's Vitals Tab -------------------------->
        <!--------------------------------------------->
        <div class="tab-content <?php echo $activeTab === 'vitals' ? 'active' : ''; ?>" id="vitals">
            <header class="header">
                <div class="header__search"><?php echo $translations['breadcrumb_server_vitals'] ?? 'My Development Server Vitals'; ?></div>
                <div class="header__avatar"><?php echo $translations['welcome_back'] ?? 'Welcome Back'; ?></div>
            </header>
            <div class="container mt-5" style="width: 1440px!important;background-color: #f8f9fa;padding: 20px;border-radius: 5px;color=#000000">
                <h1 style="text-align: center;color: #000000">Server's Vitals</h1>

                <div class="row">

                    <div class="col-md-6">
                        <h2><?php echo $translations['uptime'] ?? 'Uptime'; ?></h2>
                        <p><?php echo htmlspecialchars(shell_exec('uptime')); ?></p>
                        <canvas id="uptimeChart"></canvas>
                    </div>

                    <div class="col-md-6">
                        <h2><?php echo $translations['memory_usage'] ?? 'Memory Usage (in MB)'; ?></h2>
                        <pre><?php echo htmlspecialchars(shell_exec('free -m')); ?></pre>
                        <canvas id="memoryUsageChart"></canvas>
                    </div>

                </div>

                <div class="row">

                    <div class="col-md-6">
                        <h2><?php echo $translations['disk_usage'] ?? 'Disk Usage'; ?></h2>
                        <pre><?php echo htmlspecialchars(shell_exec('df -h')); ?></pre>
                        <!--				<canvas id="diskUsageChart"></canvas>-->
                    </div>

                </div>

            </div>
        </div>
    </div>
    <!--------------------------------------------->
    <!-------------- Footer ------------->
    <!--------------------------------------------->
    <footer class="footer">
        <div class="footer__copyright">
            <?php echo $translations['default_footer'] ?? "&copy; 2024 " . htmlspecialchars(date('Y')) . ", Tarek Tarabichi"; ?>
        </div>
        <div class="footer__signature">
            <?php echo $translations['made_with_love'] ?? "Made with <span style=\"color: #e25555;\">&hearts;</span> and powered by Laragon"; ?>
        </div>
    </footer>



    <script>
    // Sample data for uptime, memory usage, and disk usage charts
    const uptimeData = [ /* Add your uptime data here */ ];
    const memoryUsageData = [ /* Add your memory usage data here */ ];
    const diskUsageData = [ /* Add your disk usage data here */ ];

    // Uptime Chart
    const ctxUptime = document.getElementById('uptimeChart').getContext('2d');
    const uptimeChart = new Chart(ctxUptime, {
        type: 'line',
        data: {
            labels: ['Time1', 'Time2', 'Time3'], // Add your time labels here
            datasets: [{
                label: 'Uptime',
                data: uptimeData,
                backgroundColor: 'rgba(54, 162, 235, 0.2)',
                borderColor: 'rgba(54, 162, 235, 1)',
                borderWidth: 1
            }]
        },
        options: {
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });

    // Memory Usage Chart
    const ctxMemory = document.getElementById('memoryUsageChart').getContext('2d');
    const memoryUsageChart = new Chart(ctxMemory, {
        type: 'bar',
        data: {
            labels: ['Total', 'Used', 'Free'], // Memory usage categories
            datasets: [{
                label: 'Memory Usage (MB)',
                data: memoryUsageData,
                backgroundColor: [
                    'rgba(255, 99, 132, 0.2)',
                    'rgba(54, 162, 235, 0.2)',
                    'rgba(75, 192, 192, 0.2)'
                ],
                borderColor: [
                    'rgba(255, 99, 132, 1)',
                    'rgba(54, 162, 235, 1)',
                    'rgba(75, 192, 192, 1)'
                ],
                borderWidth: 1
            }]
        },
        options: {
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });

    // Disk Usage Chart
    const ctxDisk = document.getElementById('diskUsageChart').getContext('2d');
    const diskUsageChart = new Chart(ctxDisk, {
        type: 'doughnut',
        data: {
            labels: ['Used', 'Available'], // Disk usage categories
            datasets: [{
                label: 'Disk Usage',
                data: diskUsageData,
                backgroundColor: [
                    'rgba(255, 206, 86, 0.2)',
                    'rgba(75, 192, 192, 0.2)'
                ],
                borderColor: [
                    'rgba(255, 206, 86, 1)',
                    'rgba(75, 192, 192, 1)'
                ],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false
        }
    });
    </script>

</body>

</html>