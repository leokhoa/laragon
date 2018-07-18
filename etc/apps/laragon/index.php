<?php
function formatLink($file) {
	if (isset($_SERVER['HTTPS']) &&
		($_SERVER['HTTPS'] == 'on' || $_SERVER['HTTPS'] == 1) ||
		isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
		$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
			$protocol = 'https';
	} else {
			$protocol = 'http';
	}
	$link = sprintf('%s://%s/laragon/uploads/%s', $protocol, $_SERVER['HTTP_HOST'], $file);
	return sprintf('<a href="%s" target="_blank">%s</a>', $link, $link);
}
function listFiles() {
	$upload_dir = dirname(__FILE__).'\uploads';
	echo sprintf('<div>Files locate at: <b>%s</b></div>', $upload_dir);
	if ($handle = opendir($upload_dir)) {

		while (false !== ($entry = readdir($handle))) {
			if ($entry != "." && $entry != "..") {
				echo '<div>'.formatLink($entry).'</div>';
			}
		}

		closedir($handle);
	}
}

?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Uploader</title>
    <link href="extras/assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="extras/assets/css/styles.css" rel="stylesheet">
  </head>
  <body>

      <div class="container">
           <div class="row" style="padding-top:10px;">
            <div class="col-xs-2">
              <button id="uploadBtn" class="btn btn-large btn-primary">Choose Files</button> 
            </div>
            <div class="col-xs-10">
          <div id="progressOuter" class="progress progress-striped active" style="display:none;">
            <div id="progressBar" class="progress-bar progress-bar-success"  role="progressbar" aria-valuenow="45" aria-valuemin="0" aria-valuemax="100" style="width: 0%">
            </div>
          </div>
            </div>
          </div>
          <div class="row" style="padding-top:10px;">
            <div class="col-xs-10">
              <div id="msgBox">
              </div>
			  <div id="uploadedFiles">
			  </div>
			  <p>
				<hr />
				<div>
					<small>
							<div><u>Tip</u>: Hold Shift if you want to upload multiple files.</div>
							<div>If you want to share over the Internet, just run:</div>
							<div><b><i>ngrok http 80</i></b></div>
					</small>
				</div>
				<hr />
				<div id="listFiles">
				<?php
					listFiles();
					
					//$upload_dir = dirname(__FILE__).'\uploads';
					//echo $upload_dir;
					//echo '<a href="http://'.$_SERVER['HTTP_HOST'].'/laragon/uploads/" target="_blank">'.$_SERVER['HTTP_HOST'].'</a>';
				?>
				</div>
			
			  </p>
            </div>
          </div>
      </div>

  <script src="extras/SimpleAjaxUploader.min.js"></script>
<script>
function escapeTags( str ) {
  return String( str )
           .replace( /&/g, '&amp;' )
           .replace( /"/g, '&quot;' )
           .replace( /'/g, '&#39;' )
           .replace( /</g, '&lt;' )
           .replace( />/g, '&gt;' );
}

function replaceAll(str, find, replace) {
  return str.replace(new RegExp(find, 'g'), replace);
}

window.onload = function() {

  var btn = document.getElementById('uploadBtn'),
      progressBar = document.getElementById('progressBar'),
      progressOuter = document.getElementById('progressOuter'),
      msgBox = document.getElementById('msgBox');
	  listFiles = document.getElementById('listFiles');
	  theLink = '<?php echo formatLink('{{FILE}}'); ?>';

  var uploader = new ss.SimpleUpload({
        button: btn,
        url: 'extras/file_upload.php',
        name: 'uploadfile',
        hoverClass: 'hover',
		multiple: true,
        focusClass: 'focus',
        responseType: 'json',
        startXHR: function() {
            progressOuter.style.display = 'block'; // make progress bar visible
            this.setProgressBar( progressBar );
        },
        onSubmit: function() {
            msgBox.innerHTML = ''; // empty the message box
            btn.innerHTML = 'Uploading...'; // change button text to "Uploading..."
          },
        onComplete: function( filename, response ) {
            btn.innerHTML = 'Choose Files';
            progressOuter.style.display = 'none'; // hide progress bar when upload is completed

            if ( !response ) {
                msgBox.innerHTML = 'Unable to upload file';
                return;
            }

            if ( response.success === true ) {
                msgBox.innerHTML = '<strong>' + escapeTags( filename ) + '</strong>' + ' successfully uploaded.';
				uploadedFiles.innerHTML = '<div class="highlight">' + replaceAll(theLink, '{{FILE}}', filename) + '</div>' + uploadedFiles.innerHTML ;

            } else {
                if ( response.msg )  {
                    msgBox.innerHTML = escapeTags( response.msg );

                } else {
                    msgBox.innerHTML = 'An error occurred and the upload failed.';
                }
            }
          },
        onError: function() {
            progressOuter.style.display = 'none';
            msgBox.innerHTML = 'Unable to upload file';
          }
	});
};
</script>
  </body>
</html>
