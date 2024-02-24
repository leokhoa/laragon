<?php

require_once 'includes/common.inc.php';




// This mess could need some cleanup!
if (isset($_POST['commands'])) {
  // Append some spaces at the end to make sure we always have enough arguments for the last function.
  $commands = str_getcsv(str_replace(array("\r", "\n"), array('', ' '), $_POST['commands']).'    ', ' ');

  foreach ($commands as &$command) {
    $command = stripslashes($command);
  }
  unset($command);

  for ($i = 0; $i < count($commands); ++$i) {
    if (empty($commands[$i])) {
      continue;
    }

    $commands[$i] = strtoupper($commands[$i]);

    switch ($commands[$i]) {
      case 'SET': {
        $redis->set($commands[$i+1], $commands[$i+2]);
        $i += 2;
        break;
      }

      case 'HSET': {
        $redis->hSet($commands[$i+1], $commands[$i+2], $commands[$i+3]);
        $i += 3;
        break;
      }

      case 'LPUSH': {
        $redis->lPush($commands[$i+1], $commands[$i+2]);
        $i += 2;
        break;
      }

      case 'RPUSH': {
        $redis->rPush($commands[$i+1], $commands[$i+2]);
        $i += 2;
        break;
      }

      case 'LSET': {
        $redis->lSet($commands[$i+1], $commands[$i+2], $commands[$i+3]);
        $i += 3;
        break;
      }

      case 'SADD': {
        $redis->sAdd($commands[$i+1], $commands[$i+2]);
        $i += 2;
        break;
      }

      case 'ZADD': {
        $redis->zAdd($commands[$i+1], $commands[$i+2], $commands[$i+3]);
        $i += 3;
        break;
      }
    }
  }


  // Refresh the top so the key tree is updated.
  require 'includes/header.inc.php';

  ?>
  <script>
  top.location.href = top.location.pathname+'?overview&s=<?php echo $server['id']?>&d=<?php echo $server['db']?>';
  </script>
  <?php

  require 'includes/footer.inc.php';
  die;
}




$page['css'][] = 'frame';
$page['js'][]  = 'frame';

require 'includes/header.inc.php';

?>
<h2>Import</h2>
<form action="<?php echo format_html(getRelativePath('import.php'))?>" method="post">

<p>
<label for="commands">Commands:<br>
<br>
<span class="info">
Valid are:<br>
SET<br>
HSET<br>
LPUSH<br>
RPUSH<br>
LSET<br>
SADD<br>
ZADD
</span>
</label>
<textarea name="commands" id="commands" cols="80" rows="20"></textarea>
</p>

<p>
<input type="submit" class="button" value="Import">
</p>

</form>
<?php

require 'includes/footer.inc.php';

?>
