--
-- ASH wait tree for Waits Event or SQL_ID
-- Usage: SQL> @ash_wait_tree "event = 'log file sync'" 100 "where sample_time < sysdate"
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col BLOCK_INST for 9999999999
col LVL for 999
col BLOCKING_TREE for a30
col EVENT for a64
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col SQL_ID for a13
col SQL_OPNAME for a20

with ash as (select /*+ materialize*/ CAST(sample_time AS DATE) as stime, s.* from gv$active_session_history s &3
		)
select --decode(LEVEL,1,'Waiter','Blocker#'||to_char(LEVEL-1)) as LVL,
       LEVEL as LVL,
       inst_id,
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
				case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(FOREGROUND)'
					when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
					when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
					when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
					else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
				end as BLOCKING_TREE,
--nvl2(xid,'*','') as xid,
--nvl2(sql_id,'*','') as sql_id,
--nvl2(client_id,'*','') as client_id,
--       blocking_inst_id as BLOCK_INST,
sql_opname,
--       ash.SQL_ID,
--       case when module not like 'oracle%' then substr(module,1,9) else module end as MODULE,
--       ash.SQL_OPNAME,
--       nvl2(ash.XID,'xid',''),
--       ash.current_obj#,
--       REGEXP_SUBSTR(client_id, '.+\#') as
--       CLIENT_ID,
--       module,
--       action,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
       wait_class,
--p1text, p1, p2text, p2, p3text, p3,
       count(*) as WAITS_COUNT,
       count(distinct inst_id||session_id||session_serial#) as SESS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS
,round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)) as est_waits -- http://www.nocoug.org/download/2013-08/NOCOUG_201308_ASH_Architecture_and_Advanced%20Usage.pdf
,round(sum(1000)/round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 1 end))) as est_avg_latency_ms
  from ash
-- where session_state = 'WAITING'
 start with &&1
connect by nocycle  --(ash.SAMPLE_ID       = prior ash.SAMPLE_ID or
                    --abs(ash.stime - prior ash.stime) <= 1/86400)
                    --ash.stime           = prior ash.stime)
                    abs(to_char(ash.sample_time,'SSSSS') - to_char(prior ash.sample_time,'SSSSS')) < 1/2
                and ash.SESSION_ID = prior ash.BLOCKING_SESSION
                and ash.inst_id = prior ash.BLOCKING_inst_id
 group by --decode(LEVEL,1,'Waiter','Blocker#'||to_char(LEVEL-1)),
          LEVEL,
          inst_id,
--          blocking_inst_id,
sql_opname,
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')),
				case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(FOREGROUND)'
					when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
					when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
					when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
					else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
				end,
            wait_class,
--          blocking_inst_id,
--          ash.SQL_ID,
--          case when module not like 'oracle%' then substr(module,1,9) else module end,
--       ash.SQL_OPNAME,
--       nvl2(ash.XID,'xid',''),
--          ash.current_obj#,
--          REGEXP_SUBSTR(client_id, '.+\#'),
--           client_id,
--           module,
--           action,
--p1text, p1, p2text, p2, p3text, p3,
--nvl2(xid,'*',''),
--nvl2(sql_id,'*',''),
--nvl2(client_id,'*',''),
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue')
 having count(distinct sample_id) > nvl('&&2', 1)
 order by LEVEL--, inst_id
	, count(*) desc
/
set feedback on echo off VERIFY ON