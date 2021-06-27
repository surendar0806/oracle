/*
replace the value found in between % __ % with appropriate values
*/

-- -------------------------------------------------------------------------------------------------------------
-- to the get the object details in paticular tablespce 
-- -------------------------------------------------------------------------------------------------------------

col OWNER for a20
col TABLESPACE_NAME for a20
set pages 1000
set linesize 300
col "Object Type" for a40
SELECT tablespace_name, owner, segment_type "Object Type",
       COUNT(owner) "Number of Objects",
       ROUND(SUM(bytes) / 1024 / 1024, 2) "Total Size in MB"
FROM   sys.dba_segments
WHERE  tablespace_name IN ('% tablespace_name %')
GROUP BY tablespace_name, owner, segment_type
ORDER BY tablespace_name, owner, segment_type;

-- -------------------------------------------------------------------------------------------------------------
-- to get the size of all tablespace
-- -------------------------------------------------------------------------------------------------------------
SELECT tablespace_name, SUM(NVL(bytes,0))/(1024*1024*1024) total_gb
    FROM dba_data_files
       GROUP BY tablespace_name

 desc DBA_TABLESPACE_USAGE_METRICS

-- -------------------------------------------------------------------------------------------------------------
-- To get the freespace and total space occupied by the tablespace
-- -------------------------------------------------------------------------------------------------------------
select
fs.tablespace_name "Tablespace", (df.totalspace - fs.freespace) "Used MB",fs.freespace "Free MB",
df.totalspace "Total MB",
((df.totalspace - fs.freespace)*100/ df.totalspace)"Used Percentage",
round(100 * (fs.freespace / df.totalspace)) "Pct. Free"
from
(select
tablespace_name,
round(sum(bytes) / 1048576) TotalSpace
from
dba_data_files
group by
tablespace_name
) df,
(select
tablespace_name,
round(sum(bytes) / 1048576) FreeSpace
from
dba_free_space
group by
tablespace_name
) fs
where
df.tablespace_name = fs.tablespace_name
order by 6;
