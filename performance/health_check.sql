------------------------------------------------------------------------------------------------------------------------------------------------------
---
--- one script to Identify all performace issue related to sql query
------
--
--
------------------------------------------------------------------------------------------------------------------------------------------------------

Set echo off
set trimspool on
set define on

column filename new_val filename
select to_char(sysdate, 'yyyymmdd-hh-mi-ss' ) filename from dual;
column dbname new_value dbname noprint
select name dbname from v$pdbs;
spool &dbname-&filename..txt

PROMPT ==================
PROMPT DB INFO
PROMPT ==================

set lines 750 pages 9999
select name CDB_NAME,(select name from v$pdbs) PDB_NAME,database_role from v$database;
select INSTANCE_NAME,HOST_NAME,logins,VERSION from v$instance;

PROMPT ==================
PROMPT TOTAL Connections
PROMPT ==================

set lines 750 pages 9999
break on report
compute SUM of tot on report
compute SUM of active on report
compute SUM of inactive on report
col username for a50
select DECODE(username,NULL,'INTERNAL',USERNAME) Username,
count(*) TOT,
COUNT(DECODE(status,'ACTIVE',STATUS)) ACTIVE,
COUNT(DECODE(status,'INACTIVE',STATUS)) INACTIVE
from gv$session
where status in ('ACTIVE','INACTIVE')
group by username;

PROMPT ================
PROMPT Session Details
PROMPT ================

set linesize 750 pages 9999
column box format a30
col serial# for 999999
column spid format a10
column username format a30
column program format a30
column os_user format a20
col LOGON_TIME for a20

select b.inst_id,b.sid,b.serial#,a.spid, substr(b.machine,1,30) box,to_char (b.logon_time, 'dd-mon-yyyy hh24:mi:ss') logon_time,
substr(b.username,1,30) username,
substr(b.osuser,1,20) os_user,
substr(b.program,1,30) program,status,b.last_call_et AS last_call_et_secs,b.sql_id
from gv$session b,gv$process a
where b.paddr = a.addr
and a.inst_id = b.inst_id
and type='USER'
order by b.inst_id,b.sid;

PROMPT ================
PROMPT Sql Details
PROMPT ================

column sid format 9999
column username format a15
column PARSING_SCHEMA_NAME format a15
column sql_text format a50
column module format a35
select a.inst_id,a.sid,a.username,b.PARSING_SCHEMA_NAME,a.module,a.sql_id,a.sql_child_number child,b.hash_value,to_char (a.sql_exec_start, 'dd-Mon-yyyy hh24:mi:ss') sql_exec_start,(sysdate-sql_exec_start)*24*60*60 SECS,b.rows_processed,a.status,substr(b.sql_text,1,50) sql_text
from gv$session a,gv$sqlarea b
where a.sql_hash_value = b.hash_value
and a.sql_address = b.address
and a.module not like '%emagent%'
and a.module not like '%oraagent.bin%'
and a.username is not null
order by a.status;

PROMPT =========================
PROMPT Sql Monitor - REPORT
PROMPT =========================

column text_line format a1000
set lines 750 pages 9999
set long 20000 longchunksize 20000
select dbms_sqltune.report_sql_monitor_list() text_line from dual;

PROMPT =========================
PROMPT Sql Monitor - Executing
PROMPT =========================

set lines 1000 pages 9999
column sid format 9999
column serial for 999999
column status format a15
column username format a10
column sql_text format a80
column module format a30
col program for a30
col SQL_EXEC_START for a20

SELECT * FROM
(SELECT status,inst_id,sid,SESSION_SERIAL# as Serial,username,sql_id,SQL_PLAN_HASH_VALUE,
program,
TO_CHAR(sql_exec_start,'dd-mon-yyyy hh24:mi:ss') AS sql_exec_start,
ROUND(elapsed_time/1000000) AS "Elapsed (s)",
ROUND(cpu_time /1000000) AS "CPU (s)",
substr(sql_text,1,30) sql_text
FROM gv$sql_monitor where status='EXECUTING' and module not like '%emagent%'
ORDER BY sql_exec_start desc
);

PROMPT ================
PROMPT Blocking Session
PROMPT ================

set lines 750 pages 9999
col blocking_status for a100
select s1.inst_id,s2.inst_id,s1.username || '@' || s1.machine
|| ' ( SID=' || s1.sid || ' ) is blocking '
|| s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status
from gv$lock l1, gv$session s1, gv$lock l2, gv$session s2
where s1.sid=l1.sid and s2.sid=l2.sid and s1.inst_id=l1.inst_id and s2.inst_id=l2.inst_id
and l1.BLOCK=1 and l2.request > 0
and l1.id1 = l2.id1
and l2.id2 = l2.id2
order by s1.inst_id;

PROMPT ==============================================================================
PROMPT More Details
PROMPT ==============================================================================

accept sid default '' -
prompt 'Please provide the sid: '

accept inst_id default '' -
prompt 'Please provide the inst_id: '

PROMPT ================
PROMPT SID Details
PROMPT ================

column box format a30
column spid format a10
column username format a20
column program format a30
column os_user format a20
col LOGON_TIME for a20

select b.inst_id,b.sid,b.serial#,a.spid, substr(b.machine,1,30) box,to_char (b.logon_time, 'dd-mon-yyyy hh24:mi:ss') logon_time,
substr(b.username,1,20) username,
substr(b.osuser,1,20) os_user,
substr(b.program,1,30) program,status,b.last_call_et AS last_call_et_secs,b.sql_id
from gv$session b,gv$process a
where b.paddr = a.addr
and a.inst_id = b.inst_id
and type='USER' and b.sid=&sid
and b.inst_id=&inst_id
order by logon_time;




column sid format 9999
column username format a15
column PARSING_SCHEMA_NAME format a15
column sql_text format a50
column module format a35
select a.inst_id,a.sid,a.username,b.PARSING_SCHEMA_NAME,a.module,a.sql_id,a.sql_child_number child,b.hash_value,to_char (a.sql_exec_start, 'dd-Mon-yyyy hh24:mi:ss') sql_exec_start,(sysdate-sql_exec_start)*24*60*60 SECS,b.rows_processed,a.status,substr(b.sql_text,1,50) sql_text
from gv$session a,gv$sqlarea b
where a.sql_hash_value = b.hash_value
and a.sql_address = b.address
and a.sid=&sid
and a.inst_id=&inst_id
and a.module not like '%emagent%'
and a.module not like '%oraagent.bin%'
and a.username is not null
order by a.status;

accept sql_id default '' -
prompt 'Please provide the sql_id: '

PROMPT ================
PROMPT SID Waiting on
PROMPT ================

COLUMN username FORMAT A20
COLUMN sid FORMAT 9999
COLUMN serial# FORMAT 999999
COLUMN event FORMAT A40

SELECT NVL(s.username, '(oracle)') AS username,
s.sid,
s.serial#,
se.event,
se.total_waits,
se.total_timeouts,
se.time_waited,
se.average_wait,
se.max_wait,
se.time_waited_micro
FROM gv$session_event se,
gv$session s
WHERE s.sid = se.sid
AND s.sid = &sid
and s.inst_id=se.inst_id
and s.inst_id=&inst_id
ORDER BY se.time_waited DESC
/

col WAIT_CLASS for a10
SELECT sw.inst_id,NVL(s.username, '(oracle)') AS username,
s.sid,
s.serial#,
sw.event,
sw.wait_class,
sw.wait_time,
sw.seconds_in_wait,
sw.state
FROM gv$session_wait sw,
gv$session s
WHERE s.sid = sw.sid and s.inst_id=sw.inst_id and s.sid=&sid
and s.inst_id=&inst_id
ORDER BY sw.seconds_in_wait DESC;

PROMPT ================
PROMPT Session LongOps
PROMPT ================

SET VERIFY OFF

SELECT a.sid,RPAD(a.opname,30),a.sofar,a.totalwork,a.ELAPSED_SECONDS,ROUND(((a.sofar)*100)/a.totalwork,3) "%_COMPLETED",time_remaining,
RPAD(a.username,10) username,a.SQL_HASH_VALUE,B.STATUS
FROM GV$SESSION_LONGOPS a, gv$session b
WHERE a.sid=&sid
and b.inst_id=&inst_id
AND a.sofar<> a.totalwork
/

PROMPT ==============================
PROMPT RealTime Monitoring For Sid
PROMPT ===============================

SELECT *
FROM
(SELECT status,
--username,
sql_id,
sql_exec_id,
TO_CHAR(sql_exec_start,'dd-mon-yyyy hh24:mi:ss') AS sql_exec_start,
ROUND(elapsed_time/1000000) AS "Elapsed (s)",
ROUND(cpu_time /1000000) AS "CPU (s)",
buffer_gets,
ROUND(physical_read_bytes /(1024*1024)) AS "Phys reads (MB)",
ROUND(physical_write_bytes/(1024*1024)) AS "Phys writes (MB)"
FROM gv$sql_monitor where sid=&sid and inst_id=&inst_id
ORDER BY elapsed_time DESC
)
WHERE rownum<=20;

SELECT ROUND(elapsed_time /1000000) AS "Elapsed (s)",
ROUND(cpu_time /1000000,3) AS "CPU (s)",
ROUND(queuing_time /1000000,3) AS "Queuing (s)",
ROUND(user_io_wait_time /1000000,3) AS "I/O wait (s)",
ROUND(application_wait_time/1000000,3) AS "Appli wait (s)",
ROUND(concurrency_wait_time/1000000,3) AS "Concurrency wait (s)",
ROUND(cluster_wait_time /1000000,3) AS "Cluster wait (s)",
ROUND(physical_read_bytes /(1024*1024)) AS "Phys reads (MB)",
ROUND(physical_write_bytes /(1024*1024)) AS "Phys writes (MB)",
buffer_gets AS "Buffer gets",
ROUND(plsql_exec_time/1000000,3) AS "Plsql exec (s)",
ROUND(java_exec_time /1000000,3) AS "Java exec (s)"
FROM gv$sql_monitor
WHERE sid=&sid and inst_id=&inst_id;

PROMPT ================================
PROMPT SQL_MONITOR REPORT
PROMPT ================================

set pagesize 0 echo off timing off linesize 1000 trimspool on trim on long 2000000 longchunksize 2000000
select
DBMS_SQLTUNE.REPORT_SQL_MONITOR(
sql_id=>'&sql_id',
report_level=>'ALL',
type=>'TEXT')
from dual;

PROMPT ================================
PROMPT Full sql statement
PROMPT ================================

set lines 1000 pages 9999
set long 20000
col sql_text for a500
select sql_text from dba_hist_sqltext where sql_id = '&sql_id';

PROMPT ================
PROMPT Bind Variables
PROMPT ================

col VALUE_STRING for a50
SELECT NAME,POSITION,DATATYPE_STRING,VALUE_STRING FROM gv$sql_bind_capture WHERE sql_id='&sql_id' and inst_id=&inst_id;

PROMPT ================
PROMPT SQL History
PROMPT ================

set lines 1000 pages 9999
COL instance_number FOR 9999 HEA 'Inst';
COL end_time HEA 'End Time';
COL plan_hash_value HEA 'Plan|Hash Value';
COL executions_total FOR 999,999 HEA 'Execs|Total';
COL rows_per_exec HEA 'Rows Per Exec';
COL et_secs_per_exec HEA 'Elap Secs|Per Exec';
COL cpu_secs_per_exec HEA 'CPU Secs|Per Exec';
COL io_secs_per_exec HEA 'IO Secs|Per Exec';
COL cl_secs_per_exec HEA 'Clus Secs|Per Exec';
COL ap_secs_per_exec HEA 'App Secs|Per Exec';
COL cc_secs_per_exec HEA 'Conc Secs|Per Exec';
COL pl_secs_per_exec HEA 'PLSQL Secs|Per Exec';
COL ja_secs_per_exec HEA 'Java Secs|Per Exec';
SELECT 'gv$dba_hist_sqlstat' source,h.instance_number,
TO_CHAR(CAST(s.begin_interval_time AS DATE), 'DD-MM-YYYY HH24:MI') snap_time,
TO_CHAR(CAST(s.end_interval_time AS DATE), 'DD-MM-YYYY HH24:MI') end_time,
h.sql_id,
h.plan_hash_value,
h.executions_total,
TO_CHAR(ROUND(h.rows_processed_total / h.executions_total), '999,999,999,999') rows_per_exec,
TO_CHAR(ROUND(h.elapsed_time_total / h.executions_total / 1e6, 3), '999,990.000') et_secs_per_exec,
TO_CHAR(ROUND(h.cpu_time_total / h.executions_total / 1e6, 3), '999,990.000') cpu_secs_per_exec,
TO_CHAR(ROUND(h.iowait_total / h.executions_total / 1e6, 3), '999,990.000') io_secs_per_exec,
TO_CHAR(ROUND(h.clwait_total / h.executions_total / 1e6, 3), '999,990.000') cl_secs_per_exec,
TO_CHAR(ROUND(h.apwait_total / h.executions_total / 1e6, 3), '999,990.000') ap_secs_per_exec,
TO_CHAR(ROUND(h.ccwait_total / h.executions_total / 1e6, 3), '999,990.000') cc_secs_per_exec,
TO_CHAR(ROUND(h.plsexec_time_total / h.executions_total / 1e6, 3), '999,990.000') pl_secs_per_exec,
TO_CHAR(ROUND(h.javexec_time_total / h.executions_total / 1e6, 3), '999,990.000') ja_secs_per_exec
FROM dba_hist_sqlstat h,
dba_hist_snapshot s
WHERE h.sql_id = '&sql_id'
AND h.executions_total > 0
AND s.snap_id = h.snap_id
AND s.dbid = h.dbid
AND s.instance_number = h.instance_number
UNION ALL
SELECT 'gv$sqlarea_plan_hash' source,h.inst_id,
TO_CHAR(sysdate, 'DD-MM-YYYY HH24:MI') snap_time,
TO_CHAR(sysdate, 'DD-MM-YYYY HH24:MI') end_time,
h.sql_id,
h.plan_hash_value,
h.executions,
TO_CHAR(ROUND(h.rows_processed / h.executions), '999,999,999,999') rows_per_exec,
TO_CHAR(ROUND(h.elapsed_time / h.executions / 1e6, 3), '999,990.000') et_secs_per_exec,
TO_CHAR(ROUND(h.cpu_time / h.executions / 1e6, 3), '999,990.000') cpu_secs_per_exec,
TO_CHAR(ROUND(h.USER_IO_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') io_secs_per_exec,
TO_CHAR(ROUND(h.CLUSTER_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') cl_secs_per_exec,
TO_CHAR(ROUND(h.APPLICATION_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') ap_secs_per_exec,
TO_CHAR(ROUND(h.CLUSTER_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') cc_secs_per_exec,
TO_CHAR(ROUND(h.PLSQL_EXEC_TIME / h.executions / 1e6, 3), '999,990.000') pl_secs_per_exec,
TO_CHAR(ROUND(h.JAVA_EXEC_TIME / h.executions / 1e6, 3), '999,990.000') ja_secs_per_exec
FROM gv$sqlarea_plan_hash h
WHERE h.sql_id = '&sql_id'
and h.inst_id=&inst_id
AND h.executions > 0
order by source ;

PROMPT ================================
PROMPT Sql_id waiting on ?
PROMPT ================================

select
sql_id,event,
time_waited "time_waited(s)",
case when time_waited = 0 then
0
else
round(time_waited*100 / sum(time_waited) Over(), 2)
end "percentage"
from
(
select sql_id,event, sum(time_waited) time_waited
from gv$active_session_history
where sql_id = '&sql_id' and
inst_id=&inst_id
group by sql_id,event
)
order by
time_waited desc;

PROMPT ================================
PROMPT Object Statistics
PROMPT ================================

col table_name for a40
col owner for a30
select distinct owner, table_name, STALE_STATS, last_analyzed, stattype_locked
from dba_tab_statistics
where (owner, table_name) in
(select distinct owner, table_name
from dba_tables
where ( table_name)
in ( select object_name
from gv$sql_plan
where upper(sql_id) = upper('&sql_id') and inst_id=&inst_id and object_name is not null))
--and STALE_STATS='YES'
/

col index_name for a50
SELECT owner, index_name, table_name,last_analyzed, sample_size, num_rows, partitioned, global_stats
FROM dba_indexes
WHERE index_name IN (
select distinct rtrim(substr(plan_table_output, instr(plan_table_output, '|', 1, 3)+2, (instr(plan_table_output, '|', 1, 4)-instr(plan_table_output, '|', 1, 3)-2)), ' ')
from (
SELECT plan_table_output
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', null, 'BASIC'))
UNION ALL
SELECT * FROM TABLE(dbms_xplan.display_awr('&sql_id', null, null, 'ALL'))
)
where plan_table_output like '%INDEX%'
)
ORDER BY owner, table_name, index_name
/

PROMPT ================================
PROMPT Explain Plan from Memory
PROMPT ================================

col PLAN FOR a150
SELECT
RPAD('(' || p.plan_line_ID || ' ' || NVL(p.plan_parent_id,'0') || ')',8) || '|' ||
RPAD(LPAD (' ', 2*p.plan_DEPTH) || p.plan_operation || ' ' || p.plan_options,60,'.') ||
NVL2(p.plan_object_owner||p.plan_object_name, '(' || p.plan_object_owner|| '.' || p.plan_object_name || ') ', '') ||
NVL2(p.plan_COST,'Cost:' || p.plan_COST,'') || ' ' ||
NVL2(p.plan_bytes||p.plan_CARDINALITY,'(' || p.plan_bytes || ' bytes, ' || p.plan_CARDINALITY || ' rows)','') || ' ' ||
NVL2(p.plan_partition_start || p.plan_partition_stop,' PStart:' || p.plan_partition_start || ' PStop:' || p.plan_partition_stop,'') ||
NVL2(p.plan_time, p.plan_time || '(s)','') AS PLAN
FROM gv$sql_plan_monitor p
WHERE sid=&sid
and p.inst_id=&inst_id
ORDER BY p.plan_line_id, p.plan_parent_id;

select * from table(dbms_xplan.display_cursor('&sql_id', NULL, 'ALLSTATS LAST'));

PROMPT ================================
PROMPT Explain Plan from AWR
PROMPT ================================

select * from table(dbms_xplan.display_awr('&sql_id', NULL, null, 'ALLSTATS LAST'));

PROMPT ================================
PROMPT Sql Profiles
PROMPT ================================

set lines 1000 pages 9999
col name for a30
col task_exec_name for a16
col category for a10
col created for a30
col sql_text for a150
col signature for 9999999999999999999999999

select sql.sql_id,sql.child_number as child , prof.name, prof.category, prof.created,prof.task_exec_name,prof.FORCE_MATCHING,prof.status,prof.SIGNATURE
from
dba_sql_profiles prof,
gv$sql sql
where sql.sql_id in ('&sql_id')
-- and sql.child_number=child_number
-- and sql.force_matching_signature=prof.SIGNATURE
order by
created;

PROMPT ================
PROMPT Sql Baselines
PROMPT ================

col SQL_HANDLE for a30
col origin for a16
col last_modified for a30
col last_verified for a30

select sql_handle, plan_name, origin, created, last_modified, last_verified,ENABLED,ACCEPTED,FIXED,REPRODUCED
from dba_sql_plan_baselines
where signature in (select force_matching_signature
from gv$sql
where sql_id='&sql_id'
and inst_id=&inst_id);

undef sid
undef sql_id
undef inst_id
spool off;
