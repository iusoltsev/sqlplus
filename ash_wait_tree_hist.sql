--
-- ASH wait tree history for Waits Event or SQL_ID
-- Usage: SQL> @ash_wait_tree_hist.sql "event = 'log file sync'" 1001           1002
--                                      ^condition               ^start snap_id ^finish snap_id
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col LVL for 999
col BLOCKING_TREE for a30
col EVENT for a64
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999

with ash as (select /*+ materialize*/ * from dba_hist_active_sess_history where '&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
select LEVEL as LVL,
       instance_number as INST_ID,
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
				case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(FOREGROUND)'
					when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
					when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
					else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
				end as BLOCKING_TREE,
--       ash.SQL_ID,
--       ash.SQL_OPNAME,
--       nvl2(ash.XID,'xid',''),
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
--sql_plan_operation,
--p1,p2,p3,
       count(*) as WAITS_COUNT,
       count(distinct session_id) as SESS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS
--,round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)) as est_waits -- http://www.nocoug.org/download/2013-08/NOCOUG_201308_ASH_Architecture_and_Advanced%20Usage.pdf
--,round(sum(1000)/round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 1 end))) as est_avg_latency_ms
, min(sample_time)
, max(sample_time)
  from ash
-- where session_state = 'WAITING' 
 start with &&1
connect by nocycle (abs(to_char(ash.sample_time,'SSSSS') - to_char(prior ash.sample_time,'SSSSS')) <= 1)
                    --ash.stime           = prior ash.stime)
                and ash.SESSION_ID = prior ash.BLOCKING_SESSION
                and ash.instance_number = prior ash.BLOCKING_inst_id
 group by LEVEL,
          instance_number,
          LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
				case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(FOREGROUND)'
					when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
					when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
					else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
				end,
--        ash.SQL_ID,
--       ash.SQL_OPNAME,
--       nvl2(ash.XID,'xid',''),
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue')
--,p1,p2,p3
--, sql_plan_operation
 order by instance_number, LEVEL, count(*) desc
/
set feedback on echo off VERIFY ON