--
-- ASH wait tree for Waits Event or SQL_ID
-- Usage: SQL> @ash_sql_wait3_dev_hist "sql_id = '83w0zrqyzathc'" 0 "where snap_id between 43425 and 43433" "INST SQL, QUERY, EVENT, MODULE, ACTION, CLI, OBJ, SERV, PLAN, CALL, PL/ ROWID PARAM"
-- http://iusoltsev.wordpress.com
--

set echo off feedback off heading on timi off pages 1000 lines 5000 VERIFY OFF

col INST_ID for 9999999
col WAIT_LEVEL for 999
col BLOCKING_TREE for a100
col EVENT for a60
col SQL_TEXT for a200
col MODULE for a80
col ACTION for a80
col CLIENT_ID for a60
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col DATA_OBJECT_p1raw for a52
col BLOCK_STATUS for a20
col XID_LIST for a200
col SID_LIST for a200
col QC_SID_LIST       for a200
col BLOKER_LIST                for a200

col SQL_OPNAME for a30






with ash as (select /*+ materialize*/ CAST(sample_time AS DATE) as stime, ash.* from dba_hist_active_sess_history ash &3
--		where sample_time > sysdate-1/24
		)
select--+ parallel(8) opt_param('_fix_control' '16166364:off')
       LEVEL as LVL,
       CONNECT_BY_ISCYCLE as ISCYCLE,
LISTAGG(distinct ash.instance_number, ',' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY 1) as INST_LIST,
decode(instr(upper('&&4'), 'INST'), 0, '0', ash.instance_number) as inst,
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
          when REGEXP_INSTR(program, '\(W...\)')     > 0 then '(W...)'
          when REGEXP_INSTR(program, '\(DBW.\)')     > 0 then '(DBW.)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end as BLOCKING_TREE,
--       case when module not like 'oracle%' then substr(module,1,9) else module end as MODULE,
--       REGEXP_SUBSTR(client_id, '.+\#') as CLIENT_ID,
decode(instr(upper('&&4'), 'CLI'), 0, 'Not Req.', case when client_id like '%#%' then REGEXP_SUBSTR(client_id, '.+\#') else client_id end) as CLIENT_ID,
decode(instr(upper('&&4'), 'SERV'), 0, 'Not Req.', s.name) as SERVICE_NAME,
decode(instr(upper('&&4'), 'MODULE'), 0, 'Not Req.', MODULE) as MODULE,
decode(instr(upper('&&4'), 'ACTION'), 0, 'Not Req.', ACTION) as ACTION,
nvl2(xid,' X ','') as XID,
decode(instr(upper('&&4'), 'EVENT'), 0, 'Not Req.', decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue')) as EVENT,
       wait_class,
/*
       case when p1text = 'handle address' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'))
            when event = 'latch free' then to_char(p1) 
            when event = 'enq: UL - contention' then to_char(p2)--(select NAME from dbms_lock_allocated where lockid = p2)
            when event = 'DFS lock handle' then p1||' '||p2
       end as "Parameters",
*/
decode(instr(upper('&&4'), 'PARAM'), 0, 'Not Req.',
       case when ash.p1text = 'handle address' then upper(lpad(trim(to_char(ash.p1,'xxxxxxxxxxxxxxxx')),16,'0'))||';'||'p3='||ash.p3text||' 0x'||lpad(trim(to_char(ash.p3,'xxxxxxxxxxxxxxxx')),6,'0')
            when ash.event = 'latch free' then upper(lpad(trim(to_char(ash.p1,'xxxxxxxxxxxxxxxx')),16,'0'))--to_char(ash.p1)
            when ash.event = 'enq: UL - contention' then to_char(ash.p2)--(select NAME from dbms_lock_allocated where lockid = p2)
            when ash.event = 'enq: TM - contention' then chr(bitand(ash.p1,-16777216)/16777215)||chr(bitand(ash.p1, 16711680)/65535)||' '||bitand(ash.p1, 65535)
            when ash.event = 'row cache lock' then 'cache='||ash.p1||' held='||decode(ash.p2,0,'null',3,'share',5,'ex',10,'fail',ash.p2)||' req='||decode(ash.p3,0,'null',3,'share',5,'ex',10,'fail',ash.p3)
            when ash.event = 'row cache mutex' then ash.p1text||'='||ash.p1||' '||ash.p2text||'='||ash.p2
            when ash.event = 'enq: JI - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: MS - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: TQ - DDL contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: SQ - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: HW - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'DFS lock handle' then ash.p1||' '||ash.p2
            when ash.event = 'rdbms ipc reply' then ash.p1text||' '||ash.p1
       end) as "Param[RAW]",
----       o.owner||'.'||o.object_name||'.'||o.subobject_name as DATA_OBJECT,
decode(instr(upper('&&4'), 'OBJ'), 0, 'Not Req.', ash.current_obj#||' '||o.owner||'.'||o.object_name||'.'||o.subobject_name) as DATA_OBJECT,
decode(instr(upper('&&4'), 'OBJ'), 0, 'Not Req.', decode(current_obj#,0,'0',-1,'-1','No')) as Undo,
decode(instr(upper('&&4'), 'ROWID'), 0, 'Not Req.', DBMS_ROWID.ROWID_CREATE(1, ash.current_obj#, ash.current_file#, ash.current_block#, ash.current_row#)) as "ROWID",
--case when session_state='WAITING' and p1text='handle address' or event = 'latch: row cache objects' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0')) end as DATA_OBJECT_p1raw,
SQL_OPNAME,
In_hard_Parse,
In_Parse,
In_Sql_Execution,
in_connection_mgmt as In_conn_mgmt,
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
       count(distinct ash.instance_number||session_id||session_serial#) as SESS_COUNT,
--       p.owner||'.'||p.object_name||'.'||p.procedure_name as PLSQL_OBJECT_ID,
decode(instr(upper('&&4'), 'PL/'), 0, 'Not Req.', p.owner||'.'||p.object_name||'.'||p.procedure_name) as PLSQL_OBJECT,
       blocking_session_status||' i#'||decode(instr(upper('&&4'), 'INST'), 0, '0', blocking_inst_id) as BLOCK_STATUS,
count(distinct blocking_inst_id||'*'||blocking_session||'*'||blocking_session_serial#) as BLOCKERS,
min(sample_time) as min_stime,
max(sample_time) as max_stime
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', sql_ID)           as sql_ID
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', top_level_sql_id) as top_level_sql_id
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_hash_value) as sql_plan_hash_value
--,nvl2(sql_exec_id, 1, 0) as sql_exec_id
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_line_ID) as plan_line_ID
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_operation||' '||sql_plan_options) as SQL_PLAN_OPERATION
--       ,trim(replace(replace(replace(dbms_lob.substr(sql_text,200),chr(10)),chr(13)),chr(9))) as sql_text
,decode(instr(upper('&&4'), 'QUERY'), 0, 'Not Req.', trim(replace(replace(replace(sql_text ,chr(10)),chr(13)),chr(9)))) as sql_text
--,LISTAGG(distinct ash.instance_number||'#'||session_id||'#'||session_serial#, '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY 1 desc) as SID_LIST
,substr(LISTAGG(distinct nvl(ash.instance_number ,ash.instance_number)||'#'||nvl(session_id, session_id)||'#'||nvl(session_serial#, session_serial#), '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY 1 desc),1,200) as SID_LIST
,substr(LISTAGG(distinct nvl(qc_instance_id ,ash.instance_number)||'#'||nvl(qc_session_id, session_id)||'#'||nvl(qc_session_serial#, session_serial#), '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY 1 desc),1,200) as QC_SID_LIST
,substr(LISTAGG(distinct ash.blocking_inst_id||'#'||blocking_session||'#'||blocking_session_serial#, '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY 1 desc),1,200) as BLOKER_LIST
,substr(LISTAGG(distinct RawToHex(ash.xid), '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY 1 desc),1,200) as XID_LIST
,min(snap_id) as min_snap_id
,max(snap_id) as max_snap_id
  from --gv$active_session_history
      ash
       left join (select distinct sql_id, dbms_lob.substr(sql_fulltext,100) as sql_text from gv$sqlarea
                  union select sql_id, dbms_lob.substr(sql_text,100) as sql_text from dba_hist_sqltext) hs using(sql_id)--on NVL(ash.sql_id,ash.top_level_sql_id) = hs.sql_id--
       left join dba_procedures   p  on nvl(plsql_entry_object_id, plsql_object_id) = p.object_id
                                    and nvl(plsql_entry_subprogram_id, plsql_subprogram_id) = p.subprogram_id
       left join CDB_objects      o  on ash.current_obj# = o.object_id and data_object_id is not null
       left join gv$services      s  on name_hash = service_hash and ash.instance_number = s.inst_id
 start with &1
connect by nocycle (--ash.SAMPLE_ID       = prior ash.SAMPLE_ID or 
                    trunc(ash.sample_time) = trunc(prior ash.sample_time) and
                    abs(to_char(ash.sample_time,'SSSSS') - to_char(prior ash.sample_time,'SSSSS')) < 2)
                and ash.SESSION_ID      = prior ash.BLOCKING_SESSION
                and ash.SESSION_SERIAL# = prior ash.BLOCKING_SESSION_SERIAL#
--                and ash.instance_number         = prior ash.BLOCKING_INST_ID
 group by LEVEL,
          CONNECT_BY_ISCYCLE,
decode(instr(upper('&&4'), 'INST'), 0, '0', ash.instance_number),
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
          when REGEXP_INSTR(program, '\(W...\)')     > 0 then '(W...)'
          when REGEXP_INSTR(program, '\(DBW.\)')     > 0 then '(DBW.)'
          else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
        end,
--       case when module not like 'oracle%' then substr(module,1,9) else module end,
----          REGEXP_SUBSTR(client_id, '.+\#'),
--decode(instr(upper('&&4'), 'CLI'), 0, 'Not Req.', REGEXP_SUBSTR(client_id, '.+\#')),
decode(instr(upper('&&4'), 'CLI'), 0, 'Not Req.', case when client_id like '%#%' then REGEXP_SUBSTR(client_id, '.+\#') else client_id end),
decode(instr(upper('&&4'), 'MODULE'), 0, 'Not Req.', MODULE),
decode(instr(upper('&&4'), 'ACTION'), 0, 'Not Req.', ACTION),
nvl2(xid,' X ',''),
decode(instr(upper('&&4'), 'EVENT'), 0, 'Not Req.', decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue')),
--          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue'),
          wait_class,
--        case when p1text = 'handle address' or event = 'latch: row cache objects' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0'))
--             else o.owner||'.'||o.object_name||'.'||o.subobject_name end,
decode(instr(upper('&&4'), 'PARAM'), 0, 'Not Req.',
       case when ash.p1text = 'handle address' then upper(lpad(trim(to_char(ash.p1,'xxxxxxxxxxxxxxxx')),16,'0'))||';'||'p3='||ash.p3text||' 0x'||lpad(trim(to_char(ash.p3,'xxxxxxxxxxxxxxxx')),6,'0')
            when ash.event = 'latch free' then upper(lpad(trim(to_char(ash.p1,'xxxxxxxxxxxxxxxx')),16,'0'))--to_char(ash.p1)
            when ash.event = 'enq: UL - contention' then to_char(ash.p2)--(select NAME from dbms_lock_allocated where lockid = p2)
            when ash.event = 'enq: TM - contention' then chr(bitand(ash.p1,-16777216)/16777215)||chr(bitand(ash.p1, 16711680)/65535)||' '||bitand(ash.p1, 65535)
            when ash.event = 'row cache lock' then 'cache='||ash.p1||' held='||decode(ash.p2,0,'null',3,'share',5,'ex',10,'fail',ash.p2)||' req='||decode(ash.p3,0,'null',3,'share',5,'ex',10,'fail',ash.p3)
            when ash.event = 'row cache mutex' then ash.p1text||'='||ash.p1||' '||ash.p2text||'='||ash.p2
            when ash.event = 'enq: JI - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: MS - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: TQ - DDL contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: SQ - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'enq: HW - contention' then ash.p2text||' '||ash.p2
            when ash.event = 'DFS lock handle' then ash.p1||' '||ash.p2
            when ash.event = 'rdbms ipc reply' then ash.p1text||' '||ash.p1
       end),
--       o.owner||'.'||o.object_name||'.'||o.subobject_name,
decode(instr(upper('&&4'), 'OBJ'), 0, 'Not Req.', ash.current_obj#||' '||o.owner||'.'||o.object_name||'.'||o.subobject_name),
decode(instr(upper('&&4'), 'OBJ'), 0, 'Not Req.', decode(current_obj#,0,'0',-1,'-1','No')),
decode(instr(upper('&&4'), 'ROWID'), 0, 'Not Req.', DBMS_ROWID.ROWID_CREATE(1, ash.current_obj#, ash.current_file#, ash.current_block#, ash.current_row#)),
decode(instr(upper('&&4'), 'SERV'), 0, 'Not Req.', s.name),
--sql_adaptive_plan_resolved,
--sql_child_number,
--       o.owner||'.'||o.object_name||'.'||o.subobject_name,
--case when session_state='WAITING' and p1text='handle address' then upper(lpad(trim(to_char(p1,'xxxxxxxxxxxxxxxx')),16,'0')) end,
--       p1text, p1,
SQL_OPNAME,
In_hard_Parse,
In_Parse,
In_Sql_Execution,
in_connection_mgmt
--machine,
--program,
--module,
,decode(instr(upper('&&4'), 'CALL'), 0, 'Not Req.', top_level_call_name)
--       p2text, p2,
--          p3,
--          p.owner||'.'||p.object_name||'.'||p.procedure_name,
,blocking_session_status||' i#'||decode(instr(upper('&&4'), 'INST'), 0, '0', blocking_inst_id)
,decode(instr(upper('&&4'), 'PL/'), 0, 'Not Req.', p.owner||'.'||p.object_name||'.'||p.procedure_name)
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', sql_ID)
,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', top_level_sql_id)
,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_hash_value)
--,nvl2(sql_exec_id, 1, 0)
       ,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_line_ID)
       ,decode(instr(upper('&&4'), 'PLAN'), 0, 'Not Req.', sql_plan_operation||' '||sql_plan_options)
--          ,trim(replace(replace(replace(dbms_lob.substr(sql_text,200),chr(10)),chr(13)),chr(9)))
,decode(instr(upper('&&4'), 'QUERY'), 0, 'Not Req.', trim(replace(replace(replace(sql_text ,chr(10)),chr(13)),chr(9))))
 having count(distinct sample_id) > nvl('&2', 0)
 order by LEVEL, count(1) desc
/
set feedback on echo off VERIFY ON
