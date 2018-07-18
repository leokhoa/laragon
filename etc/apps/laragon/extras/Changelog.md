Change Log 
============================
### Version 2.0 ###

SimpleAjaxUploader.js:

* Added support for drag and drop file uploads
* Added `ss.uploadSetup()` method to set default uploader option values (useful for multiple uploader instances)
* Added `noParams` option to disable the default behavior of appending the file name to the URL query string
* Numerous code improvements throughout -- bug fixes, memory usage, etc.

Uploader.php
* Refactored into a single class in accordance with one class, one file
* Made improvements to error detection and handling
* Added support for reading the `X-File-Name` header as an alternative to query string parameters for sending file names to the server
* Set default value of the `$uploadName` property to be `"uploadfile"` for consistency with the examples - <a href="https://github.com/LPology/Simple-Ajax-Uploader/issues/72">72</a>

### Version 1.11 ###
* Added support for PHP Session Upload Progress for PHP 5.4+ (APC was deprecated in 5.3) 
* Added `clearQueue()` method which gives the user the ability to clear all files in queue - <a href="https://github.com/LPology/Simple-Ajax-Uploader/pull/62">#62</a> - (Special thanks to <a href="https://github.com/mouse0270">mouse0270</a> for this one) 
* Fixed multiple file selection bug - <a href="https://github.com/LPology/Simple-Ajax-Uploader/pull/67">#67</a> - (Special thanks to <a href="https://github.com/genintho">genintho</a> for this) 
* Fixed bug which could allow form/input elements to be created with invalid name/ID attributes in IE7-9 

### Version 1.10.1 ###
* `iframe` and `form` elements are now created with `document.createElement()` rather than the much slower HTML injection method
* Removed unused variable from `_uploadIframe()`

### Version 1.10 ###
* Added `setOptions()` method for setting or changing upload options - <a href="https://github.com/LPology/Simple-Ajax-Uploader/issues/54">#54</a> - (special thanks to <a href="https://github.com/hauru">hauru</a> for this)
* Added `customHeader` option for sending custom request headers - <a href="https://github.com/LPology/Simple-Ajax-Uploader/issues/47">#47</a> (special thanks to <a href="https://github.com/cillosis">cillosis</a> for this)
* Updated `ss.parseJSON()` to use a more secure method of manually parsing JSON 

### Version 1.9.1 ###
* `onError()` callback now receives server response as an argument, if it exists, or `false` if it does not - <a href="https://github.com/LPology/Simple-Ajax-Uploader/pull/37">#37</a> (special thanks to <a href="https://github.com/KSDaemon">KSDaemon</a> for this) 
<br />
<br />
<strong>API Change Note:</strong> For consistency with the other callbacks, the server response is passed to `onError()` as the next to last argument, directly before the upload button. Therefore, if you use the upload button parameter in `onError()`, you will need to update your code when upgrading.
<br />
<br />
* Switched from Google Closure Compiler to YUI Compressor for minification

### Version 1.9 ###
* Added CORS support - <a href="http://www.lpology.com/code/ajaxuploader/How-to-Cross-Domain-File-Uploading.php">Learn more</a>
* Query string parameters for Nginx Upload Progress Module in `_uploadIframe()` are now encoded with `encodeURIComponent()`
* Upload progress ID keys are now generated prior to each upload instead of on page load
* Query string parameters passed to `url` are now preserved - <a href="https://github.com/LPology/Simple-Ajax-Uploader/issues/34">#34</a> (special thanks to <a href="https://github.com/Deefjuh">Deefjuh</a> for this)

### Version 1.8.2 ###
* A reference to the button which triggers an upload is now passed as the last argument to the following callbacks: `onAbort()`, `onChange()`, `onSubmit()`, `onComplete()`, `onError()`, `startXHR()`, `endXHR()`, `startNonXHR()`, `endNonXHR()` (can be useful when using multiple upload buttons)
* Fixed bug which caused some methods to not work if called inside of `startXHR()` or `startNonXHR()`
* Fixed bug causing undefined variable in IE9 and older if `progressUrl` and `nginxProgressUrl` are not set

### Version 1.8.1 ###
* Added `destroy()` method for completely removing upload functionality
* Removed redundant call to `ss.verifyElem()` inside of `rerouteClicks()`
* Moved browser-specific checks to top of IIFE, as they only need to execute once

### Version 1.8 ###
SimpleAjaxUploader.js:
* Added support for <a href="http://wiki.nginx.org/HttpUploadProgressModule">Nginx Upload Progress Module</a>
* Added `setAbortBtn()` method to designate an element as "cancel" button
* Added `onAbort()` callback function to specify behavior upon manual abort
* Added `setPctBox()` method to designate an element to be injected with upload progress percentage
* Switched to a unique ID function that is RFC 4122 version 4 compliant
* The `button` option now accepts either a single button (element ID string, element, or jQuery object), or an array of buttons. If an array is passed, each element in the array will work as an upload button
* Upload progress update request keys are now locally generated
* Fixed bug that was causing `onError()` to be fired twice
* For consistency with jQuery behavior, any 2xx status code is now handled as a successful response (previously, only `200` and `201` were successful)
* Upload buttons are now being properly disabled/enabled at correct points
* Made significant improvements to error handling, particularly with iframe uploads and retrieving server provided progress updates
* Fixed a number of potential memory leaks for Internet Explorer
* Regular expressions are now pre-compiled and cached for better performance
* For server progress tracking, `sizeBox` and `onUpdateFileSize()` are no longer pointlessly set/called again after first progress update is received

uploadProgress.php:
* Removed functionality for returning upload keys, as RFC 4122 v4 compliant UUIDs are now generated client side

### Version 1.7 ###
SimpleAjaxUploader.js:
* Fixed IE6/IE7 memory leak when removing elements without first removing event listeners (<a href="https://github.com/LPology/Simple-Ajax-Uploader/issues/21">issue #21</a>)
* Fixed possible race condition in which `removeCurrent()` could potentially delete the wrong file from the upload queue
* Multiple file inputs are now disabled in Safari due to a browser bug that just screws everything up (see: http://stackoverflow.com/q/7231054/1091949)
* Switched to a smaller, faster process for cross-browser bounding box calculation
* Updated to faster methods of checking for, adding, and removing element CSS classes
* Combined `_checkExtension()` with `_checkFile()` to eliminate a function call/reduce code size
* Combined `_handleIframeResponse()` with `_uploadIframe()` and switched to a more efficient method of getting iframe contents
* Removed a number of unnecessary/redundant function calls, along with some unnecessary variable copying
* Updated `ss.verifyElem()` to use the much faster `charAt()` and `substr()` in place of a regex and `slice()`
* Added separate feature detection for file input `accept` attribute

Uploader.php:
* Removed unnecessary check of `$allowedExtensions` for `null` value in `handleUpload()`
* Added `final` keyword to `FileUploadXHR` and `FileUploadPOSTForm` classes and their respective methods to discourage direct use

### Version 1.6.5 ###
* When using `multipart`, additional data will now also appended to the multipart form.
* Cleaned up some messy code -- organization, unnecessary variable copying, etc.

### Version 1.6.4 ###
* Switched from using `setAttribute` to dot notation for setting element properties (some versions of IE don't handle `setAttribute` well)
* `ss.removeItem()` now uses the faster countdown method to loop through arrays
* In accordance with W3 standards, `_uploadXhr()` now accepts either a `200 OK` or `201 Created` as a successful response
* Uploader.php -- the `handleUpload()` method now checks whether the `allowedExtensions` property is `empty` instead of `null`. This prevents an "Invalid file type" error resulting from passing an empty array

### Version 1.6.3 ###
* Fixed bug which allowed `onComplete()` to be called after JSON parse error

### Version 1.6.2 ###
* Overhauled error handling to fix a number of issues. 
* Added consistent error types for `onError()` so that the second parameter will be either:
`parseerror` (bad JSON from server), `transfererror` (xfer error during XHR upload), `servererror` (server response not `200 OK`)
* Fixed problem with null file size parameter for `endXHR()` callback

### Version 1.6.1 ###
* Plugin is now wrapped in an IIFE
* Leading semicolon added to close any previous statement 
* Code is now in strict mode
* Cleaned up a few messy areas

### Version 1.6 ###
If the 1.6 release has a theme, it is flexibility. Nearly every update in this release is intended to allow greater flexibility for developers.

* Submitting a file which exceeds `maxSize` or is not an `allowedExtension` no longer triggers an alert, but will instead fire a callback
* Added `onSizeError()` callback function which fires when a file exceeds the `maxSize` option, if it is set
* Added `onExtError()` callback which fires when a file is not permitted by the `allowedExtensions` option, if it is set
* Removed `messages` option and `_errorMsg()`, both of which are no longer used
* Added new `accept` option, the value of which will be the value of the `accept` file input attribute in supporting browsers. <a href="http://stackoverflow.com/a/10503561/1091949">More info.</a>
* Added new `method` option to allow specifying an HTTP method other than POST

Special thanks to <a href="https://github.com/dleffler">dleffler</a>, <a href="https://github.com/devtrends">devtrends</a> and <a href="https://github.com/urcadox">urcadox</a> for their ideas and feedback.

### Version 1.5.3 ###
* Added `autoSubmit` check before submitting in `_cycleQueue()`
* Added check to ensure upload progress server key doesn't exceed 57 characters (max allowable APC key length)
* `rerouteClicks(element)` can now be used to add additional elements which can be clicked to open file box

### Version 1.5.2 ###
(This isn't as much a release as it is a signal to update for anyone who may have downloaded version 1.5.1 in the past few hours)
* Fixed "bug" from 1.5.1 that broke uploader without multiple option enabled
* Added `queue` option to disable automatic file queuing

### Version 1.5.1 ###
* Multiple file inputs are now used in browsers with support for File API, thus allowing multiple file selection if `multiple` option is `true`
* Removed some unnecessary variable copying
* Added queue system which allows files to be selected and automatically uploaded as others finish
* Added `getQueueSize()` function to get current number of files waiting in queue
* Fixed bug in which active upload counter was not properly updating when returning `false` from `startXHR()` and `startNonXHR()`
* Error messages now incorporate file names

### Version 1.5 ###
* Added support for multiple file uploading, along with Gmail-style multiple progress bars for tracking each file.
* Added new `maxSize` option for file size limits, `allowedExtensions` option for file type restrictions. Custom error messages supported for both.
* Updated `verifyElem()` to use a better method of detecting if an upload button is a jQuery object.
* Numerous code enhancements throughout - updated error handling, cleaner organization, performance improvements.
* Patched some memory leaks created by circular references in event handlers.

### Version 1.4.2 ###
* SimpleAjaxUploader.js - Added `multipart` option to allow multipart form upload instead of binary stream
* Uploader.php - The check for form uploads is now first in the constructor to accomodate new `multipart` option
* Uploader.php - Providing an array of valid file extensions is now optional. If not provided, all file types are allowed
* Added minified version of JS file

### Version 1.4.1 ###
* Fixed XHR status check logic that could allow false alarm calls to onError callback
* Removed redundant XHR status check
* Returning false from a callback no longer clears the file field. Not sure why it ever did to begin with.
* A status check now occurs prior to progress update requests to prevent potential loop that could be caused by a server error
* Parsing JSON in older browsers no longer uses `eval` because it's evil

### Version 1.4  ###
This release includes a major overhaul that adds functionality for implementing cross-browser upload progress support. Through feature detection and abstraction, it is now possible for the `onProgress` callback function to maintain consistent behavior across browsers. 

Currently, only PHP (with APC extension) is supported. To use, set the newly added `progressUrl` option to the URL of the included UploadProgress.php script, and `onProgress` will then return upload progress data in Internet Explorer 9 and below.

Note that this added functionality does not affect the behavior of the plugin for those not using PHP, or just not using the feature.

For those not using PHP, a similar result can still be achieved with the `startXH`/`endXHR` and `startNonXHR`/`endNonXHR` callback functions, which are included specifically for defining behavior based on whether XHR uploads are supported.

Also, adding support for other programming languages would certainly be a welcome addition, if anyone is interested in working on that.

Other items:

* Added `onUpdateFileSize` callback function for getting file size in IE9 and below (When server supported progress is enabled)
* Removed the unneccessary _handleJSON method
* Added new ss.newXHR method
* Added extras folder for non-necessary items (i.e., everything but SimpleAjaxUploader.js)
* Adjusted request headers for XHR uploads 
* Moved support detection for HTML5 File API to constructor so it only executes once
* Timestamps now appended to URLs to prevent browsers from caching requests

### Version 1.3 ###
* Returned to version numbering
* Updated method for parsing JSON
* Added PHP class for handling file uploads
* Cleaned up messy areas

### Earlier versions ###
Prior to version 1.3, I did a pretty horrible job of documenting changes, and, at one point, entirely dispensed with any notion of version control whatsoever. I have since seen the light.