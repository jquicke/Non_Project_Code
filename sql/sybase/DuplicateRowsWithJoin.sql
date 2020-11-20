-- find duplicate rows with join

select distinct(a.user_store_id) 
from user_store a 
join user_store b on a.user_id = b.user_id 
where a.user_store_id != b.user_store_id 
and a.store_id = b.store_id 
and a.user_id = b.user_id;