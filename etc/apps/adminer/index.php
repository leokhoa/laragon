<?php
/**
 * Laragon - Adminer
 *
 * phpMyAdmin only speaks MySQL, so PostgreSQL is administered from here.
 * Adminer itself lives in adminer.php - this wrapper only sets the defaults so
 * the login screen arrives pointed at Laragon's PostgreSQL service.
 *
 * MySQL still works: pick it from the driver list, or use /phpmyadmin.
 *
 * Served at http://localhost/adminer
 * (see etc/apache2/alias/adminer.conf and etc/nginx/alias/adminer.conf)
 */

define('LARAGON_PGSQL_SERVER', '127.0.0.1:5432');

// Adminer picks its driver from the query string key. When the request names no
// driver at all, land on PostgreSQL instead of Adminer's MySQL default.
$laragon_drivers = array(
	'server', 'mysql', 'sqlite', 'sqlite2', 'pgsql', 'oracle', 'mssql',
	'firebird', 'simpledb', 'mongo', 'elastic', 'clickhouse',
);
$laragon_has_driver = false;
foreach ($laragon_drivers as $laragon_driver) {
	if (isset($_GET[$laragon_driver])) {
		$laragon_has_driver = true;
		break;
	}
}
if (!$laragon_has_driver) {
	$_GET['pgsql'] = LARAGON_PGSQL_SERVER;
}

function adminer_object() {
	class LaragonAdminer extends \Adminer\Adminer
	{
		/** Fall back to Laragon's PostgreSQL service when the server box is left blank. */
		function credentials() {
			$credentials = parent::credentials();
			if ($credentials[0] === '' || $credentials[0] === null) {
				$credentials[0] = LARAGON_PGSQL_SERVER;
			}
			return $credentials;
		}

		/**
		 * Makes Adminer's "Permanent login" checkbox work - without this the
		 * feature errors out. The return value is the key the login cookie is
		 * encrypted with, so it is generated once and kept out of this file.
		 *
		 * Note this does NOT let Adminer connect with an empty password;
		 * Adminer refuses those outright. The postgres role needs a password
		 * set - see the PostgreSQL section of README.md.
		 */
		function permanentLogin($create = false) {
			$key_file = __DIR__ . '/.adminer-key';
			$key = @file_get_contents($key_file);
			if (!$key) {
				$key = bin2hex(random_bytes(32));
				@file_put_contents($key_file, $key);
			}
			return $key;
		}
	}

	return new LaragonAdminer();
}

include __DIR__ . '/adminer.php';
