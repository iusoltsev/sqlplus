set feedback off heading on echo off VERIFY OFF

col reason#1 for a40
col reason#2 for a40
col reason#3 for a40

select
    inst_id,
    s.PLAN_HASH_VALUE,
--    s.optimizer_cost,
--    s.IS_BIND_SENSITIVE  as "BIND_SENSE",
--    s.IS_BIND_AWARE      as "BIND_AWARE",
--    use_feedback_stats   as "FEEDBACK_STATS",
--    load_optimizer_stats as "OPT_STATS",
--    bind_equiv_failure   as "BIND_EQ_FAIL",
--    ROLL_INVALID_MISMATCH,
/*
    bind_uacs_diff,
    OPTIMIZER_MISMATCH,
    PQ_SLAVE_MISMATCH,    
    PX_MISMATCH,
    MULTI_PX_MISMATCH,
    dbms_lob.substr(reason, dbms_lob.instr(reason, '</reason>', 1, 1) - dbms_lob.instr(reason, '<reason>', 1, 1) - 8, dbms_lob.instr(reason, '<reason>', 1, 1) + 8) reason#1,
    dbms_lob.substr(reason, dbms_lob.instr(reason, '</reason>', 1, 2) - dbms_lob.instr(reason, '<reason>', 1, 2) - 8, dbms_lob.instr(reason, '<reason>', 1, 2) + 8) reason#2,
    dbms_lob.substr(reason, dbms_lob.instr(reason, '</reason>', 1, 3) - dbms_lob.instr(reason, '<reason>', 1, 3) - 8, dbms_lob.instr(reason, '<reason>', 1, 3) + 8) reason#3,
*/
    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2) reason#1,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2) reason#2,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 3, NULL, 2) reason#3,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 4, NULL, 2) reason#4,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 5, NULL, 2) reason#5,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 6, NULL, 2) reason#6,
    count(*) as CURSOR_COUNT,
    sum(s.EXECUTIONS)    as EXECS,
    sum(s.users_opening) as users_opening
  from gv$sql_shared_cursor sc join gv$sql s
       using (inst_id, sql_id, child_address)
 where sql_id = '&1'
 group by
    inst_id,
    s.PLAN_HASH_VALUE,
--    s.IS_BIND_SENSITIVE,
--    s.IS_BIND_AWARE,
--    use_feedback_stats,
--    load_optimizer_stats,
--    bind_equiv_failure,
--    ROLL_INVALID_MISMATCH,
    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2)--,
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2),
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 3, NULL, 2),
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 4, NULL, 2),
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 5, NULL, 2),
--    REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 6, NULL, 2)
 order by inst_id, count(*) desc
/

set feedback on VERIFY ON