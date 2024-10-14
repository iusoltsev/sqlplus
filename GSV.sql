with gvs as (select /*+ materialize*/ * from gv$session)
select/*+ ordered rule */ distinct--because of multiple records in v$sql for PREV_SQL
to_char(gvs.LOGON_TIME,'YYYY.MM.DD HH24:MI:SS') as LOGON_TIME
, gvs.taddr as TADDR
, gv$transaction.START_TIME as TX_STIME
, gv$transaction.xid
, gv$transaction.USED_UBLK
, gv$transaction.USED_UREC
, gvs.LAST_CALL_ET as LAST_CALL_ET
, gvs.STATUS
, gvs.USERNAME 
, gvs.PROGRAM
, gvs.CLIENT_INFO
, gvs.CLIENT_IDENTIFIER
, gvs.ACTION
, gvs.SERVICE_NAME as service
, gvs.CON_ID
, gvs.INST_ID
, gvs.SID
, gvs.SERIAL#
, gvs.pdml_enabled
, decode(gv$session_wait.state, 'WAITING', gv$session_wait.EVENT, 'On CPU / runqueue') as EVENT
, gv$session_wait.state
, v$latchname.NAME as LATCHNAME
, gv$latchholder.sid
--, gvs.LOCKWAIT
, gv$session_wait.SECONDS_IN_WAIT
, dba_objects.owner||'.'||dba_objects.object_name req_object
, decode(sign(nvl(gvs.ROW_WAIT_OBJ#,-1)),-1,'NONE',DBMS_ROWID.ROWID_CREATE( 1, gvs.ROW_WAIT_OBJ#, gvs.ROW_WAIT_FILE#, gvs.ROW_WAIT_BLOCK#, gvs.ROW_WAIT_ROW# )) req_rowid
, lockhold.con_id as BLOCKING_CON_ID
, NVL(lockhold.inst_id, gvs.BLOCKING_INSTANCE) as BLOCKING_INSTANCE
, NVL(lockhold.sid,     gvs.BLOCKING_INSTANCE) as BLOCKING_SESSION
, gvs.FINAL_BLOCKING_INSTANCE
, gvs.FINAL_BLOCKING_SESSION
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
, gvs.SQL_EXEC_ID as SQL_EXEC_ID
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
, gvs.PORT
, gvs.MODULE
, gvs.OSUSER
, gvs.OWNERID
, gvs.TERMINAL
, 'Alter system kill session '''||gvs.SID||','||gvs.SERIAL#||','||'@'||gvs.INST_ID||''';' as KILL_SESSION
--, gvs.PROCESS
, gv$instance.HOST_NAME
, 'kill '||gv$process.SPID as KILL_SPID
, gv$process.PID
, gvs.process
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
and gvs.PROGRAM not like '%(PR__)%'
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
/*
and (
   nvl(gv$session_longops.TIME_REMAINING, 1) > 0
----     or (select count(*) from gvs_longops gsl where gvs.SID = gsl.sid and  gvs.INST_ID = gsl.INST_ID and gvs.SERIAL# = gsl.SERIAL# and gvs.sql_address = gsl.SQL_ADDRESS and gvs.sql_hash_value = gsl.SQL_HASH_VALUE) = 0
   or nvl(gv$session_longops.START_TIME, sysdate) = (select max(START_TIME) from gv$session_longops gsl where gvs.SID = gsl.sid and  gvs.INST_ID = gsl.INST_ID and gvs.SERIAL# = gsl.SERIAL# and gvs.sql_address = gsl.SQL_ADDRESS and gvs.sql_hash_value = gsl.SQL_HASH_VALUE)
   )
*/
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
--and (gvs.module like '%XXFI012%' or gvs.module like '%XXFI010%')
--and gvs.event = 'library cache: mutex X'
--and gvs.seconds_in_wait > 1000
--and gvs.logon_time < sysdate-1/24
--and gvs.CLIENT_IDENTIFIER like '%TM1H%'
--and gvs.event like 'single-task message'
--and (upper(gvs.program) like '%SQL%')
--and gvs.event = 'enq: SS - contention'
--and gvs.machine like 'trust%'
--and (gvs.USERNAME like '%PENKINAY%' or gvs.CLIENT_IDENTIFIER like '%PENKINAY%')
and (gvs.status in ( 'ACTIVE','KILLED'))-- or gvs.event like 'SQL*Net message % client')-- or (gvs.sid in (select sid from v$px_session union select qcsid from v$px_session)))
--and (gvs.client_identifier in ('SZHURAVEL','SHEBA','DEADINDIAN'))
--and (client_identifier like 'GetRequestChoices#%' or client_identifier like '%CreateInvoice#%' or client_identifier like 'CreateTransferMultiple#%')
--and (gvs.sql_id in ('89b6g0yvj69yn','4vh877tsu9s2x') or gvs.module = 'e:PA:cp:cse/CSENIEXP')
--and ((gvs.inst_id, gvs.sid) in (select inst_id, sid from gv$lock where id1 in (select object_id from dba_objects where owner='BO' and object_name = 'T_EXPORT_HISTORY')) or gvs.program like 'plsql%')
--and (gvs.client_identifier like 'MTERESHKINA' or gvs.sql_id = '6f8nsbmv8c4tc')-- and gv$sql.PLAN_HASH_VALUE = 811920337)-- or gvs.status = 'ACTIVE')-- or gvs.wait_class = 'User I/O')
--and gvs.username = 'BS' and gvs.client_identifier like 'wrapper#%'
--and gv$process.SPID in (10340,21572,23500,29575)
--and (gvs.sql_id in ('0tu8m20ty8wwz') or gvs.PREV_SQL_ID in ('0tu8m20ty8wwz'))--('7ffmzw6fqgg39'))
--and (gvs. client_identifier like '%VALIA-SKY%')
--and (gvs.SID=5)
--and gvs.sql_id in ('0h7abdv2xdpwn')
order by tx_stime, TADDR nulls last, status, LOGON_TIME, username, gvs.sid
--etc...

select service_name from gv$session where sql_id in ('0h7abdv2xdpwn') or PREV_SQL_ID in ('8wvd6g8yf9s35')

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434, 1, 165316, 165324));

78944025
SELECT * FROM TABLE(dbms_xplan.display_cursor( 'c46d3bjnuz5f0',0,format => 'all allstats advanced adaptive last'))--'adaptive'));--;

SELECT * FROM TABLE(dbms_xplan.display_cursor('gkd0y2jkp591z',5,format => 'all allstats advanced +adaptive last'))

select sql_id, count(*) from gv$session where status = 'ACTIVE' and inst_id = 1 group by sql_id order by count(*) desc

select * from v$instance
Alter system kill session '3720,39338';
select * from gv$session where program like '%J003%'

select event, current_obj#, count(*), count(distinct Session_serial#)
 from gv$active_session_history where 
(qc_Session_ID=2440 and qc_Session_serial# = 46804
 or Session_ID=2440 and Session_serial# = 46804)
and sample_time > sysdate - 1/24/60
group by event, current_obj#
order by count(*) desc
order by sample_time desc

select * from dba_objects where object_id = 2903202

select * from v$lock_type where type = 'PS'
--sql_id in ('8wvd6g8yf9s35') or PREV_SQL_ID in ('8wvd6g8yf9s35')

select sys_context('userenv','sid') from dual

select * from dba_scheduler_jobs where job_name = 'J_RFSH_MV_CLIENT_SAME_URLS'

select event,
       wait_class,
       sum(total_waits),
       sum(total_timeouts),
       sum(time_waited),
       round(avg(average_wait) * 10, 2) as AVG_WAIT_MS,
       round(RATIO_TO_REPORT(sum(time_waited)) OVER ()*100,2) AS PCTTOT
       , count(distinct inst_id||'#'||sid) as sess_count
  from GV$session_event
 where (sid) in ((5039))--(select inst_id, sid from gv$session where module like '%e:PER:cp:xxya/XXHR_DSS_NOTICE_CANCELLING%')
-- and wait_class <> 'Idle'
 group by event, wait_class
-- having sum(time_waited) > 5
 order by 5 desc

select case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
          when REGEXP_INSTR(program, '\(AS..\)')     > 0 then '(AS..)'
          when REGEXP_INSTR(program, '\(MS..\)')     > 0 then '(MS..)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end as PROG,
        module, action,
sql_id, session_state, event, count(*), count(distinct sql_exec_id), min(sample_time), max(sample_time) from system.ash_241018_iva_tmp
where sql_id is null
group by         case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
          when REGEXP_INSTR(program, '\(AS..\)')     > 0 then '(AS..)'
          when REGEXP_INSTR(program, '\(MS..\)')     > 0 then '(MS..)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end,
sql_id, session_state, event, module, action
having count(*) > 500
order by count(*) desc


select * from gv$event_name where name like 'SOLNYSHKOM'

select * from v$lock_type where type = 'HV'

SELECT lpad(' ', 2 * level) || pt.operation || ' ' || pt.options "Query Plan", pt.object_owner, pt.object_name 
, pt.cost, pt.cardinality, pt.bytes, pt.cpu_cost, pt.io_cost, pt.temp_space, pt.access_predicates, pt.filter_predicates
, pt.other_xml, pt.temp_space
  FROM (select * from v$sql_plan
                where --plan_hash_value = 457350947 and
--                hash_value = 1979532573 and
                sql_id = '2rv22xu1fjyg6'
                and child_number = 0
                ) pt
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0
 
select * from gv$px_process

select inst_id, sid, BLOCKING_INSTANCE, BLOCKING_session, SECONDS_IN_WAIT, status, state, event, level
from gv$session --where status = 'ACTIVE'
connect by nocycle prior inst_id = BLOCKING_INSTANCE and sid = BLOCKING_session

with se as (select inst_id, TADDR, LOGON_TIME, LAST_CALL_ET, sid, serial#, status, state, program, sql_id, SQL_CHILD_NUMBER SQL_CHILD
           ,decode(state,'WAITING',EVENT,'On CPU/runqueue')
           ,SECONDS_IN_WAIT
           ,decode(state,'WAITING',p1,'')
           ,decode(state,'WAITING',p2,'')
           ,decode(state,'WAITING',p3,'')
           ,sql_address, sql_hash_value
           ,ROW_WAIT_ROW#
            from gv$session
            where --(status = 'ACTIVE' or TADDR is not NULL) and 
            SERVICE_NAME not in ('SYS$BACKGROUND')
            and event <> 'Streams AQ: waiting for messages in the queue'
            )
select/*+ ordered */ se.*, sq.sql_text from se, gv$sql sq
where se.sql_address=sq.address(+)
and se.sql_hash_value=sq.hash_value(+)
and se.SQL_CHILD = sq.CHILD_NUMBER(+)
and se.INST_ID = sq.INST_ID(+)
order by TADDR nulls last, status, LOGON_TIME

select * from gv$instance

begin dbms_system.set_ev(10,20,10053,1,''); end;
	
begin dbms_system.set_ev(10,20,10053,0,''); end;


















select * from gv$sql where sql_id = '76anyj4rpbzuk' and USERS_EXECUTING > 0

begin sys.dbms_support.start_trace_in_session(1082,25438, waits=>TRUE, binds=>TRUE );end;

select * from v$instance

--??? locks and pins held on KGL objects
select distinct vs.sid, vs.serial#, vp.spid, vsql.child_number CN, vs.process pai, vs.username, vs.osuser, vs.machine
, to_char(floor(vs.last_call_et/3600),'fm0000')||':'||to_char(floor(mod(vs.last_call_et,3600)/60),'fm00')||':'||to_char(mod(mod(vs.last_call_et,3600),60),'fm00')||' Hs' "ACTIVE SINCE"
, to_char(vs.logon_time,'DD-MON-YY HH24:MI:SS') Logon
from v$session vs, v$process vp, dba_kgllock dk, v$sql vsql
where vs.paddr=vp.addr
AND DK.KGLLKUSE = VS.SADDR
AND DK.KGLLKHDL = VSQL.CHILD_ADDRESS
AND VS.SQL_ADDRESS = VSQL.ADDRESS
order by machine;

select vs.sid, vs.serial#, vp.spid, vs.process pai, vs.username, vs.osuser, vs.machine, vsql.SQL_ID, vsql.PLAN_HASH_VALUE, vsql.SQL_TEXT, vsql.child_number CN
, to_char(floor(vs.last_call_et/3600),'fm0000')||':'||to_char(floor(mod(vs.last_call_et,3600)/60),'fm00')||':'||to_char(mod(mod(vs.last_call_et,3600),60),'fm00')||' Hs' "ACTIVE SINCE"
, to_char(vs.logon_time,'DD-MON-YY HH24:MI:SS') Logon
from v$session vs, v$process vp, dba_kgllock dk, v$sql vsql
where vs.paddr=vp.addr
AND DK.KGLLKUSE = VS.SADDR
AND DK.KGLLKHDL = VSQL.CHILD_ADDRESS
AND VS.SQL_ADDRESS = VSQL.ADDRESS
order by machine

--Sessions waits trend (by Steve Adams)
select /*+ ordered */
  substr(n.name, 1, 29)  event,
  t0,
  t1,
  t2,
  t3,
  t4,
  t5,
  t6,
  t7,
  t8,
  t9
from
  sys.v_$event_name  n,
  (select event e0, count(*)  t0 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e1, count(*)  t1 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e2, count(*)  t2 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e3, count(*)  t3 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e4, count(*)  t4 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e5, count(*)  t5 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e6, count(*)  t6 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e7, count(*)  t7 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e8, count(*)  t8 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e9, count(*)  t9 from sys.v_$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6'))
where
  n.name != 'Null event' and
  n.name != 'rdbms ipc message' and
  n.name != 'pipe get' and
  n.name != 'virtual circuit status' and
  n.name not like '%timer%' and
  n.name not like 'SQL*Net message from %' and
  n.name not like 'Streams AQ%' and
  n.name not like '%slave wait%' and
  n.name not like '%idle%' and  
  e0 (+) = n.name and
  e1 (+) = n.name and
  e2 (+) = n.name and
  e3 (+) = n.name and
  e4 (+) = n.name and
  e5 (+) = n.name and
  e6 (+) = n.name and
  e7 (+) = n.name and
  e8 (+) = n.name and
  e9 (+) = n.name and
  nvl(t0, 0) + nvl(t1, 0) + nvl(t2, 0) + nvl(t3, 0) + nvl(t4, 0) + nvl(t5, 0) + nvl(t6, 0) + nvl(t7, 0) + nvl(t8, 0) + nvl(t9, 0) > 0
order by nvl(t0, 0) + nvl(t1, 0) + nvl(t2, 0) + nvl(t3, 0) + nvl(t4, 0) + nvl(t5, 0) + nvl(t6, 0) + nvl(t7, 0) + nvl(t8, 0) + nvl(t9, 0)

select * from gv$session where program like '%SMON%'

--Summary waits ratio for sessions with program name like X connected for last Y hours
select --WAIT_RANK,
 WAIT_EVENT
,lpad(TO_CHAR(PCTTOT,'990D99'),6)||'%' as WAIT_PCT
,WAIT_AVG_MS
,TIME_WAITED_MS
,TOTAL_WAITS
,TOTAL_TIMEOUTS
from (
           select RANK() OVER (order by sum(time_waited) desc)  as WAIT_RANK,
           event as WAIT_EVENT
          , sum(time_waited) as TIME_WAITED_MS
          , sum(TOTAL_WAITS) as TOTAL_WAITS
          , sum(TOTAL_TIMEOUTS) as TOTAL_TIMEOUTS
          ,round(RATIO_TO_REPORT(sum(time_waited)) OVER ()*100,2) AS PCTTOT
          ,round(avg(average_wait)*10,2) as WAIT_AVG_MS
          from 
                    (select se.SID, se.INST_ID, se.EVENT, se.TIME_WAITED, se.AVERAGE_WAIT, se.TOTAL_WAITS, se.TOTAL_TIMEOUTS from gv$session_event se
                    where se.WAIT_CLASS not in ('Idle')
                    union
                    select ss.SID, ss.INST_ID, sn.NAME as EVENT, ss.VALUE as TIME_WAITED, 0 as AVERAGE_WAIT, 0 as TOTAL_WAITS, 0 as TOTAL_TIMEOUTS from gv$sesstat ss, v$statname sn
                    where ss.STATISTIC# = sn.STATISTIC# and sn.NAME in ('CPU used when call started'))
          where (sid, inst_id) in (
                                    select sid, inst_id from gv$session
                                    where gv$session.SERVICE_NAME not in ('SYS$BACKGROUND')
                                    and UPPER(gv$session.program) like '%HTTP%'
                                    )
          group by event
          order by PCTTOT desc) we
-------------------------------------------------------------------------------

--select * from v$statname where name like '%arse%' or name like '%CPU%'
--Parse/Exec
  select decode(name, 'parse time cpu', us) from (
  select sn.NAME, sum(ss.VALUE) us
  from v$sesstat ss, v$statname sn
  where ss.STATISTIC# = sn.STATISTIC#
  and sn.NAME in ('CPU used when call started','parse time cpu','parse time elapsed','parse count (total)','parse count (hard)','parse count (failures)')
  and sid in (  select sid from v$session where
                        program like '%httpd%' and
                        LOGON_TIME > sysdate-60/1440 and
                        (v$session.SERVICE_NAME not in ('SYS$BACKGROUND')
                            OR
                        v$session.SERVICE_NAME in ('SYS$BACKGROUND') and (v$session.PROGRAM like '%DBW%' or v$session.PROGRAM like '%LGWR%')))
  group by sn.NAME
  )

select
max(decode(name, 'CPU used when call started', name||' '||us||' us; ', NULL))||
max(decode(name, 'parse time elapsed', name||' '||us||' us', NULL))
from
( select sn.NAME as name, sum(ss.VALUE) as us
  from v$sesstat ss, v$statname sn
  where ss.STATISTIC# = sn.STATISTIC#
  and sn.NAME in ('CPU used when call started','parse time cpu','parse time elapsed','parse count (total)','parse count (hard)','parse count (failures)')
  and sid in (  select sid from v$session where
                        program like '%httpd%' and
                        LOGON_TIME > sysdate-60/1440 and
                        (v$session.SERVICE_NAME not in ('SYS$BACKGROUND')
                            OR
                        v$session.SERVICE_NAME in ('SYS$BACKGROUND') and (v$session.PROGRAM like '%DBW%' or v$session.PROGRAM like '%LGWR%')))
  group by sn.NAME)

select * from gv$session where program like '%SMON%'
--Session Waits
select event, wait_class, sum(total_waits), sum(total_timeouts), sum(time_waited), round(avg(average_wait)) as average_wait_cs
from GV$session_event
where (sid, INST_ID) in
(select sid, INST_ID from gv$session where status = 'ACTIVE' and sql_id = '2417v14tca1r3')
group by event, wait_class
order by 5 desc

select event, wait_class, total_waits, total_timeouts, time_waited, average_wait
from GV$session_event
where sid in (1095)
and INST_ID = 1
order by time_waited desc

--Session statistics
select decode(v$statname.CLASS  , 1, 'User'
	   							, 2, 'Redo'
								, 4, 'Enqueue'
								, 8, 'Cache'
								, 16, 'OS'
								, 32, 'Parallel Server'
								, 64, 'SQL'
								, 128, 'Debug'
								, 'Unknown')
, v$statname.NAME, V$sesstat.VALUE
from V$sesstat, v$statname
where V$sesstat.SID = 457
and v$statname.STATISTIC#=V$sesstat.STATISTIC#
order by V$sesstat.VALUE desc

--OS Process remained from Oracle session
SELECT USERNAME, terminal, program, 'kill -9 '||spid
FROM gv$process p
WHERE NOT EXISTS ( SELECT 1
FROM gv$session s
WHERE paddr = addr and p.inst_id = s.inst_id)
and UPPER(program) not like '%PSEUDO%'
and UPPER(program) not like '%D00%'
and UPPER(program) not like '%S00%'
and UPPER(program) not like '%(PZ%'
and (p.inst_id, p.spid) not in (select inst_id, spid from gv$px_process where status = 'AVAILABLE')
/

oracle	UNKNOWN	oracle@key-db2f.yandex.ru	kill -9 1733
oracle	UNKNOWN	oracle@key-db2f.yandex.ru	kill -9 1770


select
decode(px.qcinst_id,NULL,username, 
' - '||lower(substr(pp.SERVER_NAME,
length(pp.SERVER_NAME)-4,4) ) )"Username",
decode(px.qcinst_id,NULL, 'QC', '(Slave)') "QC/Slave" ,
to_char( px.server_set) "SlaveSet",
to_char(s.sid) "SID",
to_char(px.inst_id) "Slave INST",
decode(sw.state,'WAITING', 'WAIT', 'NOT WAIT' ) as STATE,     
case  sw.state WHEN 'WAITING' THEN substr(sw.event,1,30) ELSE NULL end as wait_event ,
decode(px.qcinst_id, NULL ,to_char(s.sid) ,px.qcsid) "QC SID",
to_char(px.qcinst_id) "QC INST",
px.req_degree "Req. DOP",
px.degree "Actual DOP"
from gv$px_session px,
gv$session s ,
gv$px_process pp,
gv$session_wait sw
where px.sid=s.sid (+)
and px.serial#=s.serial#(+)
and px.inst_id = s.inst_id(+)
and px.sid = pp.sid (+)
and px.serial#=pp.serial#(+)
and sw.sid = s.sid  
and sw.inst_id = s.inst_id   
order by
  decode(px.QCINST_ID,  NULL, px.INST_ID,  px.QCINST_ID),
  px.QCSID,
  decode(px.SERVER_GROUP, NULL, 0, px.SERVER_GROUP), 
  px.SERVER_SET, 
  px.INST_ID

select 
  sw.SID as RCVSID,
  decode(pp.server_name, 
         NULL, 'A QC', 
         pp.server_name) as RCVR,
  sw.inst_id as RCVRINST,
case  sw.state WHEN 'WAITING' THEN substr(sw.event,1,30) ELSE NULL end as wait_event ,
  decode(bitand(p1, 65535),
         65535, 'QC', 
         'P'||to_char(bitand(p1, 65535),'fm000')) as SNDR,
  bitand(p1, 16711680) - 65535 as SNDRINST,
  decode(bitand(p1, 65535),
         65535, ps.qcsid,
         (select 
            sid 
          from 
            gv$px_process 
          where 
            server_name = 'P'||to_char(bitand(sw.p1, 65535),'fm000') and
            inst_id = bitand(sw.p1, 16711680) - 65535)
        ) as SNDRSID,
   decode(sw.state,'WAITING', 'WAIT', 'NOT WAIT' ) as STATE     
from 
  gv$session_wait sw,
  gv$px_process pp,
  gv$px_session ps
where
  sw.sid = pp.sid (+) and
  sw.inst_id = pp.inst_id (+) and 
  sw.sid = ps.sid (+) and
  sw.inst_id = ps.inst_id (+) and 
  p1text  = 'sleeptime/senderid' and
  bitand(p1, 268435456) = 268435456
order by
  decode(ps.QCINST_ID,  NULL, ps.INST_ID,  ps.QCINST_ID),
  ps.QCSID,
  decode(ps.SERVER_GROUP, NULL, 0, ps.SERVER_GROUP), 
  ps.SERVER_SET, 
  ps.INST_ID

select
decode(px.qcinst_id,NULL,username, 
' - '||lower(substr(pp.SERVER_NAME,
length(pp.SERVER_NAME)-4,4) ) )"Username",
decode(px.qcinst_id,NULL, 'QC', '(Slave)') "QC/Slave" ,
to_char( px.server_set) "SlaveSet",
to_char(px.inst_id) "Slave INST",
substr(opname,1,30)  operation_name,
substr(target,1,30) target,
sofar,
totalwork,
units,
start_time,
timestamp,
decode(px.qcinst_id, NULL ,to_char(s.sid) ,px.qcsid) "QC SID",
to_char(px.qcinst_id) "QC INST"
from gv$px_session px,
gv$px_process pp,
gv$session_longops s 
where px.sid=s.sid 
and px.serial#=s.serial#
and px.inst_id = s.inst_id
and px.sid = pp.sid (+)
and px.serial#=pp.serial#(+)
order by
  decode(px.QCINST_ID,  NULL, px.INST_ID,  px.QCINST_ID),
  px.QCSID,
  decode(px.SERVER_GROUP, NULL, 0, px.SERVER_GROUP), 
  px.SERVER_SET, 
  px.INST_ID

select * from gv$sgastat where upper(name)  like 'PX%'; 
