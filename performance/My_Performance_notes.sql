/*
We need to check the below column in the gv$sql. Need to analyze how often the transcation is successful
there may be some case where where query is being callled multiple times
fetches,executions,optimizer cost , sorts 
*/

select sql_id,plan_hash_value,fetches,executions,sorts,optimizer_cost from gv$sql where sql_id='&SQL_ID';

select inst_id,username,status,count(*) from gv$session where username is not null; 
