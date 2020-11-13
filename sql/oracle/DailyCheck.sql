--  DailyCheck.sql
--  To be run each morning
--  Checks for:  Invalid objects
--               Incorrect location of objects
--               Free space
--               Over-extension
--
set linesize 78
set pagesize 150
--
COL biggest_mb FORMAT 99,999.9
COL default_tablespace FORMAT a25
COL file_name FORMAT a45
COL file_id format 999 heading ID#
COL free_space FORMAT 99,999.9
COL member FORMAT a45
COL min_mb FORMAT 99,999.9
COL name FORMAT a45
COL owner FORMAT a13
COL object_name FORMAT a30
COL percent_free FORMAT 999.9
COL temporary_tablespace FORMAT a25
COL total_mb FORMAT 99,999.9
COL username FORMAT a15
--
Select Sysdate, name from v$database;
--
PROMPT
PROMPT
PROMPT ------------ Check for invalid objects, by schema
--
select count(*) "Invalids", owner
from dba_objects
where status ='INVALID'
group by owner;
--
PROMPT
PROMPT
PROMPT ------------ Non-SYS tables in SYSTEM tablespace
--
 select a.owner,a.object_name, a.created,a.last_ddl_time
 from dba_objects a
 where concat(a.owner,a.object_name) =
 (  select concat(b.owner,b.table_name)
    from dba_tables b
    where b.owner <>'SYS'
    and b.tablespace_name = 'SYSTEM'
    and b.owner = a.owner
    and b.table_name = a.object_name);
--
PROMPT
PROMPT
PROMPT ------------ Users with SYSTEM as their default or temporary tablespace
--
SELECT username, temporary_tablespace,default_tablespace
from dba_users
where temporary_tablespace = 'SYSTEM'
or default_tablespace = 'SYSTEM';
--
Select 'Check for files in backup mode' " ", count(*) from v$backup
where status <>'NOT ACTIVE';
--
PROMPT
PROMPT ------------ Users with tables in temporary or rollback tablespaces
PROMPT

--
col "Owner and object" for a34
--SELECT owner|| '  '||object_name "Owner and table", created,
--  last_ddl_time modified
--
SELECT 'tables in wrong tablespaces is: '||count(*) "Owner and object"
FROM dba_objects
WHERE object_id IN
   (SELECT obj#
   FROM sys.tab$
   WHERE ts# IN
       (SELECT ts# FROM sys.ts$
        WHERE name IN
          (SELECT tablespace_name xyz
           FROM dba_rollback_segs
           WHERE tablespace_name <>'SYSTEM'
                UNION
           SELECT temporary_tablespace xyz
           FROM dba_users
           WHERE temporary_tablespace <>'SYSTEM')
        ) );
--
--  checks free space
--
PROMPT
PROMPT
PROMPT ------------ Free space fragmentation (in MBs) by Tablespace
--
select tablespace_name, sum(bytes)/1048576 total_mb, 
max(bytes)/1048576 biggest_mb, min(bytes)/1048576 min_mb,
count(*) N_Frags
from dba_free_space 
group by tablespace_name;
--
PROMPT
PROMPT
PROMPT ------------ Total and freespace (in MBs) by Tablespace
--
SELECT tablespace_name, sum(free_space)/sum(total_mb)*100 percent_free, 
       sum(free_space) free_space, sum(total_mb) total_mb
FROM (
      SELECT tablespace_name, sum(bytes)/1048576 total_mb,
          '  total' type, to_number('0') free_space
      FROM dba_data_files
      GROUP BY tablespace_name
           UNION
      SELECT tablespace_name, to_number('0') total_mb,
          'free' type , sum(bytes)/1048576 free_space
      FROM dba_free_space
      GROUP BY tablespace_name)
GROUP BY tablespace_name
ORDER BY 2;
--
PROMPT
PROMPT  ------------ Total free space in Database
PROMPT  
--
SELECT SUM(bytes)/1048576 total_mb 
  FROM dba_free_space;
--
--  report total database size
--
PROMPT
PROMPT
PROMPT  ------------ Free space, less SYSTEM, Temp, and RBS tablespaces
--
SELECT SUM(bytes)/1048576 total_mb FROM dba_free_space
WHERE tablespace_name NOT IN
   (SELECT temporary_tablespace xyz FROM dba_users
    UNION 
    SELECT tablespace_name xyz FROM dba_rollback_segs);
--
PROMPT
PROMPT
PROMPT  ------------ Check Total database space
--
SELECT SUM(bytes)/1048576 total_mb 
  FROM dba_data_files;
--
PROMPT
PROMPT
PROMPT  ------------ List data, control, and redo file information
PROMPT  -            files
--
SELECT file_id,file_name,bytes,status,tablespace_name 
FROM dba_data_files 
ORDER BY tablespace_name;
--
PROMPT -             control files
--
SELECT * FROM v$controlfile;
--
PROMPT -             redo logs
SELECT * from v$logfile;
-- 
PROMPT
PROMPT
PROMPT  ------------ list RBS information
--
SELECT * FROM dba_rollback_segs; 
--
-- get table(s) whose next extent is greater than its tablespaces
-- max-free-space
--
PROMPT
PROMPT
PROMPT  ------------ Tables whose next extent will be greater than max free space
--
SELECT tablespace_name, table_name, initial_extent, next_extent
  FROM sys.dba_tables A
  WHERE NEXT_EXTENT >
     (SELECT MAX(BYTES)
      FROM SYS.DBA_FREE_SPACE B
      WHERE B.TABLESPACE_NAME = A.TABLESPACE_NAME);
--
-- get index(es) whose next extent is greater than its tablespaces
-- max-free-space
--
PROMPT
PROMPT
PROMPT  ------------ Indexes whose next extent will over-extend available space
--
SELECT TABLESPACE_NAME,INDEX_NAME, INITIAL_EXTENT, NEXT_EXTENT FROM
SYS.DBA_INDEXES A
WHERE NEXT_EXTENT >
(SELECT MAX(BYTES)
  FROM SYS.DBA_FREE_SPACE B
WHERE B.TABLESPACE_NAME = A.TABLESPACE_NAME);
--
--  get all index information about any index that will over-extend
--
PROMPT
PROMPT
PROMPT  ------------ Index segment info from dba_indexes for over-extenders
--
SELECT  A.* 
FROM    DBA_INDEXES  A 
WHERE A.NEXT_EXTENT > 
(SELECT MAX(B.BYTES) 
FROM    DBA_FREE_SPACE  B 
WHERE A.TABLESPACE_NAME=B.TABLESPACE_NAME);
--
--  check tables with percent-increase greater than zero to
--  see if they will over-extend
--
PROMPT
PROMPT
PROMPT  ------------ Check tables with PCTINCREASE > 0 for over_extension
--
SELECT  A.* 
FROM    DBA_SEGMENTS  A, 
DBA_TABLES  C 
WHERE A.SEGMENT_NAME=C.TABLE_NAME 
AND C.PCT_INCREASE > 0 
AND  ((A.BYTES * C.PCT_INCREASE ) / 100) > 
(SELECT MAX(B.BYTES) 
FROM     DBA_FREE_SPACE  B 
WHERE  A.TABLESPACE_NAME=B.TABLESPACE_NAME) ;
--
--  check indexes with percent-increase greater than zero to
--  see if they will over-extend
--
PROMPT
PROMPT
PROMPT  ------------ Check indexes with PCTINCREASE > 0 for over_extension
--
SELECT  A.* 
FROM    DBA_SEGMENTS  A, 
DBA_INDEXES  C 
WHERE A.SEGMENT_NAME=C.INDEX_NAME 
AND C.PCT_INCREASE > 0 
AND  ((A.BYTES * C.PCT_INCREASE ) / 100) > 
(SELECT MAX(B.BYTES) 
FROM     DBA_FREE_SPACE  B 
WHERE  A.TABLESPACE_NAME=B.TABLESPACE_NAME);
--
--  get all table information about any table that will over-extend
--
PROMPT
PROMPT
PROMPT ------------ All table info from dba_tables for over extenders
--
SELECT  A.* 
FROM    DBA_TABLES  A 
WHERE A.NEXT_EXTENT > 
(SELECT MAX(B.BYTES) 
FROM    DBA_FREE_SPACE  B 
WHERE A.TABLESPACE_NAME=B.TABLESPACE_NAME);
--
--  get segments that are about to reach their max extents
--
PROMPT
PROMPT
PROMPT  ------------ Tables, indexes, etc within 50 of max extents
--
SELECT owner, segment_type, segment_name,
max_extents, extents, max_extents - extents
FROM dba_segments
WHERE max_extents - extents <50
AND   owner <> 'SYS'
AND   segment_type = 'CACHE'
ORDER BY 1,2,3;