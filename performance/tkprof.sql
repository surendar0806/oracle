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

-- 6.run the tkprof command.
TKPROF new_ora_271632.trc test.txt explain=\"/ as sysdba \" table=sys.plan_table
