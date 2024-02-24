<?php


if (!isset($_POST['post'])) {
  die('Javascript needs to be enabled for you to delete keys.');
}


require_once 'includes/common.inc.php';


if (isset($_GET['key'])) {
  // String
  if (!isset($_GET['type']) || ($_GET['type'] == 'string')) {
    // Delete the whole key.
    $redis->del($_GET['key']);
  }

  // Hash
  else if (($_GET['type'] == 'hash') && isset($_GET['hkey'])) {
    // Delete only the field in the hash.
    $redis->hDel($_GET['key'], $_GET['hkey']);
  }

  // List
  else if (($_GET['type'] == 'list') && isset($_GET['index'])) {
    // Lists don't have simple delete operations.
    // You can only remove something based on a value so we set the value at the index to some random value we hope doesn't occur elsewhere in the list.
    $value = str_rand(69);

    // This code assumes $value is not present in the list. To make sure of this we would need to check the whole list and place a Watch on it to make sure the list isn't modified in between.
    $redis->lSet($_GET['key'], $_GET['index'], $value);
    $redis->lRem($_GET['key'], 1, $value);
  }

  // Set
  else if (($_GET['type'] == 'set') && isset($_GET['value'])) {
    // Removing members from a set can only be done by supplying the member.
    $redis->sRem($_GET['key'], $_GET['value']);
  }

  // ZSet
  else if (($_GET['type'] == 'zset') && isset($_GET['value'])) {
    // Removing members from a zset can only be done by supplying the value.
    $redis->zRem($_GET['key'], $_GET['value']);
  }


  die('?view&s='.$server['id'].'&d='.$server['db'].'&key='.urlencode($_GET['key']));
}


if (isset($_GET['tree'])) {
  $keys = $redis->keys($_GET['tree'].'*');

  foreach ($keys as $key) {
    $redis->del($key);
  }

  die('?view&s='.$server['id'].'&d='.$server['db']);
}

if (isset($_GET['batch_del'])) {
  $keys = $_POST['selected_keys'];
  $keys = trim($keys, ',');
  if (empty($keys)) die('No keys to delete');

  $keys = explode(',', $keys);
  foreach ($keys as $key) {
    $redis->del($key);
  }

  die('?view&s=' . $server['id'] . '&d=' . $server['db'] . '&key=' . urlencode($keys[0]));
}

?>
