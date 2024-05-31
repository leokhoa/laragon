<?php
	const EML_FILE_PATH = 'D:/laragon/bin/sendmail/output/';
	
	if (isset($_GET['email'])) {
		$emailFile = EML_FILE_PATH . basename($_GET['email']);
		if (file_exists($emailFile)) {
			$content = file_get_contents($emailFile);
			if ($content === false) {
				echo "Error reading email file.";
			} else {
				// Decode and display content as HTML
				$decodedContent = htmlspecialchars_decode($content, ENT_QUOTES);
				echo nl2br($decodedContent);
			}
		} else {
			echo "Email not found.";
		}
	} else {
		echo "No email specified.";
	}
?>
