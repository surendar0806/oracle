
-- ----------------------------------------------------------------------------------------------------
-- To find the Exec Plan:
-- ----------------------------------------------------------------------------------------------------
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR('<sql_id>'));
select * from TABLE(dbms_xplan.display_awr('<sql_id>'));
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor);
 SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('TYPICAL'));
select SQL_ID,SQL_TEXT from v$sql where SQL_TEXT like '<sql_text>%';

-- ----------------------------------------------------------------------------------------------------
-- DISPLAY Function:(DBMS_XPLAN.DISPLAY function to display the execution plan)
-- ----------------------------------------------------------------------------------------------------
CONN scott/tiger

EXPLAIN PLAN FOR
SELECT *
FROM   emp e, dept d
WHERE  e.deptno = d.deptno
AND    e.ename  = 'SMITH';

SET LINESIZE 130
SET PAGESIZE 0
SELECT * 
FROM   TABLE(DBMS_XPLAN.DISPLAY);

-- ----------------------------------------------------------------------------------------------------
-- The DBMS_XPLAN.DISPLAY function can accept 3 optional parameters:( 'BASIC', 'ALL', 'SERIAL'. There is also an undocumented 'ADVANCED')
-- ----------------------------------------------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID='TSH' FOR
SELECT *
FROM   emp e, dept d
WHERE  e.deptno = d.deptno
AND    e.ename  = 'SMITH';

SELECT * FROM   TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','TSH','TYPICAL'));

