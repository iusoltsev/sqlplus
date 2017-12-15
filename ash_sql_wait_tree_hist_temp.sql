--
-- ASH wait tree for Waits Event or SQL_ID
-- Usage: SQL> @ash_sql_wait_tree_hist_temp "event = 'log file sync'" 111 113 10
-- Igor Usoltsev
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col LVL for 999
col BLOCKING_TREE for a60
col EVENT for a64
col CLIENT_ID for a40
col SQL_TEXT for a100
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col MIN_EXEC_TIME for a14
col MAX_EXEC_TIME for a14
col PLSQL_OBJECT_ID for a60
col DATA_OBJECT     for a50
col MODULE     for a40
col sql_opname for a25

with ash as (select /*+ materialize*/ CAST(sample_time AS DATE) as stime, s.* from SYSTEM.ASH_201711301351 s)--dba_hist_active_sess_history s where '&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
select LEVEL as LVL,
       instance_number,
--       BLOCKING_INST_ID,
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
        case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end as BLOCKING_TREE,
--       case when module not like 'oracle%' then substr(module,1,9) else module end as MODULE,
       REGEXP_SUBSTR(client_id, '.+\#') as CLIENT_ID,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
       lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0') as p1raw,
--       p2,
       count(1) as WAITS_COUNT,
       count(distinct sql_exec_id) as EXECS_COUNT,
       count(distinct session_id) as SESS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS,
--round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)) as est_waits, -- http://www.nocoug.org/download/2013-08/NOCOUG_201308_ASH_Architecture_and_Advanced%20Usage.pdf
--round(sum(1000)/decode(round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)),0,1,round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)))) as est_avg_latency_ms,
       p.owner||'.'||p.object_name||'.'||p.procedure_name as PLSQL_ENTRY_OBJECT_ID,
       p2.owner||'.'||p2.object_name||'.'||p2.procedure_name as PLSQL_OBJECT_ID,
       o.owner||'.'||o.object_name||'.'||o.subobject_name as DATA_OBJECT,
       blocking_session_status||' i#'||blocking_inst_id as BLOCK_SID,
min(sample_time) as min_stime,
max(sample_time) as max_stime,
       sql_ID
       ,sql_plan_line_ID
       ,sql_plan_operation||' '||sql_plan_options
       ,trim(replace(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(13)),chr(9))) as sql_text
  from --gv$active_session_history
      ash
       left join dba_hist_sqltext hs using(sql_id)
       left join dba_procedures   p  on plsql_entry_object_id     = p.object_id
                                    and plsql_entry_subprogram_id = p.subprogram_id
       left join dba_procedures   p2  on plsql_object_id          = p2.object_id
                                     and plsql_subprogram_id      = p2.subprogram_id
       left join dba_objects      o  on ash.current_obj# = o.object_id
 start with &1
connect by nocycle (--ash.SAMPLE_ID       = prior ash.SAMPLE_ID or 
                    trunc(ash.sample_time) = trunc(prior ash.sample_time) and
                    abs(to_char(ash.sample_time,'SSSSS') - to_char(prior ash.sample_time,'SSSSS')) <= 1)
                and ash.SESSION_ID      = prior ash.BLOCKING_SESSION
--              and ash.SESSION_SERIAL# = prior ash.BLOCKING_SESSION_SERIAL#
                and ash.instance_number = prior ash.BLOCKING_INST_ID
 group by LEVEL,
          instance_number,
--          BLOCKING_INST_ID,
        case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end,
--       case when module not like 'oracle%' then substr(module,1,9) else module end,
          REGEXP_SUBSTR(client_id, '.+\#'),
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue'),
          lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'),
--          p2,
          p.owner||'.'||p.object_name||'.'||p.procedure_name,
          p2.owner||'.'||p2.object_name||'.'||p2.procedure_name,
          o.owner||'.'||o.object_name||'.'||o.subobject_name,
          blocking_session_status||' i#'||blocking_inst_id,
          sql_ID
          ,sql_plan_line_ID
          ,sql_plan_operation||' '||sql_plan_options
          ,trim(replace(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(13)),chr(9)))
 having count(distinct sample_id) > nvl('&4', 0)
 order by LEVEL, count(1) desc
/*
with ash as (select --+ materialize
 * from dba_hist_active_sess_history where '&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
select LEVEL as LVL,
       instance_number as INST_ID,
       LPAD(' ',(LEVEL-1)*2)||decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
--       module,
       REGEXP_SUBSTR(client_id, '.+\#') as 		CLIENT_ID,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
--       session_state || ' ' || EVENT as EVENT,
--       lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'),
--       p2,
       wait_class,
       count(1) as WAITS_COUNT,
--       count(distinct sample_id) as WAITS_COUNT,
       count(distinct sql_exec_id) as EXECS_COUNT,
       count(distinct session_id) as SESS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS,
       sql_id,
--       top_level_sql_id,
       sql_opname,
--       p.owner||'.'||p.object_name||'.'||p.procedure_name as PLSQL_OBJECT_ID,
       o.owner||'.'||o.object_name||'.'||o.subobject_name as DATA_OBJECT,
--nvl2(o.object_name, DBMS_ROWID.ROWID_CREATE(1, ash.current_obj#, ash.current_file#, ash.current_block#, ash.current_row#),'') as RROWID,
       blocking_session_status||' i#'||blocking_inst_id as BLOCK_SID,
--       p1text, p1, p2text, p2, p3text, p3,
       sql_plan_line_ID--,
--       to_char(min(sample_time),'MM/DD HH24:MI:SS') as MIN_EXEC_TIME,
--       to_char(max(sample_time),'MM/DD HH24:MI:SS') as MAX_EXEC_TIME,
--       trim(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(9))) as sql_text
  from ash
       left join dba_hist_sqltext hs using(sql_id) --on ash.sql_id = hs.sql_id
       left join dba_procedures   p  on nvl(plsql_entry_object_id, plsql_object_id) = p.object_id
                                    and nvl(plsql_entry_subprogram_id, plsql_subprogram_id) = p.subprogram_id
       left join dba_objects      o  on ash.current_obj# = o.object_id
-- where session_state = 'WAITING'
 start with &&1
connect by nocycle (ash.SAMPLE_ID       = prior ash.SAMPLE_ID or abs(to_char(ash.sample_time,'SSSSS') - to_char(prior ash.sample_time,'SSSSS')) <= 1)
                and ash.SESSION_ID      = prior ash.BLOCKING_SESSION
                and ash.instance_number = prior ash.BLOCKING_inst_id
 group by LEVEL,
          instance_number,
          LPAD(' ',(LEVEL-1)*2)||decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')),
--          module,
          sql_opname,
          REGEXP_SUBSTR(client_id, '.+\#'),
--		CLIENT_ID,
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue'),
          wait_class,
--          session_state || ' ' || EVENT,
--          lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'),
--       p1text, p1, p2text, p2, p3text, p3,
          sql_id,
--          top_level_sql_id,
--          p.owner||'.'||p.object_name||'.'||p.procedure_name,
          o.owner||'.'||o.object_name||'.'||o.subobject_name,
--nvl2(o.object_name, DBMS_ROWID.ROWID_CREATE(1, ash.current_obj#, ash.current_file#, ash.current_block#, ash.current_row#),''),
          blocking_session_status||' i#'||blocking_inst_id,
          sql_plan_line_ID
--         ,trim(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(9)))
 having count(1) > nvl('&4',0)
 order by LEVEL, count(1) desc
*/
/
set feedback on echo off VERIFY ON