#!/usr/bin/env php
<?php
/*
 * Just a tiny tool to check password hashes from PocketMine's SimpleAuth plugin
 * SimpleAuth (2014) used SHA-512 xored with Whirlpool when registering players and left files containing user info this format:
 *
 *
 * ---
 * registerdate:
 * logindate:
 * lastip:
 * hash:
 * ...
 *
 *
 * This was written to aid bruteforcing hashes, please use responsibly. @Xeb3rnium
*/

$player = readline("Username: ");
$password = readline("Password: ");

function auth($salt, $password)
{
	return bin2hex(hash("sha512", $password . $salt, true) ^ hash("whirlpool", $salt . $password, true));
}

$result = auth(strtolower($player), $password);
echo "Hash: " . $result . "\n";

?>