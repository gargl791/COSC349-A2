#!/bin/bash

echo MYSQL_SERVER_IP=${mysql_server_ip} >> /etc/environment

echo "Setup of webserver VM has begun.">/var/log/user.log

apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql

cat <<'EOF' >/var/www/html/index.php
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<head><title>Webserver test page</title>
<style>
th { text-align: left; }

table, th, td {
  border: 2px solid grey;
  border-collapse: collapse;
}

th, td {
  padding: 0.2em;
}
</style>
</head>

<body>
<h1>Webserver test page.</h1>

<p>This page demonstrates that the webserver on your VM is generating content.</p>

<p>You likely now want to <a href="test-database.php">proceed to your webserver's
database connection testing page</a>. However, note that if there is a network problem reaching the database, the database connection testing page will spend a minute or so waiting before it produces any content.</p>

<p>For your assignment work, your project should begin on this page. The only reason the database testing page was not placed within <kbd>index.php</kbd> was to assist you in debugging any network problems you might be having.</p>

</body>
</html>
EOF

cat <<'EOF' >/var/www/html/index.php
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<head><title>Database test page</title>
<style>
th { text-align: left; }

table, th, td {
  border: 2px solid grey;
  border-collapse: collapse;
}

th, td {
  padding: 0.2em;
}
</style>
</head>

<body>
<h1>Database test page</h1>

<p>Showing contents of papers table:</p>

<table border="1">
<tr><th>Paper code</th><th>Paper name</th></tr>

<?php
 
$db_host   = '${mysql_server_ip}';
$db_name   = 'fvision';
$db_user   = 'webuser';
$db_passwd = 'insecure_db_pw';

$pdo_dsn = "mysql:host=$db_host;dbname=$db_name";

$pdo = new PDO($pdo_dsn, $db_user, $db_passwd);

$q = $pdo->query("SELECT * FROM papers");

while($row = $q->fetch()){
  echo "<tr><td>".$row["code"]."</td><td>".$row["name"]."</td></tr>\n";
}

?>
</table>
</body>
</html>
EOF

service apache2 restart

echo "Setup of webserver VM has completed.">/var/log/user.log
