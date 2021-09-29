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
