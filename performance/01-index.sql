--to check the index 
select owner,index_name,INDEX_TYPE,table_owner,table_name,TABLESPACE_NAME,TEMPORARY from dba_indexes where index_name='&INAME';

/* Index Info 
The longer an application has been successfully run, the more likely you are to have indexes that are no longer used or beneficial.
 Removing these indexes not only saves space but can also improve the performance of any DML operations.
*/

-- To check capture information on indexes usage
SELECT i.index_name, u.total_access_count tot_access, u.total_exec_count exec_cnt,
       u.bucket_0_access_count B0, u.bucket_1_access_count B1, u.bucket_2_10_access_count B2_10,
       u.bucket_11_100_access_count B11_100, u.bucket_101_1000_access_count B101_1K,
       u.bucket_1000_plus_access_count B1K, u.last_used
FROM    DBA_INDEX_USAGE u
RIGHT JOIN DBA_INDEXES i
ON     i.index_name = u.name 
WHERE  i.owner='&OWNER'
ORDER BY u.total_access_count;

-- To check the how often dba_index_usage gets updates
select * from v$INDEX_USAGE_INFO;

-- If you suspect index are not being useful.. dropping an index can be risky. 
ALTER INDEX prod_sub_idx INVISIBLE;
ALTER INDEX prod_sub_idx VISIBLE;

-- New indexes can be marked invisible until you have an opportunity to prove they improve performance
CREATE INDEX my_idx ON t(x, object_id) INVISIBLE; 
 
-- Test newly created invisible indexes by setting OPTIMIZER_USE_INVISBLE_INDEXES to TRUE
ALTER SESSION SET optimizer_use_invisible_indexes  = TRUE;