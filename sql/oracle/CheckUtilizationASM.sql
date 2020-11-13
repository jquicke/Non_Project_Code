select name, round(total_mb/1024,2) as tot_gb, round((total_mb-free_mb)/1024,2) as inuse_gb, 
round(free_mb/1024,2) as free_gb, round((free_mb/total_mb)*100,2)  as free_pct
from v$asm_diskgroup
order by name;