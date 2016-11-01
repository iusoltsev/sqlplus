--
-- Session lock tree from ASH
-- Usage: SQL> @ash_lock3 "20130519 20:15:27" "20130519 20:15:28"
-- http://iusoltsev.wordpress.com
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col LVL for a3
col BLOCKING_TREE for a20
col SQL_TEXT for a100
col EVENT for a34
col Lock_Mode for a12
col BLOCKER for a12
col OBJECT_NAME for a40
col SQL_PLAN_OPERATION for a50

with ash as (select * from ash_20130519--v$active_session_history
             where sample_time between to_date('&1','yyyymmdd hh24:mi:ss')
                                   and to_date('&2','yyyymmdd hh24:mi:ss'))
select to_char(LEVEL) as LVL,
       LPAD(' ',(LEVEL-1)*2)||session_id||','||session_serial# as BLOCKING_TREE,
       to_char(min(sample_time),'hh24:mi:ss') as START_WTIME,
       to_char(max(sample_time),'hh24:mi:ss') as STOP_WTIME,
       xid,
--sql_exec_id,
       decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue') as EVENT,
       decode(event, 'enq: TM - contention', chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535)||' '||bitand(p1, 65535), '') as "Lock_Mode",
       blocking_session||','||blocking_session_serial# as BLOCKER,
       o.object_type || ' ' || o.object_name as OBJECT_NAME,
       count(distinct sample_id) as WAITS_COUNT,
       sql_plan_operation||' '||sql_plan_options as SQL_PLAN_OPERATION,
       trim(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(9))) as sql_text
  from ash
       left join dba_hist_sqltext hs on ash.sql_id = hs.sql_id
       left join dba_objects o on decode(event, 'enq: TM - contention', ash.p2, ash.current_obj#) = o.object_id
 where session_state = 'WAITING'
       start with BLOCKING_SESSION is not null and session_serial# > 1
             and event not like 'log file sync'
connect by nocycle ash.SAMPLE_ID  = prior ash.SAMPLE_ID
               and ash.SESSION_ID = prior ash.BLOCKING_SESSION
 group by LEVEL,
          LPAD(' ',(LEVEL-1)*2)||session_id||','||session_serial#,
          xid,
--sql_exec_id,
          decode(session_state, 'WAITING', EVENT, 'On CPU / runqueue'),
          decode(event, 'enq: TM - contention', chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535)||' '||bitand(p1, 65535), ''),
          blocking_session||','||blocking_session_serial#,
          o.object_type || ' ' || o.object_name,
          hs.sql_id,
          sql_plan_operation||' '||sql_plan_options,
          trim(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(9)))
 order by LEVEL, trim(LPAD(' ',(LEVEL-1)*2)||session_id||','||session_serial#), min(sample_time)
/
set feedback on echo off VERIFY ON