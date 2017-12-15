--
-- ASH wait tree for Waits Event or SQL_ID
-- Usage: SQL> @ash_wait_tree4stby "event = 'log file sync'"
-- Igor Usoltsev
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col LVL for 999
col BLOCKING_TREE for a30
col EVENT for a64
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col SQL_ID for a13
col EST_WAITS for 999999999
col EST_AVG_LATENCY_MS for 999999999

select LEVEL as LVL,
       LPAD(' ',(LEVEL-1)*2)||decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]{3}'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
wait_class,
       count(*) as WAITS_COUNT,
       count(distinct session_id) as SESS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS
       ,round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)) as EST_WAITS -- http://www.nocoug.org/download/2013-08/NOCOUG_201308_ASH_Architecture_and_Advanced%20Usage.pdf
       ,round(sum(1000)/round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 1 end))) as EST_AVG_LATENCY_MS
  from v$active_session_history ash
-- where session_state = 'WAITING'
 start with &&1
connect by nocycle prior ash.SAMPLE_ID = ash.SAMPLE_ID
       and ash.SESSION_ID = prior ash.BLOCKING_SESSION
 group by LEVEL,
          LPAD(' ',(LEVEL-1)*2)||decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]{3}'), nvl2(qc_session_id, 'PX', 'FOREGROUND')),
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue'),
wait_class
 order by LEVEL, count(*) desc
/
set feedback on echo off VERIFY ON