<?php

/**
* Simple Ajax Uploader
* Version 2.0
* https://github.com/LPology/Simple-Ajax-Uploader
*
* Copyright 2012-2015 LPology, LLC
* Released under the MIT license
*
* View the documentation for an example of how to use this class.
*/

class FileUpload {
    private $fileName;                    // Filename of the uploaded file
    private $fileSize;                    // Size of uploaded file in bytes
    private $fileExtension;               // File extension of uploaded file
    private $fileNameWithoutExt;
    private $savedFile;                   // Path to newly uploaded file (after upload completed)
    private $errorMsg;                    // Error message if handleUpload() returns false (use getErrorMsg() to retrieve)
    private $isXhr;
    public $uploadDir;                    // File upload directory (include trailing slash)
    public $allowedExtensions;            // Array of permitted file extensions
    public $sizeLimit = 10485760;         // Max file upload size in bytes (default 10MB)
    public $newFileName;                  // Optionally save uploaded files with a new name by setting this
    public $corsInputName = 'XHR_CORS_TARGETORIGIN';
    public $uploadName = 'uploadfile';

    function __construct($uploadName = null) {
        if ($uploadName !== null) {
            $this->uploadName = $uploadName;
        }

        if (isset($_FILES[$this->uploadName])) {
            $this->isXhr = false;

            if ($_FILES[$this->uploadName]['error'] === UPLOAD_ERR_OK) {
                $this->fileName = $_FILES[$this->uploadName]['name'];
                $this->fileSize = $_FILES[$this->uploadName]['size'];

            } else {
                $this->setErrorMsg($this->errorCodeToMsg($_FILES[$this->uploadName]['error']));
            }

        } elseif (isset($_SERVER['HTTP_X_FILE_NAME']) || isset($_GET[$this->uploadName])) {
            $this->isXhr = true;

            $this->fileName = isset($_SERVER['HTTP_X_FILE_NAME']) ?
                                    $_SERVER['HTTP_X_FILE_NAME'] : $_GET[$this->uploadName];

            if (isset($_SERVER['CONTENT_LENGTH'])) {
                $this->fileSize = (int)$_SERVER['CONTENT_LENGTH'];

            } else {
                throw new Exception('Content length is empty.');
            }
        }

        if ($this->fileName) {
            $pathinfo = pathinfo($this->fileName);

            if (array_key_exists('extension', $pathinfo) &&
                array_key_exists('filename', $pathinfo))
            {
                $this->fileExtension = strtolower($pathinfo['extension']);
                $this->fileNameWithoutExt = $pathinfo['filename'];
            }
        }
    }

    public function getFileName() {
        return $this->fileName;
    }

    public function getFileSize() {
        return $this->fileSize;
    }

    public function getExtension() {
        return $this->fileExtension;
    }

    public function getErrorMsg() {
        return $this->errorMsg;
    }

    public function getSavedFile() {
        return $this->savedFile;
    }

    private function errorCodeToMsg($code) {
        switch($code) {
            case UPLOAD_ERR_INI_SIZE:
                $message = 'File size exceeds limit.';
                break;
            case UPLOAD_ERR_PARTIAL:
                $message = 'The uploaded file was only partially uploaded.';
                break;
            case UPLOAD_ERR_NO_FILE:
                $message = 'No file was uploaded.';
                break;
            case UPLOAD_ERR_NO_TMP_DIR:
                $message = 'Missing a temporary folder.';
                break;
            case UPLOAD_ERR_CANT_WRITE:
                $message = 'Failed to write file to disk.';
                break;
            case UPLOAD_ERR_EXTENSION:
                $message = 'File upload stopped by extension.';
                break;
            default:
                $message = 'Unknown upload error.';
                break;
        }
        return $message;
    }

    private function checkExtension($ext, $allowedExtensions) {
        if (!is_array($allowedExtensions))
            return false;

        if (!in_array(strtolower($ext), array_map('strtolower', $allowedExtensions)))
            return false;

        return true;
    }

    private function setErrorMsg($msg) {
        if (empty($this->errorMsg))
            $this->errorMsg = $msg;
    }

    private function fixDir($dir) {
        if (empty($dir))
            return $dir;

        $slash = DIRECTORY_SEPARATOR;
        $dir = str_replace('/', $slash, $dir);
        $dir = str_replace('\\', $slash, $dir);
        return substr($dir, -1) == $slash ? $dir : $dir . $slash;
    }

    // escapeJS and jsMatcher are adapted from the Escaper component of
    // Zend Framework, Copyright (c) 2005-2013, Zend Technologies USA, Inc.
    // https://github.com/zendframework/zf2/tree/master/library/Zend/Escaper
    private function escapeJS($string) {
        return preg_replace_callback('/[^a-z0-9,\._]/iSu', $this->jsMatcher, $string);
    }

    private function jsMatcher($matches) {
        $chr = $matches[0];

        if (strlen($chr) == 1)
            return sprintf('\\x%02X', ord($chr));

        if (function_exists('iconv'))
            $chr = iconv('UTF-16BE', 'UTF-8', $chr);

        elseif (function_exists('mb_convert_encoding'))
            $chr = mb_convert_encoding($chr, 'UTF-8', 'UTF-16BE');

        return sprintf('\\u%04s', strtoupper(bin2hex($chr)));
    }

    public function corsResponse($data) {
        if (isset($_REQUEST[$this->corsInputName])) {
            $targetOrigin = $this->escapeJS($_REQUEST[$this->corsInputName]);
            $targetOrigin = htmlspecialchars($targetOrigin, ENT_QUOTES, 'UTF-8');
            return "<script>window.parent.postMessage('$data','$targetOrigin');</script>";
        }
        return $data;
    }

    private function saveXhr($path) {
        if (false !== file_put_contents($path, fopen('php://input', 'r')))
            return true;
        return false;
    }

    private function saveForm($path) {
        if (move_uploaded_file($_FILES[$this->uploadName]['tmp_name'], $path))
            return true;
        return false;
    }

    private function save($path) {
        if (true === $this->isXhr)
            return $this->saveXhr($path);
        return $this->saveForm($path);
    }

    public function handleUpload($uploadDir = null, $allowedExtensions = null) {
        if (!$this->fileName) {
            $this->setErrorMsg('Incorrect upload name or no file uploaded');
            return false;
        }

        if ($this->fileSize == 0) {
            $this->setErrorMsg('File is empty');
            return false;
        }

        if ($this->fileSize > $this->sizeLimit) {
            $this->setErrorMsg('File size exceeds limit');
            return false;
        }

        if (!empty($uploadDir))
            $this->uploadDir = $uploadDir;

        $this->uploadDir = $this->fixDir($this->uploadDir);

        if (!is_writable($this->uploadDir)) {
            $this->setErrorMsg('Upload directory is not writable');
            return false;
        }

        if (is_array($allowedExtensions))
            $this->allowedExtensions = $allowedExtensions;

        if (!empty($this->allowedExtensions)) {
            if (!$this->checkExtension($this->fileExtension, $this->allowedExtensions)) {
                $this->setErrorMsg('Invalid file type');
                return false;
            }
        }

        $this->savedFile = $this->uploadDir . $this->fileName;

        if (!empty($this->newFileName)) {
            $this->fileName = $this->newFileName;
            $this->savedFile = $this->uploadDir . $this->fileName;

            $this->fileNameWithoutExt = null;
            $this->fileExtension = null;

            $pathinfo = pathinfo($this->fileName);

            if (array_key_exists('filename', $pathinfo))
                $this->fileNameWithoutExt = $pathinfo['filename'];

            if (array_key_exists('extension', $pathinfo))
                $this->fileExtension = strtolower($pathinfo['extension']);
        }

        if (!$this->save($this->savedFile)) {
            $this->setErrorMsg('File could not be saved');
            return false;
        }

        return true;
    }

}
