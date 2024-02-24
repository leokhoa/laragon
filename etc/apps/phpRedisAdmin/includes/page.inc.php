<?php


// Returns true when the user is using IE
function is_ie() {
  if (isset($_SERVER['HTTP_USER_AGENT']) &&
      (strpos($_SERVER['HTTP_USER_AGENT'], 'MSIE') !== false)) {
    return true;
  } else {
    return false;
  }
}




$page = array(
  'css' => array('common'),
  'js'  => array('jquery')
);

?>