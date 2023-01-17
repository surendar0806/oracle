/* 
How to use TKPROF?
	TKPROF used to read the trace file in more readable format 
*/

--steps-1: 1.create the plan table
@?/rdbms/admin/utlxplan.sql

-- 2.give the required permission
CREATE PUBLIC SYNONYM PLAN_TABLE1 FOR SYS.PLAN_TABLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON SYS.PLAN_TABLE TO PUBLIC;

-- 3.enable the trace
ALTER SESSION SET SQL_TRACE = TRUE;

-- 4.run the query the problematic query 

-- 5.disable the trace. trace are generate in USER_DUMP_DEST
ALTER SESSION SET SQL_TRACE = FALSE;
show parameter USER_DUMP_DEST
SELECT value
FROM   v$diag_info
WHERE  name = 'Default Trace File';

-- get my trace  location 
SET LINESIZE 100
COLUMN trace_file FORMAT A60

SELECT s.sid,
       s.serial#,
       pa.value || '/' || LOWER(SYS_CONTEXT('userenv','instance_name')) ||    
       '_ora_' || p.spid || '.trc' AS trace_file
FROM   v$session s,
       v$process p,
       v$parameter pa
WHERE  pa.name = 'user_dump_dest'
AND    s.paddr = p.addr
AND    s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');

-- 6.run the tkprof command.
TKPROF new_ora_271632.trc test.txt explain=\"/ as sysdba \" table=sys.plan_table

--other session 
-- we can monitor the sesison using ssession id,client id , service name ,module name and action name 
-- at session level 

EXEC DBMS_MONITOR.session_trace_enable;
EXEC DBMS_MONITOR.session_trace_enable(waits=>TRUE, binds=>FALSE);
EXEC DBMS_MONITOR.session_trace_disable;

EXEC DBMS_MONITOR.session_trace_enable(session_id=>1234, serial_num=>1234);
EXEC DBMS_MONITOR.session_trace_enable(session_id =>1234, serial_num=>1234, waits=>TRUE, binds=>FALSE);
EXEC DBMS_MONITOR.session_trace_disable(session_id=>1234, serial_num=>1234);

EXEC DBMS_MONITOR.client_id_trace_enable(client_id=>'tim_hall');
EXEC DBMS_MONITOR.client_id_trace_enable(client_id=>'tim_hall', waits=>TRUE, binds=>FALSE);
EXEC DBMS_MONITOR.client_id_trace_disable(client_id=>'tim_hall');

EXEC DBMS_MONITOR.serv_mod_act_trace_enable(service_name=>'db10g', module_name=>'test_api', action_name=>'running');
EXEC DBMS_MONITOR.serv_mod_act_trace_enable(service_name=>'db10g', module_name=>'test_api', action_name=>'running', -
> waits=>TRUE, binds=>FALSE);
EXEC DBMS_MONITOR.serv_mod_act_trace_disable(service_name=>'db10g', module_name=>'test_api', action_name=>'running');

-- at system level 

-- SQL Trace (10046)
ALTER SYSTEM SET EVENTS 'sql_trace [sql:&&sql_id] bind=true, wait=true';

-- 10053
ALTER SESSION SET EVENTS 'trace[rdbms.SQL_Optimizer.*][sql:sql_id]';


