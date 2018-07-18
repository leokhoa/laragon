<?php
require('Uploader.php');

// Directory where we're storing uploaded images
// Remember to set correct permissions or it won't work
$upload_dir = '../uploads';

$uploader = new FileUpload('uploadfile');
$uploader->sizeLimit = 1024*1024*1024;         // Max file upload size in bytes 1GB)

// Handle the upload
$result = $uploader->handleUpload($upload_dir);

if (!$result) {
  exit(json_encode(array('success' => false, 'msg' => $uploader->getErrorMsg())));  
}

echo json_encode(array('success' => true));
