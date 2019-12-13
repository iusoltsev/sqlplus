--
-- ASH wait tree for Waits Event or SQL_ID
-- Usage: SQL> @ash_sql_wait3_dev "event = 'log file sync'" 100 "gv$active_session_history ash where sample_time > sysdate-1/24" "SQL CLI, OBJ, SERV, PLAN, CALL"
-- http://iusoltsev.wordpress.com
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col WAIT_LEVEL for 999
col BLOCKING_TREE for a60
col EVENT for a40
col SQL_TEXT for a200
col MODULE for a40
col CLIENT_ID for a50
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col DATA_OBJECT_p1raw for a52

with ash as (select /*+ materialize*/ CAST(sample_time AS DATE) as stime, ash.* from &3
--		where sample_time > sysdate-1/24
		)
select--+ parallel(4)
       LEVEL as LVL,
       ash.inst_id,
--       BLOCKING_INST_ID,
       LPAD(' ',(LEVEL-1)*2)||--decode(ash.session_type,'BACKGROUND',REGEXP_SUBSTR(program, '\([^\)]+\)'), nvl2(qc_session_id, 'PX', 'FOREGROUND')) as BLOCKING_TREE,
        case when program like 'rman%' then '(RMAN)'
          when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          when REGEXP_INSTR(program, '\(PR..\)')     > 0 then '(PR..)'
          when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
          when REGEXP_INSTR(program, '\(J...\)')     > 0 then '(J...)'
          when REGEXP_INSTR(program, '\(AS..\)')     > 0 then '(AS..)'
          when REGEXP_INSTR(program, '\(MS..\)')     > 0 then '(MS..)'
          when REGEXP_INSTR(program, '\(LMS.\)')     > 0 then '(LMS.)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end as BLOCKING_TREE,
--       case when module not like 'oracle%' then substr(module,1,9) else module end as MODULE,
--       REGEXP_SUBSTR(client_id, '.+\#') as CLIENT_ID,
decode(instr(upper('&&4'), 'CLI'), 0, 'Not Req.', REGEXP_SUBSTR(client_id, '.+\#')) as CLIENT_ID,
decode(instr(upper('&&4'), 'SERV'), 0, 'Not Req.', s.name) as SERVICE_NAME,
nvl2(xid,'X','') as XID,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
       wait_class,
       case when p1text = 'handle address' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'))
            when event = 'latch free' then to_char(p1)
            when event = 'enq: TM - contention' then chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535)||' '||bitand(p1, 65535)
            when event = 'row cache lock' then 'cache='||p1||' held='||decode(p2,0,'null',3,'share',5,'ex',10,'fail',p2)||' req='||decode(p3,0,'null',3,'share',5,'ex',10,'fail',p3)
       end as "P1[RAW]",
----       o.owner||'.'||o.object_name||'.'||o.subobject_name as DATA_OBJECT,
decode(instr(upper('&&4'), 'OBJ'), 0, 'Not Req.', o.owner||'.'||o.object_name||'.'||o.subobject_name) as DATA_OBJECT,
decode(instr(upper('&&4'), 'ROWID'), 0, 'Not Req.', DBMS_ROWID.ROWID_CREATE(1, ash.current_obj#, ash.current_file#, ash.current_block#, ash.current_row#)) as "ROWID",
--case when session_state='WAITING' and p1text='handle address' or event = 'latch: row cache objects' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0')) end as DATA_OBJECT_p1raw,
In_hard_Parse,
In_Parse,
In_Sql_Execution,
--sql_adaptive_plan_resolved as ADAPTIVE,
--sql_child_number,
--machine,
--program,
--module,
decode(instr(upper('&&4'), 'CALL'), 0, 'Not Req.', top_level_call_name) as top_level_call_name,
--top_level_call_name,
--       p1text, p1,
--       p2text, p2,
--       p3,
       count(1) as WAITS_COUNT,
       count(distinct sql_exec_id) as EXECS_COUNT,
       round(avg(time_waited) / 1000) as AVG_WAIT_TIME_MS,
--round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)) as est_waits, -- http://www.nocoug.org/download/2013-08/NOCOUG_201308_ASH_Architecture_and_Advanced%20Usage.pdf
--round(sum(1000)/decode(round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)),0,1,round(sum(case when time_waited > 0 then greatest(1, (1000000/time_waited)) else 0 end)))) as est_avg_latency_ms,
       count(distinct ash.inst_id||session_id||session_serial#) as SESS_COUNT,
--       max(count(distinct ash.inst_id||session_id||session_serial#)) over (partition by sample_time) as SESS_N_COUNT,
--       p.owner||'.'||p.object_name||'.'||p.procedure_name as PLSQL_OBJECT_ID,
       blocking_session_status||' i#'||blocking_inst_id as BLOCK_SID,
SQL_OPNAME,
min(sample_time) as min_stime,
max(sample_time) as max_stime
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', sql_ID)           as sql_ID
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', top_level_sql_id) as top_level_sql_id
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_hash_value) as sql_plan_hash_value
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', nvl2(sql_exec_id, 1, 0)) as sql_exec_id
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_line_ID) as plan_line_ID
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_operation||' '||sql_plan_options) as SQL_PLAN_OPERATION
--       ,trim(replace(replace(replace(dbms_lob.substr(sql_text,200),chr(10)),chr(13)),chr(9))) as sql_text
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', trim(replace(replace(replace(sql_text ,chr(10)),chr(13)),chr(9)))) as sql_text
  from --gv$active_session_history
      ash
       left join (select distinct sql_id, dbms_lob.substr(sql_fulltext,100) as sql_text from gv$sqlarea
                  union select sql_id, dbms_lob.substr(sql_text,100) as sql_text from dba_hist_sqltext) hs using(sql_id)--on NVL(ash.sql_id,ash.top_level_sql_id) = hs.sql_id--
       left join dba_procedures   p  on nvl(plsql_entry_object_id, plsql_object_id) = p.object_id
                                    and nvl(plsql_entry_subprogram_id, plsql_subprogram_id) = p.subprogram_id
       left join CDB_objects      o  on ash.current_obj# = o.object_id and ash.con_id = o.con_id
       left join gv$services      s  on name_hash = service_hash and ash.inst_id = s.inst_id
 start with &1
connect by
nocycle 
                    (--ash.SAMPLE_ID       = prior ash.SAMPLE_ID or 
                    trunc(ash.sample_time) = trunc(prior ash.sample_time) and
                    abs(to_char(ash.sample_time,'SSSSS') - to_char(prior ash.sample_time,'SSSSS')) < 1)
                and ash.SESSION_ID      = prior ash.BLOCKING_SESSION
                and ash.SESSION_SERIAL# = prior ash.BLOCKING_SESSION_SERIAL#
--                and ash.INST_ID         = prior ash.BLOCKING_INST_ID
 group by LEVEL,
          ash.inst_id,
--          BLOCKING_INST_ID,
        case when program like 'rman%' then '(RMAN)'
          when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
          when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
          when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
          when REGEXP_INSTR(program, '\(PR..\)')     > 0 then '(PR..)'
          when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
          when REGEXP_INSTR(program, '\(J...\)')     > 0 then '(J...)'
          when REGEXP_INSTR(program, '\(AS..\)')     > 0 then '(AS..)'
          when REGEXP_INSTR(program, '\(MS..\)')     > 0 then '(MS..)'
          when REGEXP_INSTR(program, '\(LMS.\)')     > 0 then '(LMS.)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end,
--       case when module not like 'oracle%' then substr(module,1,9) else module end,
----          REGEXP_SUBSTR(client_id, '.+\#'),
decode(instr(upper('&&4'), 'CLI'), 0, 'Not Req.', REGEXP_SUBSTR(client_id, '.+\#')),
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue'),
          wait_class,
--        case when p1text = 'handle address' or event = 'latch: row cache objects' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'))
--             else o.owner||'.'||o.object_name||'.'||o.subobject_name end,
       case when p1text = 'handle address' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'))
            when event = 'latch free' then to_char(p1)
            when event = 'enq: TM - contention' then chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535)||' '||bitand(p1, 65535)
            when event = 'row cache lock' then 'cache='||p1||' held='||decode(p2,0,'null',3,'share',5,'ex',10,'fail',p2)||' req='||decode(p3,0,'null',3,'share',5,'ex',10,'fail',p3)
       end,
--       o.owner||'.'||o.object_name||'.'||o.subobject_name,
decode(instr(upper('&&4'), 'OBJ'), 0, 'Not Req.', o.owner||'.'||o.object_name||'.'||o.subobject_name),
decode(instr(upper('&&4'), 'ROWID'), 0, 'Not Req.', DBMS_ROWID.ROWID_CREATE(1, ash.current_obj#, ash.current_file#, ash.current_block#, ash.current_row#)),
decode(instr(upper('&&4'), 'SERV'), 0, 'Not Req.', s.name),
nvl2(xid,'X',''),
--sql_adaptive_plan_resolved,
--sql_child_number,
--       o.owner||'.'||o.object_name||'.'||o.subobject_name,
--case when session_state='WAITING' and p1text='handle address' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0')) end,
--       p1text, p1,
In_hard_Parse,
In_Parse,
In_Sql_Execution
--machine,
--program,
--module,
,decode(instr(upper('&&4'), 'CALL'), 0, 'Not Req.', top_level_call_name)
,SQL_OPNAME
--       p2text, p2,
--          p3,
--          p.owner||'.'||p.object_name||'.'||p.procedure_name,
          ,blocking_session_status||' i#'||blocking_inst_id
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', sql_ID)
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', top_level_sql_id)
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_hash_value)
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', nvl2(sql_exec_id, 1, 0))
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_line_ID)
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_operation||' '||sql_plan_options)
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', trim(replace(replace(replace(sql_text ,chr(10)),chr(13)),chr(9))))
 having count(distinct sample_id) > nvl('&2', 0)
 order by LEVEL, count(1) desc
/
set feedback on echo off VERIFY ON