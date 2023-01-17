-----------------------------------------------
-- To find currently waiting:
-----------------------------------------------
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
ORDER BY sw.seconds_in_wait DESC;

-----------------------------------------------
-- Overall waits:
-----------------------------------------------
COLUMN username FORMAT A20
COLUMN sid FORMAT 9999
COLUMN serial# FORMAT 9999
COLUMN event FORMAT A40
SELECT NVL(s.username, '(oracle)') AS username, s.sid,s.serial#,se.event,se.total_waits,se.total_timeouts,se.time_waited,
se.average_wait,se.max_wait,se.time_waited_micro FROM v$session_event se,v$session s WHERE s.sid = se.sid AND s.sid = &Session_ID ORDER BY se.time_waited DESC
/

-----------------------------------------------
-- Time Model:
-----------------------------------------------
select stat_name, value from V$SESS_TIME_MODEL where sid = &sid order by value desc;

-----------------------------------------------
-- Stats:
-----------------------------------------------
select vsn.name, vst.value from v$sesstat vst, v$statname vsn where vsn.statistic# = vst.statistic# and vst.value != 0 and vst.sid = &sid order by vst.value;
RealTime Monitoring for sid:

-----------------------------------------------
-- Elapsed/CPU/Read/Write MB:
-----------------------------------------------
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
ROUND(physical_read_bytes /(10241024)) AS "Phys reads (MB)",
ROUND(physical_write_bytes/(10241024)) AS "Phys writes (MB)"
FROM gv$sql_monitor where sid=&sid and inst_id=&inst_id
ORDER BY elapsed_time DESC
)
WHERE rownum<=20;

-----------------------------------------------
-- To find Each layer Time spend:
-----------------------------------------------
SELECT ROUND(elapsed_time /1000000) AS "Elapsed (s)",
ROUND(cpu_time /1000000,3) AS "CPU (s)",
ROUND(queuing_time /1000000,3) AS "Queuing (s)",
ROUND(user_io_wait_time /1000000,3) AS "I/O wait (s)",
ROUND(application_wait_time/1000000,3) AS "Appli wait (s)",
ROUND(concurrency_wait_time/1000000,3) AS "Concurrency wait (s)",
ROUND(cluster_wait_time /1000000,3) AS "Cluster wait (s)",
ROUND(physical_read_bytes /(10241024)) AS "Phys reads (MB)",
ROUND(physical_write_bytes /(10241024)) AS "Phys writes (MB)",
buffer_gets AS "Buffer gets",
ROUND(plsql_exec_time/1000000,3) AS "Plsql exec (s)",
ROUND(java_exec_time /1000000,3) AS "Java exec (s)"
FROM gv$sql_monitor
WHERE sid=&sid and inst_id=&inst_id;

-----------------------------------------------
-- To Find Explain plan waiting steps:
-----------------------------------------------
col PLAN for a150
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
ORDER BY p.plan_line_id, p.plan_parent_id;

-----------------------------------------------
-- To find list the top 20 SQL having the longest elapsed time:
-----------------------------------------------
SELECT * FROM (SELECT status, --username, sql_id, sql_exec_id, TO_CHAR(sql_exec_start,'dd-mon-yyyy hh24:mi:ss') AS sql_exec_start, ROUND(elapsed_time/1000000) AS "Elapsed (s)", ROUND(cpu_time /1000000) AS "CPU (s)", buffer_gets, ROUND(physical_read_bytes /(1024*1024)) AS "Phys reads (MB)", ROUND(physical_write_bytes/(1024*1024)) AS "Phys writes (MB)" FROM v$sql_monitor ORDER BY elapsed_time DESC ) WHERE rownum<=20;

-- Currently running SQL query’s:

-----------------------------------------------
-- v$sqlarea/v$sql:
-----------------------------------------------
set lines 1500 pages 9999
column sid format 9999
column username format a15
column PARSING_SCHEMA_NAME format a15
column SQL_EXEC_START for a21
column sql_text format a50
column module format a35
select a.inst_id,a.sid,a.username,b.PARSING_SCHEMA_NAME,a.module,a.sql_id,a.sql_child_number child,b.plan_hash_value,to_char (a.sql_exec_start, 'dd-Mon-yyyy hh24:mi:ss') sql_exec_start,(sysdate-sql_exec_start)2460*60 SECS,b.rows_processed,a.status,substr(b.sql_text,1,50) sql_text
from gv$session a,gv$sqlarea b
where a.sql_hash_value = b.hash_value
and a.sql_address = b.address
and a.module not like '%emagent%'
and a.module not like '%oraagent.bin%'
and sql_text not like '%b.PARSING_SCHEMA_NAME%'
and a.username is not null
order by a.status;

-----------------------------------------------
-- ASH:
-----------------------------------------------
column my_sid format 999
column my_ser format 99999
column my_state format a30
column my_blkr format 999
select to_char(a.sample_time, 'HH24:MI:SS') MY_TIME,a.session_id MY_SID,a.session_serial# MY_SER,
DECODE(a.session_state, 'WAITING' ,a.event, a.session_state) MY_STATE,a.xid, a.sql_id,
a.blocking_session MY_BLKR
from gv$active_session_history a, dba_users u
where u.user_id = a.user_id
and a.sql_id = '&sql_id'
and a.sample_time > SYSTIMESTAMP-(2/1440);

-----------------------------------------------
-- AWR:
-----------------------------------------------
set lines 1000 pages 9999
SELECT s.snap_id,TO_CHAR(s.begin_interval_time, 'DD-MON HH24:MI') snap_time,ss.sql_id,ss.plan_hash_value,
ss.ROWS_PROCESSED_TOTAL,
ss.executions_delta execs,
(ss.elapsed_time_delta/1000000)/DECODE(ss.executions_delta,0,1,ss.executions_delta) ela_per_exec,
(ss.cpu_time_delta /1000000)/DECODE(ss.executions_delta,0,1,ss.executions_delta) cpu_per_exec,
ss.buffer_gets_delta /DECODE(ss.executions_delta,0,1,ss.executions_delta) lio_per_exec,
ss.disk_reads_delta /DECODE(ss.executions_delta,0,1,ss.executions_delta) pio_per_exec
FROM dba_hist_snapshot s,
dba_hist_sqlstat ss
WHERE ss.dbid = s.dbid
AND ss.instance_number = s.instance_number
AND ss.snap_id = s.snap_id
AND ss.sql_id = nvl('&sql_id','4dqs2k5tynk61')
/* and ss.executions_delta > 0 /
/ check executions_delta for 1 , if it is 0 just consider only rows proceesed and calculate total execution time = sum ( executions_delta 1 + executions_delta 0 ) */
ORDER BY s.snap_id;

-----------------------------------------------
-- TIME BASED REPORT:
-----------------------------------------------
select s.sql_id, sum(case when begin_interval_time = to_date('14-nov-2017 1100','dd-mon-yyyy hh24mi') then s.executions_total else 0 end) sum_after, (sum(case when begin_interval_time >= to_date('14-nov-2020 1100','dd-mon-yyyy hh24mi') then s.executions_total
else 0 end) - sum(case when begin_interval_time < to_date('14-nov-2020 1100','dd-mon-yyyy hh24mi') then s.executions_total else 0 end)) difference from dba_hist_sqlstat s,
dba_hist_snapshot sn where sn.begin_interval_time between to_date('05-nov-2020 0001','dd-mon-yyyy hh24mi') and to_date('05-nov-2020 2359','dd-mon-yyyy hh24mi') and sn.snap_id=s.snap_id group by s.sql_id order by difference desc;

select * from ( select sql_id,sql_plan_hash_value,event,sql_exec_id,sql_exec_start,current_obj#,sql_plan_line_id,sql_plan_operation,sql_plan_options,SUM (delta_read_io_requests) lio_read ,SUM (delta_read_io_bytes) pio_read ,count(*) count_1
from dba_hist_active_sess_history where sql_id='&sql_id' group by
sql_id, sql_plan_hash_value, event,sql_exec_id, sql_exec_start,
current_obj#, sql_plan_line_id, sql_plan_operation, sql_plan_options )
order by count_1 desc;

-----------------------------------------------
-- RealTime Monitoring for sql_id:
-----------------------------------------------
-- Sql monitor report:

set pagesize 0 echo off timing off linesize 1000 trimspool on trim on long 2000000 longchunksize 2000000
select
DBMS_SQLTUNE.REPORT_SQL_MONITOR(
sql_id=>'&sql_id',
report_level=>'ALL',
type=>'TEXT')
from dual;

-----------------------------------------------
-- Elapsed/CPU/Read/Write MB:
-----------------------------------------------
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
ROUND(physical_read_bytes /(10241024)) AS "Phys reads (MB)",
ROUND(physical_write_bytes/(10241024)) AS "Phys writes (MB)"
FROM gv$sql_monitor where sql_id='&sql_id' and inst_id=&inst_id
ORDER BY elapsed_time DESC
)
WHERE rownum<=20;
