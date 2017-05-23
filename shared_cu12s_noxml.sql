set feedback on 1 heading on echo off VERIFY OFF

col reason#1 for a40
col reason#2 for a40
col reason#3 for a40
col reason#4 for a40

select
    inst_id,
    s.PLAN_HASH_VALUE,
       round(AVG(s.EXECUTIONS))                                                  as EXECS,
       round(AVG(s.ROWS_PROCESSED/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))        as ROWS_PER_EXEC,
       round(AVG(s.elapsed_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))          as ELA_PER_EXEC,
       round(AVG(s.cpu_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))              as CPU_PER_EXEC,
       round(AVG(s.parse_calls/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))           as PARSES_PER_EXEC,
       round(AVG(s.buffer_gets/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))           as GETS_PER_EXEC,
       round(AVG(s.disk_reads/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))            as READS_PER_EXEC,
       round(AVG(s.user_io_wait_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))     as UIO_PER_EXEC,
       round(AVG(s.concurrency_wait_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS))) as CONC_PER_EXEC,
       round(AVG(s.cluster_wait_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))     as CLU_PER_EXEC,
       round(AVG(s.PLSQL_EXEC_TIME/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)))       as PLSQL_PER_EXEC,
    s.optimizer_mode,
    to_char(max(s.last_active_time), 'dd.mm.yyyy hh24:mi:ss')                 as LAST_ACTIVE_TIME,
--    s.optimizer_cost,
    s.IS_BIND_SENSITIVE         as "BIND_SENSE",
    s.IS_BIND_AWARE             as "BIND_AWARE",
    use_feedback_stats          as "FEEDBACK_STATS",
    load_optimizer_stats        as "OPT_STATS",
    s.IS_REOPTIMIZABLE          as "REOPT",
    s.IS_RESOLVED_ADAPTIVE_PLAN as "ADAPT",
case when s.IS_RESOLVED_ADAPTIVE_PLAN is null then 'N' when s.IS_RESOLVED_ADAPTIVE_PLAN = 'N' then '' else 'Y' end as "ADAPT",
    bind_equiv_failure          as "BIND_EQ_FAIL",
    bind_mismatch,
    language_mismatch,
    stats_row_mismatch,
    PQ_SLAVE_MISMATCH,    
--    PX_MISMATCH,
--    MULTI_PX_MISMATCH,
--    bind_uacs_diff,
--    EXPLAIN_PLAN_CURSOR,
--    ROLL_INVALID_MISMATCH,
/*
    OPTIMIZER_MISMATCH,
    dbms_lob.substr(reason, dbms_lob.instr(reason, '</reason>', 1, 1) - dbms_lob.instr(reason, '<reason>', 1, 1) - 8, dbms_lob.instr(reason, '<reason>', 1, 1) + 8) reason#1,
    dbms_lob.substr(reason, dbms_lob.instr(reason, '</reason>', 1, 2) - dbms_lob.instr(reason, '<reason>', 1, 2) - 8, dbms_lob.instr(reason, '<reason>', 1, 2) + 8) reason#2,
    dbms_lob.substr(reason, dbms_lob.instr(reason, '</reason>', 1, 3) - dbms_lob.instr(reason, '<reason>', 1, 3) - 8, dbms_lob.instr(reason, '<reason>', 1, 3) + 8) reason#3,
*/
    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2) reason#1,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2) reason#2,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 3, NULL, 2) reason#3,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 4, NULL, 2) reason#4,
    trim(dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 1, NULL, 2), 100)) fix_control#1,
    count(*) as CURSOR_COUNT,
    count(distinct s.PLAN_HASH_VALUE) as PHV_COUNT,
    count(distinct s.FULL_PLAN_HASH_VALUE) as FPHV_COUNT,
    sum(s.EXECUTIONS)    as EXECS,
    sum(s.users_opening) as users_opening,
s.SQL_PLAN_BASELINE,
s.SQL_PATCH,
s.OUTLINE_CATEGORY,
s.SQL_PROFILE
  from gv$sql_shared_cursor sc join gv$sql s
       using (inst_id, sql_id, child_address)
 where sql_id = '&1'
 group by
    inst_id,
    s.PLAN_HASH_VALUE,
    s.optimizer_mode,
    s.IS_BIND_SENSITIVE,
    s.IS_BIND_AWARE,
    use_feedback_stats,
    load_optimizer_stats,
    s.IS_REOPTIMIZABLE,
    s.IS_RESOLVED_ADAPTIVE_PLAN,
case when s.IS_RESOLVED_ADAPTIVE_PLAN is null then 'N' when s.IS_RESOLVED_ADAPTIVE_PLAN = 'N' then '' else 'Y' end,
    bind_equiv_failure,
    bind_mismatch,
    language_mismatch,
    stats_row_mismatch,
    PQ_SLAVE_MISMATCH,    
--    PX_MISMATCH,
--    MULTI_PX_MISMATCH,
--    bind_uacs_diff,
--    EXPLAIN_PLAN_CURSOR,
--    ROLL_INVALID_MISMATCH,
    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2)
--    ,REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2)
--    ,REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 3, NULL, 2)
--    ,REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 4, NULL, 2)
    ,trim(dbms_lob.substr(REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 1, NULL, 2), 100))
,s.SQL_PLAN_BASELINE
,s.SQL_PATCH
,s.OUTLINE_CATEGORY
,s.SQL_PROFILE
 order by --count(*)
          max(s.last_active_time) --desc
/

set feedback on VERIFY ON