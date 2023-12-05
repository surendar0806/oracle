--------------------------------------------------------------------------
--Oracle sets locks in order to manage concurrent updates and ensure that the database maintains its internal integrity.
--------------------------------------------------------------------------
select session_id SID,SERIAL#  SERIAL_NUM, substr(object_name,1,30) TABLE_NAME,substr(os_user_name,1,10) TERMINAL,
substr(oracle_username,1,10) LOCKER,nvl(lockwait,'ACTIVE') WAIT,
decode(locked_mode,2,'ROW SHARE',3,'ROW EXCLUSIVE',4,'SHARE',5,'SHARE ROW EXCLUSIVE',6,'EXCLUSIVE','UNKNOWN') LOCK_MODE,
OBJECT_TYPE Type,to_char(c.logon_time,'MM/DD/YYYY HH24:MI:SS') as "SESSION_START_TIME",
c.SECONDS_IN_WAIT  SECONDS_IN_WAIT
FROM   SYS.V_$LOCKED_OBJECT A,SYS.ALL_OBJECTS B,SYS.V_$SESSION c
WHERE   A.OBJECT_ID = B.OBJECT_ID
AND   C.SID = A.SESSION_ID
AND A.ORACLE_USERNAME='SWMS_JDBC'
AND B.OBJECT_NAME like 'SAP%'
AND c.SECONDS_IN_WAIT > 600
AND lockwait is NULL
ORDER BY 3 ASC;

--------------------------------------------------------------------------
--Detect locked objects:
--------------------------------------------------------------------------
select    (select username from v$session where sid=a.sid) blocker, a.sid,
   ' is blocking ',   (select username from v$session where sid=b.sid) blockee,   b.sid
from v$lock a, v$lock b
where a.block = 1 and    b.request > 0 and    a.id1 = b.id1 and    a.id2 = b.id2;

--------------------------------------------------------------------------
--Quickly identify all lock objects within your Oracle system.
--------------------------------------------------------------------------
Select    c.owner,   c.object_name,   c.object_type,   b.sid,   b.serial#,   b.status,   b.osuser,   b.machine 
From   v$locked_object a , v$session b,dba_objects c
Where    b.sid = a.session_id and   a.object_id = c.object_id;   

--------------------------------------------------------------------------
--Show all sessions waiting for any lock:
--------------------------------------------------------------------------
select event,p1,p2,p3 from v$session_wait where wait_time=0 and event='enqueue';

--------------------------------------------------------------------------
-- show sessions waiting for a TX lock:
--------------------------------------------------------------------------
select * from v$lock where type='TX' and request>0;


--------------------------------------------------------------------------
-- Detect locked objects:
--------------------------------------------------------------------------
select    (select username from v$session where sid=a.sid) blocker, a.sid,
   ' is blocking ',   (select username from v$session where sid=b.sid) blockee,   b.sid
from gv$lock a, gv$lock b
where a.block = 1 and    b.request > 0 and    a.id1 = b.id1 and    a.id2 = b.id2;

--------------------------------------------------------------------------   
-- Quickly identify all lock objects within your Oracle system.
--------------------------------------------------------------------------
Select    c.owner,   c.object_name,   c.object_type,   b.sid,   b.serial#,   b.status,   b.osuser,   b.machine 
From   gv$locked_object a , gv$session b,dba_objects c
Where    b.sid = a.session_id and   a.object_id = c.object_id;   

--------------------------------------------------------------------------
--list of blocking sessions and the sessions that they are blocking:
--------------------------------------------------------------------------
select blocking_session, sid, serial#, wait_class, seconds_in_wait
from gv$session
where  blocking_session is not NULL
order by  blocking_session;

--------------------------------------------------------------------------
-- list of blocking sessions and the sessions that they are blocking:
--------------------------------------------------------------------------
select blocking_session, sid, serial#, wait_class, seconds_in_wait
from gv$session
where  blocking_session is not NULL
order by  blocking_session;

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
-- Hash Plan history for sql_id
-----------------------------------------------
select a.instance_number inst_id, a.snap_id,a.plan_hash_value, to_char(begin_interval_time,'dd-mon-yy hh24:mi') btime, abs(extract(minute from (end_interval_time-begin_interval_time)) + extract(hour from (end_interval_time-begin_interval_time))*60 + extract(day from (end_interval_time-begin_interval_time))*24*60) minutes,
executions_delta executions, round(ELAPSED_TIME_delta/1000000/greatest(executions_delta,1),4) "avg duration (sec)" from dba_hist_SQLSTAT a, dba_hist_snapshot b
where sql_id='&sql_id' and a.snap_id=b.snap_id
and a.instance_number=b.instance_number
order by snap_id desc, a.instance_number;

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


--------------------------------------------------------------------------------------------------------------------
-- File name:   prashantpoormanscript.sql
-- Version:     V1.1 (12-08-2021) Simple View
-- Purpose:     This script can be used on any Oracle DB to know what all running and for how long and waiting
--              Also provides details on SQL and SESSION level. 
-- Author:      Prashant Dixit The Fatdba www.fatdba.com
-- Long Running Queries
--------------------------------------------------------------------------------------------------------------------
set linesize 400 pagesize 400
select
x.inst_id
,x.sid
,x.serial#
,x.username
,x.sql_id
,plan_hash_value
,sqlarea.DISK_READS
,sqlarea.BUFFER_GETS
,sqlarea.ROWS_PROCESSED
,x.event
,x.osuser
,x.status
,x.BLOCKING_SESSION_STATUS
,x.BLOCKING_INSTANCE
,x.BLOCKING_SESSION
,x.process
,x.machine
,x.program
,x.module
,x.action
,TO_CHAR(x.LOGON_TIME, 'MM-DD-YYYY HH24:MI:SS') logontime
,x.LAST_CALL_ET
,x.SECONDS_IN_WAIT
,x.state
,sql_text,
ltrim(to_char(floor(x.LAST_CALL_ET/3600), '09')) || ':'
 || ltrim(to_char(floor(mod(x.LAST_CALL_ET, 3600)/60), '09')) || ':'
 || ltrim(to_char(mod(x.LAST_CALL_ET, 60), '09'))    RUNNING_SINCE
from   gv$sqlarea sqlarea
,gv$session x
where  x.sql_hash_value = sqlarea.hash_value
and    x.sql_address    = sqlarea.address
and    sql_text not like '%select x.inst_id,x.sid ,x.serial# ,x.username ,x.sql_id ,plan_hash_value ,sqlarea.DISK_READS%'
and    x.status='ACTIVE'
and x.USERNAME is not null
and x.SQL_ADDRESS    = sqlarea.ADDRESS
and x.SQL_HASH_VALUE = sqlarea.HASH_VALUE
order by RUNNING_SINCE desc;