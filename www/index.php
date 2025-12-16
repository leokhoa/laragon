<?php
// ==========================
// BASIC ENV DETECTION
// ==========================
$isLocal = in_array($_SERVER['REMOTE_ADDR'], ['127.0.0.1', '::1'], true);

// ==========================
// QUERY HANDLING (SAFE)
// ==========================
if (isset($_GET['q'])) {
    $query = $_GET['q'];

    // Allow-list approach
    if ($query === 'info') {

        // phpinfo allowed ONLY on localhost
        if ($isLocal) {
            phpinfo();
            exit;
        }

        http_response_code(403);
        exit('Forbidden');
    }

    // Unknown query
    http_response_code(404);
    exit('Invalid query parameter.');
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laragon</title>

    <link href="https://fonts.googleapis.com/css?family=Karla:400" rel="stylesheet">

    <style>
        html, body {
            height: 100%;
            margin: 0;
            padding: 0;
            font-family: 'Karla', sans-serif;
            background-color: #f9f9f9;
            color: #333;
        }

        .container {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100%;
            text-align: center;
        }

        .content {
            max-width: 800px;
            padding: 100px;
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .title {
            font-size: 60px;
            margin: 0;
        }

        .info {
            margin-top: 20px;
            font-size: 18px;
            line-height: 1.6;
        }

        .info a {
            color: #007bff;
            text-decoration: none;
        }

        .info a:hover {
            color: #0056b3;
            text-decoration: underline;
        }

        .opt {
            margin-top: 30px;
        }

        .opt a {
            font-size: 18px;
            color: #007bff;
            text-decoration: none;
        }

        .opt a:hover {
            color: #0056b3;
            text-decoration: underline;
        }
    </style>
</head>
<body>

<div class="container">
    <div class="content">
        <h1 class="title">Laragon</h1>

        <div class="info">
            <?php if ($isLocal): ?>
                <p><?= htmlspecialchars($_SERVER['SERVER_SOFTWARE'], ENT_QUOTES, 'UTF-8'); ?></p>
                <p>
                    PHP version: <?= htmlspecialchars(PHP_VERSION, ENT_QUOTES, 'UTF-8'); ?>
                    <a title="phpinfo()" href="/?q=info">info</a>
                </p>
                <p>
                    Document Root:
                    <?= htmlspecialchars($_SERVER['DOCUMENT_ROOT'], ENT_QUOTES, 'UTF-8'); ?>
                </p>
            <?php else: ?>
                <p>Server is running</p>
                <p>PHP is enabled</p>
            <?php endif; ?>
        </div>

        <div class="opt">
            <p>
                <a href="https://laragon.org/docs" target="_blank" rel="noopener">
                    Getting Started
                </a>
            </p>
        </div>
    </div>
</div>

</body>
</html>
