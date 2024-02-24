<?php

require_once 'includes/common.inc.php';

if($redis) {

    if (!empty($server['keys'])) {
        $keys = $redis->keys($server['filter']);
    } else {
        $next = 0;
        $keys = array();

        while (true) {
            $r = $redis->scan($next, 'MATCH', $server['filter'], 'COUNT', $server['scansize']);

            $next = $r[0];
            $keys = array_merge($keys, $r[1]);

            if ($next == 0) {
                break;
            }
        }
    }

    sort($keys);

    $namespaces = array(); // Array to hold our top namespaces.

    // Build an array of nested arrays containing all our namespaces and containing keys.
    foreach ($keys as $key) {
      // Ignore keys that are to long (Redis supports keys that can be way to long to put in an url).
      if (strlen($key) > $config['maxkeylen']) {
        continue;
      }

      $key = explode($server['seperator'], $key);
      if ($config['showEmptyNamespaceAsKey'] && $key[count($key) - 1] == '') {
        array_pop($key);
        $key[count($key) - 1] .= ':';
      }

      // $d will be a reference to the current namespace.
      $d = &$namespaces;

      // We loop though all the namespaces for this key creating the array for each.
      // Each time updating $d to be a reference to the last namespace so we can create the next one in it.
      for ($i = 0; $i < (count($key) - 1); ++$i) {
        if (!isset($d[$key[$i]])) {
          $d[$key[$i]] = array();
        }

        $d = &$d[$key[$i]];
      }

      // Nodes containing an item named __phpredisadmin__ are also a key, not just a directory.
      // This means that creating an actual key named __phpredisadmin__ will make this bug.
      $d[$key[count($key) - 1]] = array('__phpredisadmin__' => true);

      // Unset $d so we don't accidentally overwrite it somewhere else.
      unset($d);
    }

    // Recursive function used to print the namespaces.
    function print_namespace($item, $name, $fullkey, $islast) {
      global $config, $server, $redis;

      // Is this also a key and not just a namespace?
      if (isset($item['__phpredisadmin__'])) {
        // Unset it so we won't loop over it when printing this namespace.
        unset($item['__phpredisadmin__']);

        $class = array();
        $len   = false;

        if (isset($_GET['key']) && ($fullkey == $_GET['key'])) {
          $class[] = 'current';
        }
        if ($islast) {
          $class[] = 'last';
        }

        // Get the number of items in the key.
        if (!isset($config['faster']) || !$config['faster']) {
          switch ($redis->type($fullkey)) {
            case 'hash':
              $len = $redis->hLen($fullkey);
              break;

            case 'list':
              $len = $redis->lLen($fullkey);
              break;

            case 'set':
              $len = $redis->sCard($fullkey);
              break;

            case 'zset':
              $len = $redis->zCard($fullkey);
              break;
          }
        }

        if (empty($name) && $name != '0') {
          $name = '<empty>';
          $class[] = 'empty';
        }

        ?>
        <li<?php echo empty($class) ? '' : ' class="'.implode(' ', $class).'"'?>>
        <input type="checkbox" name="checked_keys" value="<?php echo $fullkey?>"/>
        <a href="?view&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>&amp;key=<?php echo urlencode($fullkey)?>" title="<?php echo format_html($name)?>"><?php echo format_html($name)?><?php if ($len !== false) { ?><span class="info">(<?php echo $len?>)</span><?php } ?></a>
        </li>
        <?php
      }

      // Does this namespace also contain subkeys?
      if (count($item) > 0) {
        ?>
        <li class="folder<?php echo ($fullkey === '') ? '' : ' collapsed'?><?php echo $islast ? ' last' : ''?>">
        <div class="icon"><?php echo format_html($name)?>&nbsp;<span class="info">(<?php echo count($item)?>)</span>
        <?php if ($fullkey !== '') { ?><a href="delete.php?s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>&amp;tree=<?php echo urlencode($fullkey).$server['seperator']?>" class="deltree"><img src="images/delete.png" width="10" height="10" title="Delete tree" alt="[X]"></a><?php } ?>
        </div><ul>
        <?php

        $l = count($item);

        foreach ($item as $childname => $childitem) {
          // $fullkey will be empty on the first call.
          if ($fullkey === '') {
            $childfullkey = $childname;
          } else {
            $childfullkey = $fullkey.$server['seperator'].$childname;
          }

          print_namespace($childitem, $childname, $childfullkey, (--$l == 0));
        }

        ?>
        </ul>
        </li>
        <?php
      }
    }

    function getDbInfo($d, $info, $padding = '') {
      global $config, $server;
      $prefix = "database ";
      $db = "db$d";

      $dbHasData = array_key_exists("db$d", $info['Keyspace']);

      if (!$dbHasData && ((isset($server['hide']) && $server['hide']) || (!isset($server['hide']) && $config['hideEmptyDBs']))) {
        return false; // we don't show empty dbs, so return false to tell the caller to continue the loop
      }

      $dbinfo = sprintf("$prefix%'.-${padding}d", $d);
      if ($dbHasData) {
        $dbinfo = sprintf("%s (%d)", $dbinfo, $info['Keyspace'][$db]['keys']);
      }
      $dbinfo = str_replace('.', '&nbsp;&nbsp;', $dbinfo); // 2 spaces per character are needed to get the alignment right

      return $dbinfo;
    }

}  // if redis



// This is basically the same as the click code in index.js.
// Just build the url for the frame based on our own url.
if (count($_GET) == 0) {
  $iframe = 'overview.php';
} else {
  $iframe = substr($_SERVER['REQUEST_URI'], strpos($_SERVER['REQUEST_URI'], '?') + 1);

  if (strpos($iframe, '&') !== false) {
    $iframe = substr_replace($iframe, '.php?', strpos($iframe, '&'), 1);
  } else {
    $iframe .= '.php';
  }
}



$page['css'][] = 'index';
$page['js'][]  = 'index';
$page['js'][]  = 'jquery-cookie';

require 'includes/header.inc.php';

?>
<div id="sidebar">
<div id="header">
<h1 class="logo"><a href="?overview&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>">phpRedisAdmin</a></h1>

<p>
<select id="server">
<?php foreach ($config['servers'] as $i => $srv) { ?>
<option value="<?php echo $i?>" <?php echo ($server['id'] == $i) ? 'selected="selected"' : ''?>><?php echo isset($srv['name']) ? format_html($srv['name']) : $srv['host'].':'.$srv['port']?></option>
<?php } ?>
</select>

<?php if($redis) { ?>

<?php
if (isset($server['databases'])) {
  $databases = $server['databases'];
} else {
  $databases = $redis->config('GET', 'databases');
  $databases = $databases['databases'];
}
$info = $redis->info(); $len = strlen((string)($databases-1));
if ($databases > 1) { ?>
  <select id="database">
  <?php for ($d = 0; $d < $databases; ++$d) { if (($dbinfo=getDbInfo($d, $info, $len)) === false) continue; ?>
  <option value="<?php echo $d?>" <?php echo ($server['db'] == $d) ? 'selected="selected"' : ''?>><?php echo "$dbinfo"; ?></option>
  <?php } ?>
  </select>
<?php } ?>
</p>

<p>
<?php if (isset($login)) { ?>
<a href="logout.php"><img src="images/logout.png" width="16" height="16" title="Logout" alt="[L]"></a>
<?php } ?>
<a href="?info&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>"><img src="images/info.png" width="16" height="16" title="Info" alt="[I]"></a>
<a href="?export&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>"><img src="images/export.png" width="16" height="16" title="Export" alt="[E]"></a>
<a href="?import&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>"><img src="images/import.png" width="16" height="16" title="Import" alt="[I]"></a>
<?php if (isset($server['flush']) && $server['flush']) { ?>
<a href="?flush&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>" id="flush"><img src="images/flush.png" width="16" height="16" title="Flush" alt="[F]"></a>
<?php } ?>
</p>

<p>
<a href="?edit&amp;s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>" class="add">Add another key</a>
</p>

<p>
<input type="text" id="server_filter" size="14" value="<?php echo format_html($server['filter']); ?>" placeholder="type here to server filter" class="info">
<button id="btn_server_filter">Filter!</button>
</p>

<p>
<input type="text" id="filter" size="24" value="type here to filter" placeholder="type here to filter" class="info">
</p>
<button id="selected_all_keys">Select all</button>
<button id="operations">
<a href="delete.php?s=<?php echo $server['id']?>&amp;d=<?php echo $server['db']?>&batch_del=1" class="batch_del">Delete selected<img src="images/delete.png" style="width: 1em;height: 1em;vertical-align: middle;" title="Delete selected" alt="[X]"></a>
</button>
</div>
<div id="keys">
<ul>
<?php print_namespace($namespaces, 'Keys', '', empty($namespaces))?>
</ul>
</div><!-- #keys -->

<?php } else { ?>
</p>
<div style="color:red">Can't connect to this server</div>
<?php } ?>

</div><!-- #sidebar -->

<div id="resize"></div>
<div id="resize-layover"></div>

<div id="frame">
<iframe src="<?php echo format_html($iframe)?>" id="iframe" frameborder="0" scrolling="0"></iframe>
</div><!-- #frame -->

<?php

require 'includes/footer.inc.php';

?>
