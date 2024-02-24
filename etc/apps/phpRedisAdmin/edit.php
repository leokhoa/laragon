<?php

require_once 'includes/common.inc.php';




// Are we editing or creating a new key?
$edit = false;

if (isset($_GET['key'], $_GET['type'])) {
  if (($_GET['type'] == 'string') ||
      (($_GET['type'] == 'hash') && isset($_GET['hkey']))  ||
      (($_GET['type'] == 'list') && isset($_GET['index'])) ||
      (($_GET['type'] == 'set' ) && isset($_GET['value'])) ||
      (($_GET['type'] == 'zset') && isset($_GET['value']))) {
    $edit = true;
  }
}




if (isset($_POST['type'], $_POST['key'], $_POST['value'])) {
  // Don't allow keys that are to long (Redis supports keys that can be way to long to put in an url).
  if (strlen($_POST['key']) > $config['maxkeylen']) {
    die('ERROR: Your key is to long (max length is '.$config['maxkeylen'].')');
  }

  $key   = input_convert($_POST['key']);
  $value = input_convert($_POST['value']);
  $value = encodeOrDecode('save', $key, $value);

  if ($value === false || is_null($value)) {
    die('ERROR: could not encode value');
  }

  // String
  if ($_POST['type'] == 'string') {
    $redis->set($key, $value);
  }

  // Hash
  else if (($_POST['type'] == 'hash') && isset($_POST['hkey'])) {
    if (strlen($_POST['hkey']) > $config['maxkeylen']) {
      die('ERROR: Your hash key is to long (max length is '.$config['maxkeylen'].')');
    }

    if ($edit && !$redis->hExists($key, input_convert($_POST['hkey']))) {
      $redis->hDel($key, input_convert($_GET['hkey']));
    }

    $redis->hSet($key, input_convert($_POST['hkey']), $value);
  }

  // List
  else if (($_POST['type'] == 'list') && isset($_POST['index'])) {
    $size = $redis->lLen($key);

    if (($_POST['index'] == '') ||
        ($_POST['index'] == $size)) {
      // Push it at the end
      $redis->rPush($key, $value);
    } else if ($_POST['index'] == -1) {
      // Push it at the start
      $redis->lPush($key, $value);
    } else if (($_POST['index'] >= 0) &&
               ($_POST['index'] < $size)) {
      // Overwrite an index
      $redis->lSet($key, input_convert($_POST['index']), $value);
    } else {
      die('ERROR: Out of bounds index');
    }
  }

  // Set
  else if ($_POST['type'] == 'set') {
    if ($_POST['value'] != $_POST['oldvalue']) {
      // The only way to edit a Set value is to add it and remove the old value.
      $redis->sRem($key, encodeOrDecode('save', $key, input_convert($_POST['oldvalue'])));
      $redis->sAdd($key, $value);
    }
  }

  // ZSet
  else if (($_POST['type'] == 'zset') && isset($_POST['score'])) {
    // The only way to edit a ZSet value is to add it and remove the old value.
    $redis->zRem($key, encodeOrDecode('save', $key, input_convert($_POST['oldvalue'])));
    $redis->zAdd($key, input_convert($_POST['score']), $value);
  }



  // Refresh the top so the key tree is updated.
  require 'includes/header.inc.php';

  ?>
  <script>
  top.location.href = top.location.pathname+'?view&s=<?php echo $server['id']?>&d=<?php echo $server['db']?>&key=<?php echo urlencode($_POST['key'])?>';
  </script>
  <?php

  require 'includes/footer.inc.php';
  die;
}




// Get the current value.
$value = '';

if ($edit) {
  // String
  if ($_GET['type'] == 'string') {
    $value = $redis->get($_GET['key']);
  }

  // Hash
  else if (($_GET['type'] == 'hash') && isset($_GET['hkey'])) {
    $value = $redis->hGet($_GET['key'], $_GET['hkey']);
  }

  // List
  else if (($_GET['type'] == 'list') && isset($_GET['index'])) {
    $value = $redis->lIndex($_GET['key'], $_GET['index']);
  }

  // Set, ZSet
  else if ((($_GET['type'] == 'set') || ($_GET['type'] == 'zset')) && isset($_GET['value'])) {
    $value = $_GET['value'];
  }

  $value = encodeOrDecode('load', $_GET['key'], $value);
}




$page['css'][] = 'frame';
$page['js'][]  = 'frame';

require 'includes/header.inc.php';

?>
<h2><?php echo $edit ? 'Edit' : 'Add'?></h2>
<form action="<?php echo format_html(getRelativePath('edit.php'))?>" method="post">

<p>
<label for="type">Type:</label>
<select name="type" id="type">
<option value="string" <?php echo (isset($_GET['type']) && ($_GET['type'] == 'string')) ? 'selected="selected"' : ''?>>String</option>
<option value="hash"   <?php echo (isset($_GET['type']) && ($_GET['type'] == 'hash'  )) ? 'selected="selected"' : ''?>>Hash</option>
<option value="list"   <?php echo (isset($_GET['type']) && ($_GET['type'] == 'list'  )) ? 'selected="selected"' : ''?>>List</option>
<option value="set"    <?php echo (isset($_GET['type']) && ($_GET['type'] == 'set'   )) ? 'selected="selected"' : ''?>>Set</option>
<option value="zset"   <?php echo (isset($_GET['type']) && ($_GET['type'] == 'zset'  )) ? 'selected="selected"' : ''?>>ZSet</option>
</select>
</p>

<p>
<label for="key">Key:</label>
<input type="text" name="key" id="key" size="30" <?php echo isset($_GET['key']) ? 'value="'.format_html($_GET['key']).'"' : ''?>>
</p>

<p id="hkeyp">
<label for="khey">Hash key:</label>
<input type="text" name="hkey" id="hkey" size="30" <?php echo isset($_GET['hkey']) ? 'value="'.format_html($_GET['hkey']).'"' : ''?>>
</p>

<p id="indexp">
<label for="index">Index:</label>
<input type="text" name="index" id="index" size="30" <?php echo isset($_GET['index']) ? 'value="'.format_html($_GET['index']).'"' : ''?>> <span class="info">empty to append, -1 to prepend</span>
</p>

<p id="scorep">
<label for="score">Score:</label>
<input type="text" name="score" id="score" size="30" <?php echo isset($_GET['score']) ? 'value="'.format_html($_GET['score']).'"' : ''?>>
</p>

<p>
<label for="value">Value:</label>
<textarea name="value" id="value" cols="80" rows="20"><?php echo format_html($value)?></textarea>
</p>

<input type="hidden" name="oldvalue" value="<?php echo format_html($value)?>">

<p>
<input type="submit" class="button" value="<?php echo $edit ? 'Edit' : 'Add'?>">
</p>

</form>
<?php

require 'includes/footer.inc.php';

?>
