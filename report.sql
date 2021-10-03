/*   
To generate  Oracle Exawatcher
-----------------------------------------
cd /opt/oracle.ExaWatcher
./GetExaWatcherResults.sh --from 09/12/2021_15:00:00 --to 09/12/2021_18:00:00 --resultdir /tmp/exawatcher_12092021

*/


--AWR report scripts
@$ORACLE_HOME/rdbms/admin/awrrpt.sql
@$ORACLE_HOME/rdbms/admin/awrrpti.sql

--ASH Report scripts
$ORACLE_HOME/rdbms/admin/ashrpt.sql
