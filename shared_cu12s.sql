set feedback on 1 heading on echo off VERIFY OFF

select
    inst_id,
    s.PLAN_HASH_VALUE,
    sum(s.EXECUTIONS)                                                                      as EXECS,
    sum(s.users_opening)                                                                   as USERS_OPENING,
    round(SUM(s.ROWS_PROCESSED)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))           as ROWS_PER_EXEC,
    round(SUM(s.elapsed_time)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))             as ELA_PER_EXEC,
    round(SUM(s.cpu_time)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))                 as CPU_PER_EXEC,
    round(SUM(s.parse_calls)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))              as PARSES_PER_EXEC,
    round(SUM(s.buffer_gets)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))              as GETS_PER_EXEC,
    round(SUM(s.disk_reads)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))               as READS_PER_EXEC,
    round(SUM(s.user_io_wait_time)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))        as UIO_PER_EXEC,
    round(SUM(s.concurrency_wait_time)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))    as CONC_PER_EXEC,
    round(SUM(s.cluster_wait_time)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))        as CLU_PER_EXEC,
    round(SUM(s.PLSQL_EXEC_TIME)/decode(SUM(s.EXECUTIONS),0,1,SUM(s.EXECUTIONS)))          as PLSQL_PER_EXEC,
    s.optimizer_mode,
    to_char(max(NVL(s.last_active_time, TO_DATE(s.last_load_time,'YYYY-MM-DD/HH24:MI:SS')))
           ,'DD.MM.YYYY HH24:MI:SS')                                                       as LAST_ACTIVE_TIME,
    ROUND(AVG(s.optimizer_cost))                                                           as AVG_CBO_COST,
    s.IS_BIND_SENSITIVE                                                                    as "BIND_SENSE",
    s.IS_BIND_AWARE                                                                        as "BIND_AWARE",
    s.IS_REOPTIMIZABLE                                                                     as "REOPT",
    case
      when s.IS_RESOLVED_ADAPTIVE_PLAN is null then 'N'
      when s.IS_RESOLVED_ADAPTIVE_PLAN = 'N'   then '' else 'Y' end                        as "ADAPT",
    sc.NOT_SHARED_BY,
    rtrim(REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2) || chr(13) || chr(10) ||
          REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2), chr(13) || chr(10))               as REASON,
    rtrim(REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 1, NULL, 2) || chr(13) || chr(10) ||
          REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 2, NULL, 2), chr(13) || chr(10))     as FIX_CONTROL,
    count(*) as CURSOR_COUNT,
    count(distinct s.FULL_PLAN_HASH_VALUE)                                                 as FPHV_COUNT,
    s.SQL_PLAN_BASELINE,
    s.SQL_PATCH,
    s.OUTLINE_CATEGORY,
    s.SQL_PROFILE
  from gv$sql s
  join (select inst_id, child_address, sql_id, dbms_lob.substr(reason,4000) as REASON from gv$sql_shared_cursor)
       using(inst_id, child_address, sql_id)
  LEFT OUTER join
                  (select sql_id,
                          inst_id,
                          child_number,
                          listagg( reason_not_shared, chr(13) || chr(10)) WITHIN GROUP (order by inst_id, child_number)     as NOT_SHARED_BY
                   from gv$sql_shared_cursor
                   unpivot(val for reason_not_shared in(
                    UNBOUND_CURSOR,SQL_TYPE_MISMATCH,OPTIMIZER_MISMATCH,OUTLINE_MISMATCH,
                    STATS_ROW_MISMATCH,LITERAL_MISMATCH,FORCE_HARD_PARSE,EXPLAIN_PLAN_CURSOR,
                    BUFFERED_DML_MISMATCH,PDML_ENV_MISMATCH,INST_DRTLD_MISMATCH,SLAVE_QC_MISMATCH,
                    TYPECHECK_MISMATCH,AUTH_CHECK_MISMATCH,BIND_MISMATCH,DESCRIBE_MISMATCH,
                    LANGUAGE_MISMATCH,TRANSLATION_MISMATCH,BIND_EQUIV_FAILURE,INSUFF_PRIVS,
                    INSUFF_PRIVS_REM,REMOTE_TRANS_MISMATCH,LOGMINER_SESSION_MISMATCH,INCOMP_LTRL_MISMATCH,
                    OVERLAP_TIME_MISMATCH,EDITION_MISMATCH,MV_QUERY_GEN_MISMATCH,USER_BIND_PEEK_MISMATCH,
                    TYPCHK_DEP_MISMATCH,NO_TRIGGER_MISMATCH,FLASHBACK_CURSOR,ANYDATA_TRANSFORMATION,
                    PDDL_ENV_MISMATCH,TOP_LEVEL_RPI_CURSOR,DIFFERENT_LONG_LENGTH,LOGICAL_STANDBY_APPLY,
                    DIFF_CALL_DURN,BIND_UACS_DIFF,PLSQL_CMP_SWITCHS_DIFF,CURSOR_PARTS_MISMATCH,
                    STB_OBJECT_MISMATCH,CROSSEDITION_TRIGGER_MISMATCH,PQ_SLAVE_MISMATCH,TOP_LEVEL_DDL_MISMATCH,
                    MULTI_PX_MISMATCH,BIND_PEEKED_PQ_MISMATCH,MV_REWRITE_MISMATCH,ROLL_INVALID_MISMATCH,
                    OPTIMIZER_MODE_MISMATCH,PX_MISMATCH,MV_STALEOBJ_MISMATCH,FLASHBACK_TABLE_MISMATCH,
                    LITREP_COMP_MISMATCH,PLSQL_DEBUG,LOAD_OPTIMIZER_STATS,ACL_MISMATCH,
                    FLASHBACK_ARCHIVE_MISMATCH,LOCK_USER_SCHEMA_FAILED,REMOTE_MAPPING_MISMATCH,LOAD_RUNTIME_HEAP_FAILED,
                    HASH_MATCH_FAILED,PURGED_CURSOR,BIND_LENGTH_UPGRADEABLE,USE_FEEDBACK_STATS
                   ))
                   where val = 'Y'
                   group by sql_id, inst_id, child_number
                   ) sc
         using(inst_id, child_number, sql_id)
 where sql_id = '&&1'
  and (plan_hash_value = NVL('&&2',plan_hash_value) or '&&2' = '0')
 group by
    inst_id,
    s.PLAN_HASH_VALUE,
    s.optimizer_mode,
    s.IS_BIND_SENSITIVE,
    s.IS_BIND_AWARE,
    s.IS_REOPTIMIZABLE,
    s.IS_RESOLVED_ADAPTIVE_PLAN,
    case when s.IS_RESOLVED_ADAPTIVE_PLAN is null then 'N' when s.IS_RESOLVED_ADAPTIVE_PLAN = 'N' then '' else 'Y' end,
    sc.NOT_SHARED_BY,
    rtrim(REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2) || chr(13) || chr(10) ||
          REGEXP_SUBSTR ( reason, '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2), chr(13) || chr(10)),
    rtrim(REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 1, NULL, 2) || chr(13) || chr(10) ||
          REGEXP_SUBSTR ( reason, '<(_fix_control_key)>([^<]+)</\1>', 1, 2, NULL, 2), chr(13) || chr(10)),
    s.SQL_PLAN_BASELINE,
    s.SQL_PATCH,
    s.OUTLINE_CATEGORY,
    s.SQL_PROFILE
 order by max(NVL(s.last_active_time, TO_DATE(s.last_load_time,'YYYY-MM-DD/HH24:MI:SS')))
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
