--
-- ASH wait tree starting from blocker
-- Usage: SQL> @ash_sql_block_tree_temp "program like '%LMS%'" 0
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col WAIT_LEVEL for 999
col BLOCKING_TREE for a30
col EVENT for a60
col SQL_TEXT for a100
col MODULE for a40
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col CLIENT_ID for a30

--with ash as (select /*+ materialize*/ * from ash_201409051700--gv$active_session_history
--		)
select LEVEL as LVL,
       inst_id,
--       BLOCKING_INST_ID,
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
        case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end as BLOCKING_TREE,
       case when module not like 'oracle%' then substr(module,1,9) else module end as MODULE,
       REGEXP_SUBSTR(client_id, '.+\#') as CLIENT_ID,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
--       lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0') as p1raw,
--       p2,
       count(1) as WAITS_COUNT,
       count(distinct sql_exec_id) as EXECS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS,
round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)) as est_waits, -- http://www.nocoug.org/download/2013-08/NOCOUG_201308_ASH_Architecture_and_Advanced%20Usage.pdf
round(sum(1000)/decode(round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)),0,1,round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)))) as est_avg_latency_ms,
       sql_id,
       nvl(plsql_entry_object_id, plsql_object_id)||'.'||nvl(plsql_entry_subprogram_id, plsql_subprogram_id) as PLSQL_OBJECT_ID,
       blocking_session_status||' i#'||blocking_inst_id as BLOCK_SID
--       ,sql_plan_line_ID
--       ,sql_plan_operation||' '||sql_plan_options
       ,trim(replace(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(13)),chr(9))) as sql_text
  from ash_201409051700--gv$active_session_history
       ash left join dba_hist_sqltext hs using(sql_id)
 start with &1
connect by nocycle (ash.SAMPLE_ID       = prior ash.SAMPLE_ID or abs(to_char(ash.sample_time,'SSSSS') - to_char(prior ash.sample_time,'SSSSS')) <= 1)
               and prior ash.SESSION_ID      = ash.BLOCKING_SESSION
               and prior ash.SESSION_SERIAL# = ash.BLOCKING_SESSION_SERIAL#
               and prior ash.INST_ID         = ash.BLOCKING_INST_ID
 group by LEVEL,
          inst_id,
--          BLOCKING_INST_ID,
        case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end,
       case when module not like 'oracle%' then substr(module,1,9) else module end,
          REGEXP_SUBSTR(client_id, '.+\#'),
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue'),
--          lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'),
--          p2,
          sql_id,
          nvl(plsql_entry_object_id, plsql_object_id)||'.'||nvl(plsql_entry_subprogram_id, plsql_subprogram_id),
          blocking_session_status||' i#'||blocking_inst_id
--          ,sql_plan_line_ID
--          ,sql_plan_operation||' '||sql_plan_options
          ,trim(replace(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(13)),chr(9)))
-- having count(distinct sample_id) > nvl('&2', 0)
 order by LEVEL, count(1) desc

/
set feedback on echo off VERIFY ON