--
-- Real/everage gv$sqlstats from GV$SQL by PLAN_HASH_VALUE
-- Usage: 
-- SQL> @v$sqlstats2 &sql_id [&phv]
--                            ^PLAN_HASH_VALUE
--

set feedback off heading on timi off pages 200 lines 1000 echo off  VERIFY OFF

col INST for 9999
col EXECS for 999999999999
col CHILD for 99999
col BIND_SENSE for a10
col BIND_AWARE for a10
col SHAREABLE for a10
col USE_FEEDBACK_STATS for a18
col OPTIMIZER_STATS for a16
col BIND_EQ_FAILURE for a16
col reason#1 for a40
col reason#2 for a40
col reason#3 for a40
col reason#4 for a40
col fix_control#1 for a40
col fix_control#2 for a40
col SQL_PLAN_BASELINE for a30
col SQL_PATCH for a30
col SQL_PROFILE for a64
col ROLL for a4
col REOPT for a5
col ADAPT for a5
col FIRST_LOAD_TIME for a20
col LAST_LOAD_TIME for a20
col PARSE_USER for a30
col SPD_Valid for a9
col SPD_Used  for a9
col CURSOR_STATUS for a19
col DS_LEVEL for a8
col DOP for a3
col DOP_REASON for a30

pro
pro --------------------------------------------------------------

pro SQL_ID=&&1 Shared Pool statistics by PLAN_HASH_VALUE

pro --------------------------------------------------------------

select s.inst_id                                                                           as INST,
       sum(s.EXECUTIONS)                                                                   as EXECS,
       max(s.last_load_time)                                                               as LAST_LOAD_TIME,
       max(to_char(s.last_active_time, 'dd.mm.yyyy hh24:mi:ss'))                           as LAST_ACTIVE_TIME,
       round(sum(s.elapsed_time)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))          as ELA_PER_EXEC,
       round(sum(s.cpu_time)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))              as CPU_PER_EXEC,
       round(sum(s.parse_calls)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))           as PARSES_PER_EXEC,
       round(sum(s.buffer_gets)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))           as GETS_PER_EXEC,
       round(sum(s.disk_reads)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))            as READS_PER_EXEC,
       round(sum(s.user_io_wait_time)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))     as UIO_PER_EXEC,
       round(sum(s.concurrency_wait_time)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS))) as CONC_PER_EXEC,
       round(sum(s.cluster_wait_time)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))     as CLU_PER_EXEC,
       round(sum(s.PLSQL_EXEC_TIME)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))       as PLSQL_PER_EXEC,
       round(sum(s.FETCHES)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))               as FETCH_PER_EXEC,
       round(sum(s.ROWS_PROCESSED)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS)))        as ROWS_PER_EXEC,
       s.PLAN_HASH_VALUE,
       s.FULL_PLAN_HASH_VALUE,
       round(avg(s.optimizer_cost))                                                        as AVG_CBO_COST,
       count(distinct s.child_number)                                                      as CHILDS,
       max(s.IS_BIND_SENSITIVE)                                                            as "BIND_SENSE",
       max(s.IS_BIND_AWARE)                                                                as "BIND_AWARE",
       max(s.IS_REOPTIMIZABLE)                                                             as "REOPT",
       max(nvl(s.IS_RESOLVED_ADAPTIVE_PLAN,'N'))                                           as "ADAPT",
       s.SQL_PLAN_BASELINE,
       s.SQL_PATCH,
       s.OUTLINE_CATEGORY,
       s.SQL_PROFILE
  from gv$sql s
 where s.sql_id = '&1'
   and (s.PLAN_HASH_VALUE = NVL('&&2',s.PLAN_HASH_VALUE) or '&&2' = '0')
group by s.inst_id,
         s.PLAN_HASH_VALUE,
         s.FULL_PLAN_HASH_VALUE,
         s.SQL_PLAN_BASELINE,
         s.SQL_PATCH,
         s.OUTLINE_CATEGORY,
         s.SQL_PROFILE
order by max(to_char(s.last_active_time, 'dd.mm.yyyy hh24:mi:ss')),
         max(s.last_load_time)
--round(sum(s.elapsed_time)/decode(sum(s.EXECUTIONS),0,1,sum(s.EXECUTIONS))) desc
/
@@v$sqlstats &&1 &&2
set feedback on VERIFY ON