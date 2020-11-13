USE master
GO
-- Declare a variable to store the database name returned by FETCH.
DECLARE @dbname sysname, @cmd varchar(1000)
 
-- Declare a cursor to populate with list of databases
DECLARE db_recovery_cursor CURSOR FOR
SELECT name from sysdatabases WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb') and status = 24
OPEN db_recovery_cursor
FETCH NEXT FROM db_recovery_cursor INTO @dbname
 
-- loop through cursor and execute command
WHILE @@FETCH_STATUS = 0
BEGIN
SET @cmd = 'ALTER DATABASE ' + @dbname + ' SET RECOVERY SIMPLE'
EXEC(@cmd)
PRINT @dbname
FETCH NEXT FROM db_recovery_cursor INTO @dbname
END
CLOSE db_recovery_cursor
DEALLOCATE db_recovery_curso