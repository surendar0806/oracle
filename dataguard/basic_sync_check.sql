
---------------------------------------
-- Check sync in standby 
-------------------------------------
SELECT ARCH.THREAD# “Thread”,
 ARCH.SEQUENCE# “Last Sequence Received”, 
 APPL.SEQUENCE# “Last Sequence Applied”, (ARCH.SEQUENCE# – APPL.SEQUENCE#) “Difference”
FROM(SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
    (SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;

-------------------------------------------
-- Query to monitor the data guard status:
-------------------------------------------
-- Run in Primary 
select name, database_role from v$database;
select thread#,max(sequence#) from v$archived_log group by thread#;
SELECT MAX(SEQUENCE#),THREAD#,APPLIED,STANDBY_DEST FROM GV$ARCHIVED_LOG GROUP BY THREAD#,APPLIED,STANDBY_DEST ;

-- Run in DR Database:
select thread#,max(sequence#) from v$log_history group by thread#;
select name,database_role from v$database;

-------------------------------------------
-- Command to see MRP & RFS services are running or not
-------------------------------------------
select process,status,client_process,thread#,sequence#,BLOCK# from v$managed_standby;

-------------------------------------------
-- Dataguard Error Message 
-------------------------------------------
select message from v$dataguard_status;

-------------------------------------------
-- Restart the MRP in database 
-------------------------------------------
-- To stop MRP 
ALTER database RECOVER MANAGED STANDBY DATABASE CANCEL;
-- To start the  MRP 
alter database mount standby database;
alter database recover managed standby database disconnect;
