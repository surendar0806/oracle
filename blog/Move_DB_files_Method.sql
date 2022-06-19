-- 1. Create the PFILEfrom the SPFILE.
Create pfile='E:\pfile.txt' from spfile;

-- 2. Edit the PFILE for the location of control files or other parameters if you want to move. 

/* Save it.Edit control file parameter and provide new location:
*.control_files='C:\ORACLE\ORADATA\XE\CONTROL01.CTL','C:\ORACLE\ORADATA\XE\CONTROL02.CTL'
*/


-- 3. Before shutdown the database. Prepared scripts for rename the datafile,undo, redolog and temp files.:
-- For Windows platform:
--For Redo log files:
Set line 2000 pages 200
select 'ALTER DATABASE RENAME FILE '''||member||''' TO ''new_location'||substr(member,INSTR(member,'\',-1,1),length(member)) ||''';' from v$logfile;
--Output:
ALTER DATABASE RENAME FILE 'C:\ORACLE\ORADATA\XE\REDO01.LOG' TO 'new_location\REDO01.LOG';
--For Datafiles and undo files:
SQL> select 'ALTER DATABASE RENAME FILE '''||file_name||''' TO ''new_location'||substr(file_name,INSTR(file_name,'\',-1,1),length(file_name)) ||''';' from dba_data_files;
--Output like following:
ALTER DATABASE RENAME FILE 'C:\ORACLE\ORADATA\XE\SYSTEM01.DBF' TO 'new_location\SYSTEM01.DBF';
--For Temp files:
SQL> select 'ALTER DATABASE RENAME FILE '''||file_name||''' TO ''new_location'||substr(file_name,INSTR(file_name,'\',-1,1),length(file_name)) ||''';' from dba_TEMP_files;
-- Output for temp:
ALTER DATABASE RENAME FILE 'C:\ORACLE\ORADATA\XE\TEMP01.DBF' TO 'new_location\TEMP01.DBF';

--For Linux use these commands:
--For Redo log files:
SQL> Set line 2000 pages 200
SQL> select 'ALTER DATABASE RENAME FILE '''||member||''' TO ''new_location'||substr(member,INSTR(member,'/',-1,1),length(member)) ||''';' from v$logfile;
--For Datafiles and undo files:
SQL> select 'ALTER DATABASE RENAME FILE '''||file_name||''' TO ''new_location'||substr(file_name,INSTR(file_name,'/',-1,1),length(file_name)) ||''';' from dba_data_files;
--For Temp files:
SQL> select 'ALTER DATABASE RENAME FILE '''||file_name||''' TO ''new_location'||substr(file_name,INSTR(file_name,'/',-1,1),length(file_name)) ||''';' from dba_TEMP_files;

--4. After shut down the database and moving all the oradata folders or datafiles to a new location.
Shutdown immediate
-- copy all datafiles to new location

-- 5. Create SPFILE from the edited PFILE.
create spfile from pfile='E:\pfile.txt';

-- 6. Start the database in the mounted state.
Startup mount;

--7. Then Run the upper alter command generated for renaming the datafiles, undo, temp, or redo log file.
-- For Redo
ALTER DATABASE RENAME FILE 'C:\ORACLE\ORADATA\XE\REDO01.LOG' TO 'new_location\REDO01.LOG';
--For datafiles or undo
ALTER DATABASE RENAME FILE 'C:\ORACLE\ORADATA\XE\SYSTEM01.DBF' TO 'new_location\SYSTEM01.DBF';
--For temp files:
ALTER DATABASE RENAME FILE 'C:\ORACLE\ORADATA\XE\TEMP01.DBF' TO 'new_location\TEMP01.DBF';

--8. Open the database after executing all the altered commands:

ALTER DATABASE OPEN;
