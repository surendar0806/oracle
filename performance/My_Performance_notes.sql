/*
We need to check the below column in the gv$sql. Need to analyze how often the transcation is successful
there may be some case where where query is being callled multiple times
fetches,executions,optimizer cost , sorts 
*/

select sql_id,plan_hash_value,fetches,executions,sorts,optimizer_cost from gv$sql where sql_id='&SQL_ID';

select inst_id,username,status,count(*) from gv$session where username is not null; 

/* #General 
Not every query running slow is issues of database 
Need to check if the query runs single or as part of loop
Understand the bussiness requirement and then start tuning. 
Ask from when we start facing issues
*/

/*  data volume affecting the #query_plan
consider a scenario from company table where the dept='it' fetches only 10% of data 
whereas  dept='delivery' fetches rows more than 30%. 
here the plan changes pased on the id passed. so it is important to understand the query purpose 
*/
