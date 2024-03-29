/* Basic errors
Your table is already locked by some query. 
ERROR at line 1: ORA-00054: resource busy and acquire with NOWAIT specified or timeout expired
*/

-- ----------------------------------------------------------------------------------------
-- To get the details of the locked objects
-- --------------------------------------------------------------------------------------
SELECT O.OBJECT_NAME, S.SID, S.SERIAL#, P.SPID, S.PROGRAM,S.USERNAME,
S.MACHINE,S.PORT , S.LOGON_TIME,SQ.SQL_FULLTEXT 
FROM V$LOCKED_OBJECT L, DBA_OBJECTS O, V$SESSION S, 
V$PROCESS P, V$SQL SQ 
WHERE L.OBJECT_ID = O.OBJECT_ID 
AND L.SESSION_ID = S.SID AND S.PADDR = P.ADDR 
AND S.SQL_ADDRESS = SQ.ADDRESS;

ALTER SYSTEM KILL SESSION '25,54324' IMMEDIATE;

