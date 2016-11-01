--
-- ASH wait tree for Waits Event or SQL_ID
-- Usage: SQL> @ash_block_tree "event = 'log file sync'"
-- Igor Usoltsev
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

with ash as (select /* materialize*/ * from gv$active_session_history &3)
select --decode(LEVEL,1,'Waiter','Blocker#'||to_char(LEVEL-1)) as LVL,
       LEVEL as LVL,
       inst_id,
--       LPAD(' ',(LEVEL-1)*2)||decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
				case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(FOREGROUND)'
					when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
					when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
					when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
					else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
				end as BLOCKING_TREE,
--       blocking_inst_id as BLOCK_INST,
--sql_opcode,
--       ash.SQL_ID,
--       case when module not like 'oracle%' then substr(module,1,9) else module end as MODULE,
--       ash.SQL_OPNAME,
--       ash.current_obj#,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
       count(*) as WAITS_COUNT,
       count(distinct session_id) as SESS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS
  from ash
-- where session_state = 'WAITING'
 start with &&1
connect by nocycle prior ash.SAMPLE_ID = ash.SAMPLE_ID
       and prior ash.SESSION_ID = ash.BLOCKING_SESSION
       and prior ash.inst_id = ash.BLOCKING_inst_id
 group by --decode(LEVEL,1,'Waiter','Blocker#'||to_char(LEVEL-1)),
          LEVEL,
          inst_id,
--          blocking_inst_id,
--sql_opcode,
--          LPAD(' ',(LEVEL-1)*2)||decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')),
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
				case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(FOREGROUND)'
					when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
					when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
					when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
					else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
				end,
--          blocking_inst_id,
--          ash.SQL_ID,
--          case when module not like 'oracle%' then substr(module,1,9) else module end,
--          ash.SQL_OPNAME,
--          ash.current_obj#,
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue')
 having count(distinct sample_id) > nvl('&&2', 1)
 order by inst_id, LEVEL, count(*) desc
/
set feedback on echo off VERIFY ON