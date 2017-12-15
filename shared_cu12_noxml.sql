--
-- SQL child cursor generation properties for 12.1.0.1+ (quick, w/o XML functions)
-- Usage: 
-- SQL> @shared_cu12_noxml &sql_id [&phv]
--                                  ^PLAN_HASH_VALUE
--

set feedback on 1 heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col INST for 9999
col EXECS for 999999999999
col CHILD for 99999
col BIND_SENSE for a10
col BIND_AWARE for a10
col SHAREABLE for a10
col USE_FEEDBACK_STATS for a18
col OPTIMIZER_STATS for a16
col BIND_EQ_FAILURE for a16
col reason#1 for a48
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
col FIRST_LOAD_TIME for a20
col LAST_LOAD_TIME for a20
col PARSE_USER for a30
col SPD_Valid for a9
col SPD_Used  for a9
col CURSOR_STATUS for a19
col DS_LEVEL for a8
col DOP for a3
col DOP_REASON for a30
col min_sample_time for a25
col max_sample_time for a25
col "DURATIONs" for a25
col "V$SQL.Adapt" for a11
col "XML.Adapt"   for a9
col CF            for a3

select s.inst_id    as INST,
       s.EXECUTIONS as EXECS,
       s.users_opening,
       s.first_load_time,
       s.last_load_time,
      (select username from dba_users where user_id = s.parsing_user_id)    as PARSE_USER,
       to_char(s.last_active_time, 'dd.mm.yyyy hh24:mi:ss')                 as LAST_ACTIVE_TIME,
       round(s.ROWS_PROCESSED/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))        as ROWS_PER_EXEC,
       round(s.elapsed_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))          as ELA_PER_EXEC,
       round(s.cpu_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))              as CPU_PER_EXEC,
       round(s.parse_calls/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))           as PARSES_PER_EXEC,
       round(s.buffer_gets/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))           as GETS_PER_EXEC,
       round(s.disk_reads/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))            as READS_PER_EXEC,
       round(s.user_io_wait_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))     as UIO_PER_EXEC,
       round(s.concurrency_wait_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)) as CONC_PER_EXEC,
       round(s.cluster_wait_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))     as CLU_PER_EXEC,
       round(s.PLSQL_EXEC_TIME/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))       as PLSQL_PER_EXEC,
       s.object_status as CURSOR_STATUS,
       s.PLAN_HASH_VALUE,
       s.FULL_PLAN_HASH_VALUE,
       s.optimizer_cost,
       s.child_number as CHILD,
       s.IS_BIND_SENSITIVE as "BIND_SENSE",
       s.IS_BIND_AWARE as "BIND_AWARE",
       s.IS_SHAREABLE as "SHAREABLE",
       load_optimizer_stats as OPTIMIZER_STATS,
       sc.use_feedback_stats as USE_FEEDBACK_STATS,
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="cardinality_feedback" note="y">([^<]+)</\1>', 1, 1, NULL, 2) as CF,
       s.IS_REOPTIMIZABLE as "REOPT",
       rh.REOPT_HINTS,
--       s.IS_RESOLVED_ADAPTIVE_PLAN as "ADAPT",
       case when s.IS_RESOLVED_ADAPTIVE_PLAN is null then 'N' when s.IS_RESOLVED_ADAPTIVE_PLAN = 'N' then '' else 'Y' end         as "V$SQL.Adapt",
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="adaptive_plan" note="y">([^<]+)</\1>', 1, 1, NULL, 2)    as "XML.Adapt",
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(cv)>([^<]+)</\1>', 1, 1, NULL, 2) as "SPD_Valid",
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(cu)>([^<]+)</\1>', 1, 1, NULL, 2) as "SPD_Used",
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="dynamic_sampling" note="y">([^<]+)</\1>', 1, 1, NULL, 2) as DS_LEVEL,
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="dop" note="y">([^<]+)</\1>', 1, 1, NULL, 2)              as DOP,
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="dop_reason" note="y">([^<]+)</\1>', 1, 1, NULL, 2)       as DOP_REASON,
       bind_equiv_failure as BIND_EQ_FAILURE,
CURSOR_PARTS_MISMATCH,
       ROLL_INVALID_MISMATCH as "ROLL",
       dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2), 100) reason#1,
       dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2), 100) reason#2,
       dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 3, NULL, 2), 100) reason#3,
       dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 4, NULL, 2), 100) reason#4,
       trim(dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 1, NULL, 2), 100)) fix_control#1,
       trim(dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 2, NULL, 2), 100)) fix_control#2,
       SQL_PLAN_BASELINE,
       SQL_PATCH,
       OUTLINE_CATEGORY,
       SQL_PROFILE,
       IS_OBSOLETE
  from gv$sql_shared_cursor sc
  join gv$sql s on sc.inst_id = s.inst_id and sc.child_address = s.child_address and sc.sql_id = s.sql_id
  left join gv$sql_plan p on p.inst_id = s.inst_id and p.child_address = s.child_address and p.sql_id = s.sql_id and p.other_xml is not null
  left join (select inst_id, sql_id, child_number, count(*) as REOPT_HINTS from gv$sql_reoptimization_hints group by inst_id, sql_id, child_number) rh
    on rh.inst_id = s.inst_id and rh.child_number = s.child_number and rh.sql_id = s.sql_id
 where s.sql_id = '&&1'
   and (s.PLAN_HASH_VALUE = NVL('&&2',s.PLAN_HASH_VALUE) or '&&2' = '0')
order by 
      s.last_active_time,
      s.last_load_time,
      s.inst_id -- s.EXECUTIONS,
/
@@v$sqlstats2 &&1 &&2
pro
pro --------------------------------------------------------------
pro ASH TOP5 SQL_ID=&&1 Executions by Elapsed Time
pro --------------------------------------------------------------
select *
  from (select inst_id,
               sql_id,
               sql_plan_hash_value,
--               sql_full_plan_hash_value,
               sql_exec_id,
               sql_child_number                    as CHILD_ID,
               count(distinct sample_id)           as ash_rows,
               max(sample_time) - min(sample_time) as "DURATIONs",
               min(sample_time)                    as min_sample_time,
               max(sample_time)                    as max_sample_time
          from gv$active_session_history
         where sql_id = '&&1'
           and (sql_plan_hash_value = NVL('&&2',sql_plan_hash_value) or '&&2' = '0')
           and sql_exec_id > 0
         group by inst_id, sql_id, sql_child_number, sql_exec_id, sql_plan_hash_value
--, sql_full_plan_hash_value
         order by count(distinct sample_id) desc)
 where rownum <= 15
/
set feedback on VERIFY ON