-----------------------------------------------
-- Archive log  Hourly basics : 
-----------------------------------------------
select trunc(COMPLETION_TIME,'HH') Hour,thread# , 
round(sum(BLOCKS*BLOCK_SIZE)/1024/1024) MB,
count(*) Archives from v$archived_log 
group by trunc(COMPLETION_TIME,'HH'),thread#  order by 1 

select count(to_char(COMPLETION_TIME,'MM-YYY')) Month from v$archived_log

-----------------------------------------------
-- Prompt Monthly-View
-----------------------------------------------
select (select 'zzz '||host_name from v$instance) as Host,to_char(COMPLETION_TIME,'MM-YYYY') Month,thread# , 
round(sum(BLOCKS*BLOCK_SIZE)/1024/1024/1024) GB,
count(*) Archives from v$archived_log 
group by to_char(COMPLETION_TIME,'MM-YYYY'),thread#  order by 1;
