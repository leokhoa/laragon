<?php

require_once 'includes/common.inc.php';


// Export to redis-cli commands
function export_redis($key, $filter = false, $transform = false) {

  global $redis;

  $type = $redis->type($key);

  // we rename the keys as necessary
  if($filter !== false && $transform !== false)
    $outputKey = str_replace($filter, $transform, $key);
  else
    $outputKey = $key;
  
  // String
  if ($type == 'string') {
    echo 'SET "',addslashes($outputKey),'" "',addslashes($redis->get($key)),'"',PHP_EOL;
  }

  // Hash
  else if ($type == 'hash') {
    $values = $redis->hGetAll($key);

    foreach ($values as $k => $v) {
      echo 'HSET "',addslashes($outputKey),'" "',addslashes($k),'" "',addslashes($v),'"',PHP_EOL;
    }
  }

  // List
  else if ($type == 'list') {
    $size = $redis->lLen($key);

    for ($i = 0; $i < $size; ++$i) {
      echo 'RPUSH "',addslashes($outputKey),'" "',addslashes($redis->lIndex($key, $i)),'"',PHP_EOL;
    }
  }

  // Set
  else if ($type == 'set') {
    $values = $redis->sMembers($key);

    foreach ($values as $v) {
      echo 'SADD "',addslashes($outputKey),'" "',addslashes($v),'"',PHP_EOL;
    }
  }

  // ZSet
  else if ($type == 'zset') {
    $values = $redis->zRange($key, 0, -1);

    foreach ($values as $v) {
      $s = $redis->zScore($key, $v);

      echo 'ZADD "',addslashes($outputKey),'" ',$s,' "',addslashes($v),'"',PHP_EOL;
    }
  }
}



// Return the JSON for this key
function export_json($key) {
  global $redis;

  $type = $redis->type($key);

  // String
  if ($type == 'string') {
    $value = $redis->get($key);
  }

  // Hash
  else if ($type == 'hash') {
    $value = $redis->hGetAll($key);
  }

  // List
  else if ($type == 'list') {
    $size  = $redis->lLen($key);
    $value = array();

    for ($i = 0; $i < $size; ++$i) {
      $value[] = $redis->lIndex($key, $i);
    }
  }

  // Set
  else if ($type == 'set') {
    $value = $redis->sMembers($key);
  }

  // ZSet
  else if ($type == 'zset') {
    $value = $redis->zRange($key, 0, -1);
  }


  return $value;
}




// Export
if (isset($_POST['type'])) {
  if ($_POST['type'] == 'json') {
    $ext = 'js';
    $ct  = 'application/json';
  } else {
    $ext = 'redis';
    $ct  = 'text/plain';
  }


  header('Content-type: '.$ct.'; charset=utf-8');
  header('Content-Disposition: inline; filename="export.'.$ext.'"');

  $filter = !empty($_POST['filter']) ? trim($_POST['filter']) : false;
  $transform = !empty($_POST['transform']) ? trim($_POST['transform']) : false;

  // JSON
  if ($_POST['type'] == 'json') {
    
    // Single key
    if (isset($_GET['key'])) {
      echo json_encode(export_json($_GET['key']));
    } else { // All keys
      $keys = $redis->keys('*');
      $vals = array();

      foreach ($keys as $key) {

        // if we have a filter and no match, nothing to do
        if($filter !== false && stripos($key, $filter) === false)
          continue;
        
        // we rename the keys as necessary
        if($filter !== false && $transform !== false)
          $outputKey = str_replace($filter, $transform, $key);
        else
          $outputKey = $key;
        
        $vals[$outputKey] = export_json($key);
      }

      echo json_encode($vals);
    }
  }

  // Redis Commands
  else {

    // Single key
    if (isset($_GET['key'])) {
      export_redis($_GET['key']);
    } else { // All keys
      $keys = $redis->keys('*');

      foreach ($keys as $key) {

        // if we have a filter and no match, we skip
        if($filter !== false && stripos($key, $filter) === false)
          continue;
        
        export_redis($key, $filter, $transform);
      }
    }
  }


  die;
}




$page['css'][] = 'frame';
$page['js'][]  = 'frame';

require 'includes/header.inc.php';

?>
<h2>Export <?php echo isset($_GET['key']) ? format_html($_GET['key']) : ''?></h2>

<form action="<?php echo format_html(getRelativePath('export.php'))?>" method="post">

<p>
<label for="type">Type:</label>
<select name="type" id="type">
<option value="redis" <?php echo (isset($_GET['type']) && ($_GET['type'] == 'redis')) ? 'selected="selected"' : ''?>>Redis</option>
<option value="json"  <?php echo (isset($_GET['type']) && ($_GET['type'] == 'json' )) ? 'selected="selected"' : ''?>>JSON</option>
</select>
</p> 

<?php if (!isset($_GET['key'])): ?>
  <p>
  <label for="filter">Filter:</label>
  <input type="text" name="filter" />
  </p>

  <p>
  <label for="transform">Tranform:</label>
  <input type="text" name="transform" />
  </p>
<?php endif; ?>

<p>
<input type="submit" class="button" value="Export">
</p>

</form>
<?php

require 'includes/footer.inc.php';

?>
