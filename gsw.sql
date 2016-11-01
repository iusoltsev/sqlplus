set linesize 500 pagesize 5000
with gvs as (select /*+ materialize*/ * from gv$session)
select/*+ ordered */ distinct--because of multiple records in v$sql for PREV_SQL
to_char(gvs.LOGON_TIME,'YYYY.MM.DD HH24:MI:SS') as LOGON_TIME
, gv$transaction.START_TIME as TX_STIME
, gvs.LAST_CALL_ET as LAST_CALL_ET
, gvs.STATUS
, gvs.USERNAME 
, gvs.PROGRAM
, gvs.SERVICE_NAME as service
, gvs.INST_ID
, gvs.SID
, gvs.SERIAL#
, decode(gv$session_wait.state, 'WAITING', gv$session_wait.EVENT, 'On CPU / runqueue') as EVENT
, gv$session_wait.state
, v$latchname.NAME as LATCHNAME
, gv$latchholder.sid
--, gvs.LOCKWAIT
, gv$session_wait.SECONDS_IN_WAIT
, dba_objects.owner||'.'||dba_objects.object_name req_object
, decode(sign(nvl(gvs.ROW_WAIT_OBJ#,-1)),-1,'NONE',DBMS_ROWID.ROWID_CREATE( 1, gvs.ROW_WAIT_OBJ#, gvs.ROW_WAIT_FILE#, gvs.ROW_WAIT_BLOCK#, gvs.ROW_WAIT_ROW# )) req_rowid
, lockhold.inst_id as BLOCKING_INSTANCE
, lockhold.sid as BLOCKING_SESSION
--from 10g and above--, case when substr(gv$instance.VERSION, 1, instr(gv$instance.VERSION,'.')-1) >= '10' then to_char(gvs.BLOCKING_INSTANCE) else 'Version <= 10' end as BLOCKING_INSTANCE
--from 10g and above--, case when substr(gv$instance.VERSION, 1, instr(gv$instance.VERSION,'.')-1) >= '10' then to_char(gvs.BLOCKING_SESSION) else 'Version <= 10' end as BLOCKING_SESSION
, gvs.COMMAND
, decode(gvs.COMMAND,
                            '1' ,'CREATE TABLE' ,'2' ,'INSERT', '3' ,'SELECT' ,'4' ,'CREATE CLUSTER' ,'5' ,'ALTER CLUSTER' ,'6' ,'UPDATE' ,'7' ,'DELETE' ,'8' ,'DROP CLUSTER' ,'9' ,'CREATE INDEX' ,'10' ,'DROP INDEX' ,'11' ,'ALTER INDEX' ,'12' ,'DROP TABLE' ,'13' ,'CREATE SEQUENCE 	14 	ALTER SEQUENCE' ,'15' ,'ALTER TABLE' ,'16' ,'DROP SEQUENCE' ,'17' ,'GRANT OBJECT' ,'18' ,'REVOKE OBJECT' ,'19' ,'CREATE SYNONYM 	20 	DROP SYNONYM' ,
                            '21' ,'CREATE VIEW' ,'22' ,'DROP VIEW' ,'23' ,'VALIDATE INDEX' ,'24' ,'CREATE PROCEDURE' ,'25' ,'ALTER PROCEDURE' ,'26' ,'LOCK' ,'27' ,'NO-OP' ,'28' ,'RENAME' ,'29' ,'COMMENT' ,'30' ,'AUDIT OBJECT' ,'31' ,'NOAUDIT OBJECT' ,'32' ,'CREATE DATABASE LINK' ,'33' ,'DROP DATABASE LINK' ,'34' ,'CREATE DATABASE' ,'35' ,'ALTER DATABASE' ,'36' ,'CREATE ROLLBACK SEG' ,'37' ,'ALTER ROLLBACK SEG' ,'38' ,'DROP ROLLBACK SEG' ,'39' ,'CREATE TABLESPACE' ,'40' ,'ALTER TABLESPACE' ,
                            '41' ,'DROP TABLESPACE' ,'42' ,'ALTER SESSION' ,'43' ,'ALTER USER' ,'44' ,'COMMIT' ,'45' ,'ROLLBACK' ,'46' ,'SAVEPOINT' ,'47' ,'PL/SQL EXECUTE' ,'48' ,'SET TRANSACTION' ,'49' ,'ALTER SYSTEM' ,'50' ,'EXPLAIN' ,'51' ,'CREATE USER' ,'52' ,'CREATE ROLE' ,'53' ,'DROP USER' ,'54' ,'DROP ROLE' ,'55' ,'SET ROLE' ,'56' ,'CREATE SCHEMA' ,'57' ,'CREATE CONTROL FILE' ,'59' ,'CREATE TRIGGER' ,'60' ,'ALTER TRIGGER' ,
                            '61' ,'DROP TRIGGER' ,'62' ,'ANALYZE TABLE' ,'63' ,'ANALYZE INDEX' ,'64' ,'ANALYZE CLUSTER' ,'65' ,'CREATE PROFILE' ,'66' ,'DROP PROFILE' ,'67' ,'ALTER PROFILE' ,'68' ,'DROP PROCEDURE' ,'70' ,'ALTER RESOURCE COST' ,'71' ,'CREATE MATERIALIZED VIEW LOG' ,'72' ,'ALTER MATERIALIZED VIEW LOG' ,'73' ,'DROP MATERIALIZED VIEW LOG' ,'74' ,'CREATE MATERIALIZED VIEW' ,'75' ,'ALTER MATERIALIZED VIEW' ,'76' ,'DROP MATERIALIZED VIEW' ,'77' ,'CREATE TYPE' ,'78' ,'DROP TYPE' ,'79' ,'ALTER ROLE' ,'80' ,'ALTER TYPE' ,
                            decode(gvs.COMMAND,
                            '81' ,'CREATE TYPE BODY' ,'82' ,'ALTER TYPE BODY' ,'83' ,'DROP TYPE BODY' ,'84' ,'DROP LIBRARY' ,'85' ,'TRUNCATE TABLE' ,'86' ,'TRUNCATE CLUSTER' ,'91' ,'CREATE FUNCTION' ,'92' ,'ALTER FUNCTION' ,'93' ,'DROP FUNCTION' ,'94' ,'CREATE PACKAGE' ,'95' ,'ALTER PACKAGE' ,'96' ,'DROP PACKAGE' ,'97' ,'CREATE PACKAGE BODY' ,'98' ,'ALTER PACKAGE BODY' ,'99' ,'DROP PACKAGE BODY' ,'100' ,'LOGON' ,
                            '101' ,'LOGOFF' ,'102' ,'LOGOFF BY CLEANUP' ,'103' ,'SESSION REC' ,'104' ,'SYSTEM AUDIT' ,'105' ,'SYSTEM NOAUDIT' ,'106' ,'AUDIT DEFAULT' ,'107' ,'NOAUDIT DEFAULT' ,'108' ,'SYSTEM GRANT' ,'109' ,'SYSTEM REVOKE' ,'110' ,'CREATE PUBLIC SYNONYM' ,'111' ,'DROP PUBLIC SYNONYM' ,'112' ,'CREATE PUBLIC DATABASE LINK' ,'113' ,'DROP PUBLIC DATABASE LINK' ,'114' ,'GRANT ROLE' ,'115' ,'REVOKE ROLE' ,'116' ,'EXECUTE PROCEDURE' ,'117' ,'USER COMMENT' ,'118' ,'ENABLE TRIGGER' ,'119' ,'DISABLE TRIGGER' ,'120' ,'ENABLE ALL TRIGGERS' ,
                            '121' ,'DISABLE ALL TRIGGERS' ,'122' ,'NETWORK ERROR' ,'123' ,'EXECUTE TYPE' ,'157' ,'CREATE DIRECTORY' ,'158' ,'DROP DIRECTORY' ,'159' ,'CREATE LIBRARY' ,'160' ,'CREATE JAVA' ,'161' ,'ALTER JAVA' ,'162' ,'DROP JAVA' ,'163' ,'CREATE OPERATOR' ,'164' ,'CREATE INDEXTYPE' ,'165' ,'DROP INDEXTYPE' ,'167' ,'DROP OPERATOR' ,'168' ,'ASSOCIATE STATISTICS' ,'169' ,'DISASSOCIATE STATISTICS' ,'170' ,'CALL METHOD' ,
                            '171' ,'CREATE SUMMARY' ,'172' ,'ALTER SUMMARY' ,'173' ,'DROP SUMMARY' ,'174' ,'CREATE DIMENSION' ,'175' ,'ALTER DIMENSION' ,'176' ,'DROP DIMENSION' ,'177' ,'CREATE CONTEXT' ,'178' ,'DROP CONTEXT' ,'179' ,'ALTER OUTLINE' ,'180' ,'CREATE OUTLINE' ,'181' ,'DROP OUTLINE' ,'182' ,'UPDATE INDEXES', '183', 'ALTER OPERATOR',
                            '')) as COMMAND
, gv$session_longops.TIME_REMAINING as LONGOPS_CALL_RT
, gv$session_longops.MESSAGE as LONGOPS_MESSAGE
--from 10g and above--, gvs.EVENT
--from 10g and above--, gvs.ROW_WAIT_OBJ#
--from 10g and above--, gvs.ROW_WAIT_FILE#
--from 10g and above--, gvs.ROW_WAIT_BLOCK#
--from 10g and above--, gvs.ROW_WAIT_ROW#
, gv$session_wait.P1
, gv$session_wait.P1TEXT
, gv$session_wait.P1RAW /* X$BH.HLADDR for LATCH: CACHE BUFFERS CHAINS */
--, decode(gvs_wait.EVENT, 'cursor: pin S wait on X', to_number(RTRIM(to_char( gvs_wait.P2, 'xxxxxxxxxxxx' ),'0'), 'xxxxxx' ), gvs_wait.P2) P2_HOLD_MUTEX_SID
, gv$session_wait.P2 P2
, gv$session_wait.P2TEXT
, gv$session_wait.P3
, gv$session_wait.P3TEXT
, ses_optimizer_env38.VALUE as ses_optimizer_mode
, ses_optimizer_env48.VALUE as ses_cursor_sharing
, gv$sql.SQL_ID as SQL_ID
, gv$sql.PLAN_HASH_VALUE as PLAN_HASH_VALUE
, gv$sql.OPTIMIZER_MODE as SQL_OPTIMIZER_MODE
, gv$sql.sql_text as SQL_TEXT
, gv$sql.SQL_PROFILE
, gvs.SQL_CHILD_NUMBER SQL_CHILD_NUMBER
, sql1.SQL_ID as PREV_SQL_ID
, sql1.PLAN_HASH_VALUE as PREV_PLAN_HASH_VALUE
, sql1.OPTIMIZER_MODE as PREV_SQL_OPTIMIZER_MODE
, sql1.sql_text as PREV_sql_text
, gvs.PREV_CHILD_NUMBER
, gvs.PLSQL_OBJECT_ID
, gvs.PLSQL_SUBPROGRAM_ID
, gvs.PLSQL_ENTRY_OBJECT_ID
, gvs.PLSQL_ENTRY_SUBPROGRAM_ID
--Network connection properties
, gvs.SERVER
, gvs.FAILOVER_TYPE
, gvs.FAILOVER_METHOD
, gvs.FAILED_OVER
, gvs.FIXED_TABLE_SEQUENCE
--OS properties
, gvs.MACHINE
, gvs.MODULE
, gvs.OSUSER
, gvs.OWNERID
, gvs.TERMINAL
, 'Alter system kill session '''||gvs.SID||','||gvs.SERIAL#||''';' as KILL_SESSION
--, gvs.PROCESS
, gv$instance.HOST_NAME
, 'kill '||gv$process.SPID as KILL_SPID
-- from 10g and above - SQL Trace info
, gvs.SQL_TRACE, gvs.SQL_TRACE_WAITS, gvs.SQL_TRACE_BINDS
, 'begin sys.dbms_support.start_trace_in_session('||gvs.SID||','||
  gvs.SERIAL#||', waits=>TRUE, binds=>TRUE );end;'
, 'begin sys.dbms_support.stop_trace_in_session('||gvs.SID||','||
  gvs.SERIAL#||' );end;'
, gvs.RESOURCE_CONSUMER_GROUP
from gvs
, gv$session_wait
, gv$session_longops
, gv$transaction
, gv$lock lockwait
, gv$lock lockhold
, gv$latchholder
, v$latchname
, gv$process
, gv$sql
, gv$sql sql1
, gv$instance
, dba_objects
, gv$ses_optimizer_env ses_optimizer_env38
, gv$ses_optimizer_env ses_optimizer_env48
where gvs.INST_ID = gv$instance.INST_ID
and gvs.PADDR=gv$process.ADDR(+) and gvs.INST_ID = gv$process.INST_ID(+)
and gvs.sql_address=gv$sql.address(+) and gvs.sql_hash_value=gv$sql.hash_value(+)
and gvs.SQL_CHILD_NUMBER = gv$sql.CHILD_NUMBER(+) and gvs.INST_ID = gv$sql.INST_ID(+)
and gvs.PREV_SQL_ADDR = sql1.address(+) and gvs.PREV_HASH_VALUE = sql1.hash_value(+)
and gvs.PREV_CHILD_NUMBER = sql1.CHILD_NUMBER(+)
and gvs.SID=gv$session_wait.SID(+) and gvs.INST_ID = gv$session_wait.INST_ID(+)
and gvs.SADDR=gv$transaction.SES_ADDR(+) and gvs.INST_ID = gv$transaction.INST_ID(+)
and gvs.SERVICE_NAME not in ('SYS$BACKGROUND')
        --or gvs.PROGRAM like '%LGWR%'   --These processes may be interesting
        --or gvs.PROGRAM like '%DBW%' )
and gvs.PROGRAM not like '%QMNC%'     --[Advanced] Queue Monitor Coordinator excluded
and gvs.PROGRAM not like '%q00%'          --[Advanced] queue monitor processes excluded
--and v$session.PROGRAM not like '%J00%'          --DBMS_JOB processes excluded
and gv$session_wait.P2=v$latchname.LATCH#(+)
and gv$session_wait.p1raw = gv$latchholder.laddr(+)
and gvs.ROW_WAIT_OBJ# = dba_objects.object_id(+)
and gvs.SID = gv$session_longops.sid(+)
and gvs.INST_ID = gv$session_longops.INST_ID(+)
and gvs.SERIAL# = gv$session_longops.SERIAL#(+)
and gvs.sql_address = gv$session_longops.SQL_ADDRESS(+)
and gvs.sql_hash_value = gv$session_longops.SQL_HASH_VALUE(+)
--and (nvl(gvs_longops.SOFAR,0) <> nvl(gvs_longops.TOTALWORK,1) or (select count(*) from gvs_longops gsl where gvs.SID = gsl.sid and  gvs.INST_ID = gsl.INST_ID and gvs.SERIAL# = gsl.SERIAL#) = 1)
and (
     nvl(gv$session_longops.TIME_REMAINING, 1) > 0
----     or (select count(*) from gvs_longops gsl where gvs.SID = gsl.sid and  gvs.INST_ID = gsl.INST_ID and gvs.SERIAL# = gsl.SERIAL# and gvs.sql_address = gsl.SQL_ADDRESS and gvs.sql_hash_value = gsl.SQL_HASH_VALUE) = 0
     or nvl(gv$session_longops.START_TIME, sysdate) = (select max(START_TIME) from gv$session_longops gsl where gvs.SID = gsl.sid and  gvs.INST_ID = gsl.INST_ID and gvs.SERIAL# = gsl.SERIAL# and gvs.sql_address = gsl.SQL_ADDRESS and gvs.sql_hash_value = gsl.SQL_HASH_VALUE)
     )
and gvs.sid = ses_optimizer_env38.sid(+) and gvs.INST_ID = ses_optimizer_env38.INST_ID(+)
and nvl(ses_optimizer_env38.id,38) = 38 --optimizer_mode
and gvs.sid = ses_optimizer_env48.sid(+) and gvs.INST_ID = ses_optimizer_env48.INST_ID(+)
and nvl(ses_optimizer_env48.id, 48) = 48--cursor_sharing
and gvs.LOCKWAIT = lockwait.KADDR(+)
and lockwait.id1 = lockhold.id1(+)
and lockwait.id2 = lockhold.id2(+)
and nvl(lockwait.REQUEST,1) > 0
and	nvl(lockwait.LMODE,0) = 0
and nvl(lockhold.REQUEST,0) = 0
and	nvl(lockhold.LMODE,1) > 0
and nvl(lockwait.SID,0) <> nvl(lockhold.SID,1)
and gvs.event not in ('Streams AQ: waiting for messages in the queue')
--and gvs.STATUS = 'KILLED'
--and ((gvs.USERNAME = 'SYS' and gvs.PROGRAM = 'plsqldev.exe') or gvs.PROGRAM like '%(P0%')
--and gvs.event = 'enq: TX - row lock contention'
--and gvs.PROGRAM = 'plsqldev.exe'
order by tx_stime, status, LOGON_TIME, username, gvs.sid
/