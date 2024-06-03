<?php
	/**
	 * Application: Laragon | Server Index Inbox Page
	 * Description: This is the main index page for the Laragon server, displaying server info and applications.
	 * Author: Tarek Tarabichi <tarek@2tinteractive.com>
	 * Contributors: LrkDev in v.2.1.2
	 * Version: 2.2.1
	 */
	
	// Set the directory path (modify as needed)
	const EML_FILE_PATH = 'D:/laragon/bin/sendmail/output/';
	
	// Function to handle email deletion
	function handleEmailDeletion($directory) {
		if (isset($_GET['delete'])) {
			$fileToDelete = $directory . basename($_GET['delete']);
			if (file_exists($fileToDelete)) {
				unlink($fileToDelete);
			}
			header("Location: " . $_SERVER['PHP_SELF']);
			exit;
		}
	}
	
	// Function to get list of emails
	function getEmails($directory) {
		if (!is_dir($directory)) {
			echo "<p>Directory does not exist: $directory</p>";
			return [];
		}
		$files = scandir($directory);
		if ($files === false) {
			echo "<p>Failed to scan directory: $directory</p>";
			return [];
		}
		$files = array_diff($files, ['.', '..']);
		return array_filter($files, function ($file) {
			return preg_match('~^mail-\d{8}-\d{6}\.\d{3}\.txt$~', $file);
		});
	}
	
	// Function to sort emails by date
	function sortEmailsByDate($emails, $directory) {
		usort($emails, function ($a, $b) use ($directory) {
			return filemtime($directory . $b) - filemtime($directory . $a);
		});
		return $emails;
	}
	
	// Handle email deletion if requested
	handleEmailDeletion(EML_FILE_PATH);
	
	// Get and sort emails
	$emails = getEmails(EML_FILE_PATH);
	$emails = sortEmailsByDate($emails, EML_FILE_PATH);

?>
<!DOCTYPE html>
<html lang="en">

<!DOCTYPE html>
<html lang="<?php echo $lang; ?>">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="icon" type="image/x-icon" href="assets/favicon.ico">
    <title><?php echo $translations['title'] ?? 'Welcome to the Laragon Dashboard'; ?></title>

    <link href="https://fonts.googleapis.com/css?family=Pt+Sans&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Poppins:300,400,500,700&display=swap">

    <link rel="stylesheet" href="./assets/style.css">

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap-grid.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap-reboot.min.css" />

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/brands.min.css" />


    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

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


    .modal-body {
        position: relative;
        flex: 1 1 auto;
        padding: var(--bs-modal-padding);
        --bs-modal-padding: 1.5rem;
        width: 100%;
        max-height: calc(100vh - 210px);
        overflow-y: auto;
        background-color: white;
        border-radius: 20px;
        border: 1px solid black;
    }

    .modal-content {
        position: relative;
        display: flex;
        flex-direction: column;
        width: 100%;
        color: black;
        pointer-events: auto;
        background-color: #ffffff;
        background-clip: padding-box;
        border: 1px solid rgba(0, 0, 0, 0.2);
        border-radius: 0.3rem;
        outline: 0;
    }

    /* Common Class */
    .pd-5 {
        padding: 5px;
    }

    .pd-10 {
        padding: 10px;
    }

    .pd-20 {
        padding: 20px;
    }

    .pd-30 {
        padding: 30px;
    }

    .pb-10 {
        padding-bottom: 10px;
    }

    .pb-20 {
        padding-bottom: 20px;
    }

    .pb-30 {
        padding-bottom: 30px;
    }

    .pt-10 {
        padding-top: 10px;
    }

    .pt-20 {
        padding-top: 20px;
    }

    .pt-30 {
        padding-top: 30px;
    }

    .pr-10 {
        padding-right: 10px;
    }

    .pr-20 {
        padding-right: 20px;
    }

    .pr-30 {
        padding-right: 30px;
    }

    .pl-10 {
        padding-left: 10px;
    }

    .pl-20 {
        padding-left: 20px;
    }

    .pl-30 {
        padding-left: 30px;
    }

    .px-30 {
        padding-left: 30px;
        padding-right: 30px;
    }

    .px-20 {
        padding-left: 20px;
        padding-right: 20px;
    }

    .py-30 {
        padding-top: 30px;
        padding-bottom: 30px;
    }

    .py-20 {
        padding-top: 20px;
        padding-bottom: 20px;
    }

    .mb-30 {
        margin-bottom: 30px;
    }

    .mb-50 {
        margin-bottom: 50px;
    }

    .font-30 {
        font-size: 30px;
        line-height: 1.46em;
    }

    .font-24 {
        font-size: 24px;
        line-height: 1.5em;
    }

    .font-20 {
        font-size: 20px;
        line-height: 1.5em;
    }

    .font-18 {
        font-size: 18px;
        line-height: 1.6em;
    }

    .font-16 {
        font-size: 16px;
        line-height: 1.75em;
    }

    .font-14 {
        font-size: 14px;
        line-height: 1.85em;
    }

    .font-12 {
        font-size: 12px;
        line-height: 2em;
    }

    .weight-300 {
        font-weight: 300;
    }

    .weight-400 {
        font-weight: 400;
    }

    .weight-500 {
        font-weight: 500;
    }

    .weight-600 {
        font-weight: 600;
    }

    .weight-700 {
        font-weight: 700;
    }

    .weight-800 {
        font-weight: 800;
    }

    .text-blue {
        color: #1b00ff;
    }

    .text-dark {
        color: #000000;
    }

    .text-white {
        color: #ffffff;
    }

    .height-100-p {
        height: 100%;
    }

    .bg-white {
        background: #ffffff;
    }

    .border-radius-10 {
        -webkit-border-radius: 10px;
        -moz-border-radius: 10px;
        border-radius: 10px;
    }

    .border-radius-100 {
        -webkit-border-radius: 100%;
        -moz-border-radius: 100%;
        border-radius: 100%;
    }

    .box-shadow {
        -webkit-box-shadow: 0px 0px 28px rgba(0, 0, 0, .08);
        -moz-box-shadow 0px 0px 28px rgba(0, 0, 0, .08);
        box-shadow: 0px 0px 28px rgba(0, 0, 0, .08);
    }

    .gradient-style1 {
        background-image: linear-gradient(135deg, #43CBFF 10%, #9708CC 100%);
    }

    .gradient-style2 {
        background-image: linear-gradient(135deg, #72EDF2 10%, #5151E5 100%);
    }

    .gradient-style3 {
        background-image: radial-gradient(circle 732px at 96.2% 89.9%, rgba(70, 66, 159, 1) 0%, rgba(187, 43, 107, 1) 92%);
    }

    .gradient-style4 {
        background-image: linear-gradient(135deg, #FF9D6C 10%, #BB4E75 100%);
    }

    /* widget style 1 */
    .widget-style1 {
        padding: 20px 10px;
    }

    .widget-style1 .circle-icon {
        width: 60px;
    }

    .widget-style1 .circle-icon .icon {
        width: 60px;
        height: 60px;
        background: #ecf0f4;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .widget-style1 .widget-data {
        width: calc(100% - 150px);
        padding: 0 15px;
    }

    .widget-style1 .progress-data {
        width: 90px;
    }

    .widget-style1 .progress-data .apexcharts-canvas {
        margin: 0 auto;
    }

    .widget-style2 .widget-data {
        padding: 20px;
    }

    .widget-style3 {
        padding: 30px 20px;
    }

    .widget-style3 .widget-data {
        width: calc(100% - 60px);
    }

    .widget-style3 .widget-icon {
        width: 60px;
        font-size: 45px;
        line-height: 1;
    }

    a.email-link {
        color: black !important;
        text-decoration: none;
    }

    .bg-white.box-shadow.border-radius-10.height-100-p.widget-style1 {
        height: 140px !important;
        overflow-y: scroll;
    }
    </style>
</head>

<body>
    <div class="grid-container">
        <div class="menu-icon">
            <i class="fas fa-bars header__menu"></i>
        </div>

        <header class="header">
            <div class="header__search">My Development Server Mailbox</div>
            <div class="header__avatar">Welcome Back!</div>
        </header>

        <main class="main">
            <!-- Server Info Section -->
            <div class="main-overview">

                <div class="row">

                    <div class="col-xl-3 mb-50">
                        <div class="bg-white box-shadow border-radius-10 height-100-p widget-style1">
                            <div class="d-flex flex-wrap align-items-center">
                                <div class="circle-icon">
                                    <div class="icon border-radius-100 font-24 text-blue">
                                        <i class="fa fa-message" aria-hidden="true"></i>
                                    </div>
                                </div>
                                <div class="widget-data">
                                    <div class="weight-600 font-18">Logged Messages</div>
                                    <div class="weight-500">
                                        <a href="#" style="margin-top: 10px;color: #000;!important">
                                            <span style=" color:#000; font-size: 44px; font-weight: bold;"><?php echo count(getEmails(EML_FILE_PATH)) ?></span>
                                        </a>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>


                    <div class="col-xl-3 mb-50">
                        <div class="bg-white widget-style1 border-radius-10 height-100-p box-shadow">
                            <div class="d-flex flex-wrap align-items-center">
                                <div class="circle-icon">
                                    <div class="icon border-radius-100 font-24 text-blue">
                                        <i class="fa fa-directory" aria-hidden="true"></i>
                                    </div>
                                </div>
                                <div class="widget-data">
                                    <div class="weight-600 font-18">
                                        <span style="color: #000; font-weight: 400;">
                                            <?php echo "<small>Directory:<p style='color: #000;'> " . EML_FILE_PATH . "</p></small>"; ?>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>


                    <div class="col-xl-6 mb-50">
                        <div class="bg-white box-shadow border-radius-10 height-100-p widget-style1">
                            <div class="d-flex flex-wrap align-items-center">
                                <div class="circle-icon">
                                    <div class="icon border-radius-100 font-24 text-blue"><i class="fa fa-dollar" aria-hidden="true"></i></div>
                                </div>
                                <div class="widget-data">
                                    <div class="weight-400 font-18" style="color: #000000!important;">
                                        <?php echo "<small><p style='color: #000;'>" . implode(", ", getEmails(EML_FILE_PATH)) . "</p></small>"; ?>
                                    </div>

                                </div>

                            </div>
                        </div>
                    </div>

                </div>

                <!-- Email List Section -->
            </div>
            <br><br><br>
            <!-- Email List Section -->
            <div class="container mt-5" style="width: 1440px!important;background-color: #f8f9fa;padding: 20px;border-radius: 5px;color=#000000">
                <h1 style="text-align: center;color: #000000">Email List</h1>

                <?php if (empty($emails)): ?>
                <div class="alert alert-info" style="color: #000000">No emails found.</div>
                <?php else: ?>
                <ul class="list-group" style="color: #000000">
                    <?php foreach ($emails as $email): ?>
                    <li class="list-group-item d-flex justify-content-between align-items-center" style="color: #000000">
                        <a href="#" class="email-link" style="color: #000000" data-email="<?= $email ?>"><?= $email ?></a>
                        <form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="get" class="d-inline">
                            <input type="hidden" name="delete" value="<?= $email ?>">
                            <button type="submit" class="btn btn-sm btn-danger">Delete</button>
                        </form>
                    </li>
                    <?php endforeach; ?>
                </ul>
                <?php endif; ?>
            </div>

            <div class="modal fade" id="emailModal" tabindex="-1" role="dialog">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-body"></div>
                    </div>
                </div>
            </div>
        </main>

    </div>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js" integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0-beta1/dist/js/bootstrap.bundle.min.js"></script>
    <script>
    $(document).ready(function() {
        $('.email-link').click(function(e) {
            e.preventDefault();
            var email = $(this).data('email');
            $.ajax({
                url: 'assets/inbox/open_email.php',
                data: {
                    email: email
                },
                success: function(data) {
                    $('#emailModal .modal-body').html(data);
                    $('#emailModal').modal('show');
                }
            });
        });
    });
    </script>
</body>

</html>