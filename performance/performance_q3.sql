-- ---------------------------------------
-- To get plan from awr 
-- ---------------------------------------

-- Query 1 
set pagesize 999
set lines 999
col sql_text format a70 trunc
col child format 99999
col sql_id for a15
col plan_hash_value for 9999999999999
col executions_total format 9999999999999999
col avg_etime format 999,999,999,999.99
col avg_lio format 999,999,999,999.99
col NOCHILD_CURSORS for 999999999999999
col "OFFLOADED_%" format a11
col avg_px format 999999
col offload for a7
col BEGIN_INTERVAL_TIME format a30
col END_INTERVAL_TIME format a30
-- using dba_hist_sqlstat

select    a.INSTANCE_NUMBER, snap_id, BEGIN_INTERVAL_TIME, END_INTERVAL_TIME,
        PARSING_SCHEMA_NAME,
        sql_id, PLAN_HASH_VALUE,
                aa.name command_type_desc,
        SQL_PROFILE,
        executions_total,
        OPTIMIZER_COST,
        (ELAPSED_TIME_TOTAL/1e6)/decode(nvl(EXECUTIONS_TOTAL,0),0,1,EXECUTIONS_TOTAL)/
                        decode(PX_SERVERS_EXECS_TOTAL,0,1,PX_SERVERS_EXECS_TOTAL)/decode(nvl(EXECUTIONS_TOTAL,0),0,1,EXECUTIONS_TOTAL) avg_etime,
        decode(PX_SERVERS_EXECS_TOTAL,0,1,PX_SERVERS_EXECS_TOTAL)/decode(nvl(EXECUTIONS_TOTAL,0),0,1,EXECUTIONS_TOTAL) avg_px,
        BUFFER_GETS_TOTAL/decode(nvl(EXECUTIONS_TOTAL,0),0,1,EXECUTIONS_TOTAL) avg_lio,
        VERSION_COUNT nochild_cursors,
        decode(IO_OFFLOAD_ELIG_BYTES_TOTAL,0,'No','Yes') Offload,
        decode(IO_OFFLOAD_ELIG_BYTES_TOTAL,0,0,100*(IO_OFFLOAD_ELIG_BYTES_TOTAL-IO_INTERCONNECT_BYTES_TOTAL))
        /decode(IO_OFFLOAD_ELIG_BYTES_TOTAL,0,1,IO_OFFLOAD_ELIG_BYTES_TOTAL) "IO_SAVED_%",
                c.sql_text
from DBA_HIST_SQLSTAT a  left outer join
     DBA_HIST_SNAPSHOT b using (SNAP_ID) left outer join
     DBA_HIST_SQLTEXT c using (SQL_ID) left outer join
     audit_actions aa on (COMMAND_TYPE = aa.ACTION)
where
    upper(dbms_lob.substr(sql_text, 4000, 1)) like upper(nvl('&sql_text',upper(dbms_lob.substr(sql_text, 4000, 1))))  --use dbms_lob.substr in order not to get an "ORA-22835: Buffer too small for CLOB to CHAR or BLOB to RAW conversion"
    and sql_id = nvl(trim('&sql_id'),sql_id)
        and b.begin_interval_time > sysdate - &days_back
order by 2 desc,3 desc;

undef days_back

-- query 2  , Simple 
select a.instance_number inst_id, a.snap_id,a.plan_hash_value, to_char(begin_interval_time,'dd-mon-yy hh24:mi') btime, abs(extract(minute from (end_interval_time-begin_interval_time)) + extract(hour from (end_interval_time-begin_interval_time))*60 + extract(day from (end_interval_time-begin_interval_time))*24*60) minutes,
executions_delta executions, round(ELAPSED_TIME_delta/1000000/greatest(executions_delta,1),4) "avg duration (sec)" from dba_hist_SQLSTAT a, dba_hist_snapshot b
where sql_id='&sql_id' and a.snap_id=b.snap_id
and a.instance_number=b.instance_number
order by snap_id desc, a.instance_number;

