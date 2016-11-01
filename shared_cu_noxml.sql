--
-- High version count reason for 11.2.0.2+
-- Usage: 
-- SQL> @shared_cu &sql_id
--

set feedback off heading on pages 200 lines 600 echo off  VERIFY OFF
col INST for 9999
col EXECS for 99999999
col CHILD for 99999
col BIND_SENSE for a10
col BIND_AWARE for a10
col SHAREABLE for a10
col USE_FEEDBACK_STATS for a18
col OPTIMIZER_STATS for a16
col BIND_EQ_FAILURE for a16
col Reason for a60
col SQL_PLAN_BASELINE for a30
col SQL_PATCH for a30
col SQL_PROFILE for a64
col DS_LEVEL for a8
col DOP for a3
col DOP_REASON for a30

select s.inst_id as INST,
       s.EXECUTIONS as EXECS,
       to_char(to_date(s.last_load_time, 'yyyy-mm-dd/hh24:mi:ss'), 'dd.mm hh24:mi:ss') as last_load_time,
       s.users_opening,
       to_char(s.last_active_time, 'dd.mm hh24:mi:ss') as last_active_time,
       round(s.elapsed_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)) as ELA_PER_EXEC,
       s.PLAN_HASH_VALUE,
       s.optimizer_cost,
       s.child_number as CHILD,
       s.IS_BIND_SENSITIVE as "BIND_SENSE",
       s.IS_BIND_AWARE as "BIND_AWARE",
       s.IS_SHAREABLE as "SHAREABLE",
       use_feedback_stats as USE_FEEDBACK_STATS,
       load_optimizer_stats as OPTIMIZER_STATS,
       bind_equiv_failure as BIND_EQ_FAILURE,
       ROLL_INVALID_MISMATCH,
       bind_uacs_diff,
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="dynamic_sampling" note="y">([^<]+)</\1>', 1, 1, NULL, 2) as DS_LEVEL,
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="dop" note="y">([^<]+)</\1>', 1, 1, NULL, 2)              as DOP,
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="dop_reason" note="y">([^<]+)</\1>', 1, 1, NULL, 2)       as DOP_REASON,
       REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 1, NULL, 2) reason#1,
       REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 2, NULL, 2) reason#2,
       REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 3, NULL, 2) reason#3,
       REGEXP_SUBSTR ( dbms_lob.substr(reason,4000), '<(reason)>([^<]+)</\1>', 1, 4, NULL, 2) reason#4,
       SQL_PLAN_BASELINE,
       SQL_PATCH,
       OUTLINE_CATEGORY,
       SQL_PROFILE,
       IS_OBSOLETE
  from gv$sql_shared_cursor sc
  join gv$sql s on sc.inst_id = s.inst_id and sc.child_address = s.child_address and sc.sql_id = s.sql_id
  left join gv$sql_plan p on p.inst_id = s.inst_id and p.child_address = s.child_address and p.sql_id = s.sql_id and p.other_xml is not null
 where s.sql_id = '&1'
   and s.PLAN_HASH_VALUE = NVL('&2',s.PLAN_HASH_VALUE)
order by s.inst_id, --s.child_number
	s.last_active_time desc
/
set feedback on VERIFY ON timi on