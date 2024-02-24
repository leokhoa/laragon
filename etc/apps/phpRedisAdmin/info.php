<?php

require_once 'includes/common.inc.php';




if (isset($_GET['reset'])) {
  $redis->config('resetstat');

  header('Location: info.php');
  die;
}



// Fetch the info
$info = $redis->info();
$alt  = false;




$page['css'][] = 'frame';
$page['js'][]  = 'frame';

require 'includes/header.inc.php';

?>
<h2>Info</h2>

<p>
<a href="?reset=1&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>" class="reset">Reset usage statistics</a>
</p>

<table>
<tr><th><div>Key</div></th><th><div>Value</div></th></tr>
<?php

foreach ($info as $key => $value) {
  if ($key == 'allocation_stats') { // This key is very long to split it into multiple lines
    $value = str_replace(',', ",\n", $value);
  }

  ?>
  <tr <?php echo $alt ? 'class="alt"' : ''?>><td><div><?php echo format_html($key)?></div></td><td><pre><?php echo format_html(is_array($value) ? print_r($value, true) : $value)?></pre></td></tr>
  <?php

  $alt = !$alt;
}

?>
</table>
<?php

require 'includes/footer.inc.php';

?>
