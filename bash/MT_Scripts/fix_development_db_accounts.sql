# Name: fix_dev_db_passwd.sql
# Function: change production database password to dev passwords
# Author: James Quicke
# Version: 20131004

use mysql;

update user set password=PASSWORD('BitMiethBiWekVunmij2') WHERE User='root' and host = 'localhost';
update user set password=PASSWORD('BitMiethBiWekVunmij2') WHERE User='root' and host = '127.0.0.1';
update user set password=PASSWORD('BitMiethBiWekVunmij2') WHERE User='root' and host = '::1';
flush privileges;

update user set password=PASSWORD('noyctyopVoypKethAubA') WHERE User='dbadmin' and host = 'localhost';
update user set password=PASSWORD('noyctyopVoypKethAubA') WHERE User='dbadmin' and host = '127.0.0.1';
update user set password=PASSWORD('noyctyopVoypKethAubA') WHERE User='dbadmin' and host = 'dev-app-001';
flush privileges;

grant all on *.* to 'dbadmin'@'127.0.0.1';
grant all on *.* to 'dbadmin'@'localhost';
grant all on *.* to 'dbadmin'@'%';
update user set grant_priv = 'Y' where user = 'dbadmin';
flush privileges;

update user set password=PASSWORD('pegyerEwhautEOnVigea') WHERE User='mtadmin' and host = 'dev-app-001';
grant select,update,insert on foo.* to 'mtadmin'@'dev-app-001';
flush privileges;

update user set password=PASSWORD('Rf98q5gBm42vsfaEnZJj') WHERE User='wpUser' and host = 'dev-app-001';
grant select,update,insert on wordpress.* to wpUser@'dev-app-001';
flush privileges;

update user set password=PASSWORD('rTbXAeUNqsEaFsLNpdxV9Ho8') WHERE User='dataloader' and host = 'dev-app-001';
grant all on foo.* to 'dataloader'@'dev-app-001';
grant all on wordpress.* to 'dataloader'@'dev-app-001';
grant select, insert, update on loadlogs.* to 'dataloader'@'dev-app-001';
grant file on *.* to 'dataloader'@'dev-app-001';
flush privileges;

update user set password=PASSWORD('rTbXAeUNqsEaFsLNpdxV9Ho8') WHERE User='dataloader' and host = 'localhost';
grant all on foo.* to 'dataloader'@'localhost';
grant all on wordpress.* to 'dataloader'@'localhost';
grant select, insert, update on loadlogs.* to 'dataloader'@'localhost';
grant file on *.* to 'dataloader'@'localhost';
flush privileges;

update user set password=PASSWORD('BRJHSAjK5UBPpIkX1JHI') WHERE User='mtyiiadmin' and host = 'dev-app-001';
grant all on mtyii.* to 'mtyiiadmin'@'dev-app-001';
grant all on mtyiitest.* to 'mtyiiadmin'@'dev-app-001';
flush privileges;

update user set password=PASSWORD('BRJHSAjK5UBPpIkX1JHI') WHERE User='mtyiiadmin' and host = 'localhost';
grant all on mtyii.* to 'mtyiiadmin'@'localhost';
grant all on mtyiitest.* to 'mtyiiadmin'@'localhost';
flush privileges;

update user set password=PASSWORD('4k4TVEQEdrpJcphj11Vb') WHERE User='mtyii' and host = 'localhost';
flush privileges;
grant all on mtyii.* to 'mtyii'@'localhost';
grant all on mtyiitest.* to 'mtyii'@'localhost';
flush privileges;

update user set password=PASSWORD('4k4TVEQEdrpJcphj11Vb') WHERE User='mtyii' and host = 'dev-app-001';
flush privileges;
grant all on mtyii.* to 'mtyii'@'dev-app-001';
grant all on mtyiitest.* to 'mtyii'@'dev-app-001';
flush privileges;
