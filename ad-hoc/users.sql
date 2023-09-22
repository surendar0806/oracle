-- # CONTENTS  
-- 1. Proxy users
-- 2. 
-- 3. 

-------------------------------------
-- 1. Proxy users 
--    It is alterntive way of logging into DB without knowing the password 

-- Allow the MY_USER_1 user to make a proxy connection to the SCHEMA_OWNER user.
alter user schema_owner grant connect through my_user_1;

-- We can now connect to the SCHEMA_OWNER user, using the credentials of the proxy user.
conn my_user_1[schema_owner]/MyPassword1@//localhost:1521/dbname
show user

-- The proxy authentication can be revoked using the following command.
alter user schema_owner revoke connect through my_user_1;

-- list all proxy roles 
select * from proxy_users;

--  V$SESSION_CONNECT_INFO view gives us access to the AUTHENITCATION_TYPE column
select s.sid, s.serial#, s.username, s.osuser, sci.authentication_type
from   v$session s,
       v$session_connect_info sci
where  s.sid = sci.sid
and    s.serial# = sci.serial#
and    sci.authentication_type = 'PROXY';

-------------------------------------






-------------------------------------
-- Reference :
-- Proxy users : https://oracle-base.com/articles/misc/proxy-users-and-connect-through
