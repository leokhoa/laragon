<?php

require_once 'includes/common.inc.php';




if (isset($_POST['old'], $_POST['key'])) {
  if (strlen($_POST['key']) > $config['maxkeylen']) {
    die('ERROR: Your key is to long (max length is '.$config['maxkeylen'].')');
  }

  $redis->rename($_POST['old'], $_POST['key']);


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



$page['css'][] = 'frame';
$page['js'][]  = 'frame';

require 'includes/header.inc.php';

?>
<h2>Edit Name of <?php echo format_html($_GET['key'])?></h2>
<form action="<?php echo format_html(getRelativePath('rename.php'))?>" method="post">

<input type="hidden" name="old" value="<?php echo format_html($_GET['key'])?>">

<p>
<label for="key">Key:</label>
<input type="text" name="key" id="key" size="30" <?php echo isset($_GET['key']) ? 'value="'.format_html($_GET['key']).'"' : ''?>>
</p>

<p>
<input type="submit" class="button" value="Rename">
</p>

</form>
<?php

require 'includes/footer.inc.php';

?>
