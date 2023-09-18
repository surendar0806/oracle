-- ----------------------------------------------------------------------------
-- To Temp usage details:
-- check size of temp tablespace 
-- ----------------------------------------------------------------------------

select TABLESPACE_NAME, sum(BYTES_USED/1024/1024/1024) as "BYTES_USED in GB" , sum(BYTES_FREE/1024/1024/1024) as "BYTES_FREE in GB" 
from V$TEMP_SPACE_HEADER group by TABLESPACE_NAME;

select (s.tot_used_blocks/f.total_blocks)*100 as "percent used"
from (select sum(used_blocks) tot_used_blocks from 
v$sort_segment where tablespace_name='TTS1') s, 
(select sum(blocks) total_blocks from 
dba_temp_files where tablespace_name='TTS1') f;

-- ----------------------------------------------------------------------------
-- To Check the Session in Temp usages : 
-- ----------------------------------------------------------------------------
SET PAUSE ON
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 50
SET LINESIZE 300 
COLUMN tablespace FORMAT A20
COLUMN temp_size FORMAT A20
COLUMN sid_serial FORMAT A20
COLUMN username FORMAT A20
COLUMN program FORMAT A50

SELECT b.tablespace,
       ROUND(((b.blocks*p.value)/1024/1024),2)||'M' AS temp_size,
       a.inst_id as Instance,
       a.sid||','||a.serial# AS sid_serial,
       NVL(a.username, '(oracle)') AS username,
       a.program,
       a.status,
       a.sql_id
FROM   gv$session a,
       gv$sort_usage b,
       gv$parameter p
WHERE  p.name  = 'db_block_size'
AND    a.saddr = b.session_addr
AND    a.inst_id=b.inst_id
AND    a.inst_id=p.inst_id
ORDER BY b.tablespace, b.blocks
/ 


SELECT s.sid, s.username, s.status, u.tablespace, u.segfile#, u.contents, u.extents, u.blocks 
FROM v$session s, v$sort_usage u 
WHERE s.saddr=u.session_addr 
ORDER BY u.tablespace, u.segfile#, u.segblk#, u.blocks;
 
set lines 200
col username format a20

select    username,   session_addr,    session_num,    sql_id,    contents,   segtype,    extents,    blocks
from  v$tempseg_usage order by username;


-- ----------------------------------------------------------------------------
-- To Check the size of undo tablespace:
--  NEW_UNDOTBS_FILE_SIZE_MB = CURR_UNDOTBS_FILE_SIZE_MB + CURR_UNDOTBS_FILE_SIZE_MB*0.2
-- ----------------------------------------------------------------------------

SELECT file_name, tablespace_name, bytes/1024/1024 UNDO_SIZE_MB, SUM
(bytes/1024/1024) OVER() TOTAL_UNDO_SIZE_MB
      FROM dba_data_files d
      WHERE EXISTS (SELECT 1 FROM v$parameter p WHERE LOWER
(p.name)='undo_tablespace' AND p.value=d.tablespace_name);
