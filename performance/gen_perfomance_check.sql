/* Performance tuning general queries: */

-----------------------------------------------------
-- CHECK alert log for errors:
-----------------------------------------------------

-----------------------------------------------------
--Check for the plan change :
-----------------------------------------------------
select SQL_ID, COST,to_char(TIMESTAMP,'dd-mon-yy hh24:mi:ss') as TIMESTAMP,PLAN_HASH_VALUE,ID from dba_hist_sql_plan where SQL_ID='&sql_id' 
order by timestamp;
select sql_id,count(*) from v$session group by sql_id;

-----------------------------------------------------
--Check the gather stats for the table :
-----------------------------------------------------
select OWNER,TABLE_NAME,TABLESPACE_NAME,NUM_ROWS,PARTITIONED,TEMPORARY,last_analyzed,degree,COMPRESSION,LOGGING from dba_tables where TABLE_NAME like '&table_name';
select count(*) from table_name;
exec DBMS_STATS.GATHER_TABLE_STATS (ownname =>'HR',tabname =>'EMPLOYEE',cascade =>true,estimate_percent => dbms_stats.auto_sample_size, method_opt=>'FOR ALL INDEXED COLUMNS SIZE AUTO', granularity => 'ALL', degree => 1);

-----------------------------------------------------
--Check ddl & check dba_modifications
-----------------------------------------------------
select OBJECT_NAME,OWNER,CREATED,LAST_DDL_TIME, TIMESTAMP,STATUS from dba_objects where OBJECT_NAME='&OBJECT_NAME';
select TABLE_NAME,TABLE_OWNER,INSERTS, UPDATES, DELETES,TIMESTAMP from dba_tab_modifications where TABLE_NAME='&TABLE_NAME';


-----------------------------------------------------
--Check top CPU Usage queries:
-----------------------------------------------------
col SQL_TEXT for a80
select SQL_ID,SQL_TEXT,EXECUTIONS,round(ELAPSED_TIME/1000000) ELAPSED_SECONDS,
round(CPU_TIME/1000000) CPU_SECONDS
from (select * from v$sql order by ELAPSED_TIME desc) where rownum <6;
