SELECT   d.tablespace_name
        ,(a.bytes/1024/1024) available
        ,(a.ubytes/1024/1024) actual
        ,NVL((a.ubytes/1024/1024)-(NVL(f.bytes,0)/1024/1024),0) used
        ,(a.bytes - a.ubytes + NVL(f.bytes, 0)) / 1048576 free
        ,((a.ubytes - NVL(f.bytes,0)) / a.bytes * 100) pct_used
        ,case when ((a.ubytes - NVL(f.bytes,0)) / a.ubytes * 100) > 92.5 
then '*
' end flag
FROM     sys.dba_tablespaces d
        ,(
                SELECT   tablespace_name
                        ,SUM(bytes) ubytes
                        ,SUM(DECODE(autoextensible,'YES',maxbytes,bytes)) 
bytes
                FROM     dba_data_files
                GROUP BY tablespace_name
         ) a
        ,(
                SELECT   tablespace_name
                        ,SUM(bytes) bytes
                FROM     dba_free_space
                GROUP BY tablespace_name
         ) f
WHERE   d.tablespace_name = a.tablespace_name
AND     d.tablespace_name = f.tablespace_name(+)
ORDER BY d.tablespace_name