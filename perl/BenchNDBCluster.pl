#!/usr/bin/perl

use DBI;

# database information
$db="opxdev";
$host="127.0.0.1";
$port="3306";
$userid="root";
$passwd="";
$connectionInfo="DBI:mysql:database=$db;$host:$port";

# make connection to database
$dbh = DBI->connect($connectionInfo,$userid,$passwd);

for($i=0;$i<10000;$i++) {
# prepare and execute query
$j=int(rand()*60000000);

$query = "update counter set hits=hits+1 where propertyid=$j";
$sth = $dbh->prepare($query);
$sth->execute();

$query = "SELECT * FROM counter where propertyid=$j";
$sth = $dbh->prepare($query);
$sth->execute();

# assign fields to variables
$sth->bind_columns(undef, \$propertyid, \$result);

# output computer list to the browser
while($sth->fetch()) {
   print "$result ";
}

}

$sth->finish();

# disconnect from database
$dbh->disconnect;
