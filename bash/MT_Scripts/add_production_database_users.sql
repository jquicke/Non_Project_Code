# Name: add_production_database_users.sql 
# Function: add production database users 
# Author: James Quicke
# Version: 20130918

use mysql;

update user set password=PASSWORD('yuebUssUphCugUrkanca') WHERE User='root' and host = 'localhost';
update user set password=PASSWORD('yuebUssUphCugUrkanca') WHERE User='root' and host = '127.0.0.1';
update user set password=PASSWORD('yuebUssUphCugUrkanca') WHERE User='root' and host = '::1';
flush privileges;

create user 'dbadmin'@'127.0.0.1' identified by 'RyocMivsunlycticfupo';
create user 'dbadmin'@'localhost' identified by 'RyocMivsunlycticfupo';
create user 'dbadmin'@'%' identified by 'RyocMivsunlycticfupo';
flush privileges;

grant all on *.* to 'dbadmin'@'127.0.0.1';
grant all on *.* to 'dbadmin'@'localhost';
grant all on *.* to 'dbadmin'@'%';
update user set Grant_priv = 'Y' where user = 'dbadmin';
flush privileges;

create user 'mtadmin'@'prd-app-001' identified by 'Iy6MN4cceyLhtWzrQ0XRw3Yg5JyqTctF';
flush privileges;

grant select,update,insert on foo.* to 'mtadmin'@'prd-app-001';
flush privileges;

create user 'wpUser'@'prd-app-001' identified by 'kogsyiedoivNajIgelru';
flush privileges;

grant select,update,insert,delete on wordpress.* to wpUser@'prd-app-001';
flush privileges;

create user 'dataloader'@'prd-app-001' identified by 'LlQTcfSJ8ATizjDKCoCe29Vi';
grant all on foo.* to 'dataloader'@'prd-app-001';
grant all on wordpress.* to 'dataloader'@'prd-app-001';
grant select, insert, update on loadlogs.* to 'dataloader'@'prd-app-001';
grant file on *.* to 'dataloader'@'prd-app-001';
flush privileges;

grant all on foo.* to 'dataloader'@'prd-app-001';
grant all on wordpress.* to 'dataloader'@'prd-app-001';
grant file on *.* to 'dataloader'@'prd-app-001';
flush privileges;

create user 'cmpmgr'@'prd-app-001' identified by 'wjRSipeYXB2wEhhcFqw4';
flush privileges;

grant select,update,insert on foo.* to 'cmpmgr'@'prd-app-001';
grant delete on foo.campaign_category to 'cmpmgr'@'prd-app-001';
grant delete on foo.campaign_state to 'cmpmgr'@'prd-app-001';
grant delete on foo.campaign_product to 'cmpmgr'@'prd-app-001';
flush privileges;

create user 'mtyiiadmin'@'prd-app-001' identified by 'jke7nrS3aof5l67kVhTV';
grant all on mtyii.* to 'mtyiiadmin'@'prd-app-001';
grant all on mtyiitest.* to 'mtyiiadmin'@'prd-app-001';
flush privileges;

create user 'mtyiiadmin'@'localhost' identified by 'jke7nrS3aof5l67kVhTV';
grant all on mtyii.* to 'mtyiiadmin'@'localhost';
grant all on mtyiitest.* to 'mtyiiadmin'@'localhost';
flush privileges;
