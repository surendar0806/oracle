--to check the index 
select owner,index_name,INDEX_TYPE,table_owner,table_name,TABLESPACE_NAME,TEMPORARY from dba_indexes where index_name='&INAME';
