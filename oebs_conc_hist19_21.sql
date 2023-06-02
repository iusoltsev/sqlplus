--
-- EBS concurrent analysis from DBA_HIST_ASH
-- Usage: SQL> @oebs_conc_hist19_21 "91911537,3332222111"    [SQL]|TOP|REQ|SID|MOD|"PL/"|INST|OBJ [10]
--                                 ^Request_id               ^FieldSelector                       ^topN_sql ^order by Duration desc, otherwise - by Activity desc
--

set echo off feedback off heading on timi off pages 1000 lines 2000 VERIFY OFF

col INST for 9999
col BLOCK_INST for 9999999999
col LVL for 999
col BLOCKING_TREE for a30
col EVENT for a64
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col SQL_ID for a13
col SQL_OPNAME for a20
col PLSQL for a60
col CLIENT_ID for a30
col SQL_TEXT for a200
col TOP_SQL_TEXT for a200
col argument_text for a250
col WAIT_PROFILE for a200
col PARENT_REQUEST_ID for 99999999999
col PARENT_ID         for 99999999999
col SID for 999999
col SERIAL for 99999999
col actual_start_date for a20
col actual_completion_date for a20
col MIN_SAMPLE_TIME        for a26
col MAX_SAMPLE_TIME        for a26

DEFINE v_DBID        = 0
DEFINE v_min_snap_id = 0
DEFINE v_max_snap_id = 0
DEFINE v_child_reqs  = 0

col DBID          new_value v_DBID         noprint
col min_snap_id   new_value v_min_snap_id  noprint
col max_snap_id   new_value v_max_snap_id  noprint
col child_reqs    new_value v_child_reqs   noprint
col sum_ash_rows  new_value v_sum_ash_rows noprint

select parent_request_id, request_id,
       concurrent_program_id,
       actual_start_date,
       actual_completion_date,
       STATUS_CODE,
       PHASE_CODE
      ,(select distinct CONCURRENT_PROGRAM_NAME||'|'||USER_CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl
         where concurrent_program_id = q.concurrent_program_id and rownum <= 1) as CONCURRENT_PROGRAM_NAME
, (select b.user_concurrent_queue_name
    from apps.fnd_concurrent_processes a,
         apps.fnd_concurrent_queues_vl b,
         apps.fnd_concurrent_requests  c
   where a.concurrent_queue_id = b.concurrent_queue_id
     and a.concurrent_process_id = c.controlling_manager
     and c.request_id = q.request_id) as cm_name
, RESPONSIBILITY_APPLICATION_ID
, RESPONSIBILITY_ID
, argument_text
  from apps.fnd_concurrent_requests q
 where request_id in (&1)
/
with sids as
      (select /*+ materialize */
       distinct module,
       CONNECT_BY_ROOT request_id as ROOT_request_id,
       request_id,
       parent_request_id,
       inst_id,
       sid,
       serial#,
       min(v_timestamp) over () as min_timestamp
       , case when STATUS_CODE='R' then sysdate
              when STATUS_CODE in ('C','X','E','G') then actual_completion_date
              else max(v_timestamp) over () end as max_timestamp
       from system.fnd_concurrent_sessions join apps.fnd_concurrent_requests b using (request_id,parent_request_id)
       start with request_id in  (&1)
        connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null
and b.RESUBMIT_END_DATE is null-- 149210904 ???
        and module not like 'oratop@%')
, minmax_timestamp as (select min(min_timestamp) as mmin_timestamp
                            , max(max_timestamp) as mmax_timestamp
                            , count(distinct request_id) as child_reqs
--                            , round( sum(cast(max_timestamp as date)-cast(min_timestamp as date)) * 86400 / 10) as sum_ash_rows
                            , round( abs(cast(max(max_timestamp) as date)-cast(min(min_timestamp) as date)) * 86400 / 10) as sum_ash_rows
                       from sids)
--select * from minmax_timestamp
select-- monitor
        DBID--, con_id
      , min(snap_id) as min_snap_id
      , max(snap_id) as max_snap_id
      , child_reqs
      , sum_ash_rows
, mmin_timestamp, mmax_timestamp
from (select DBID, snap_id, begin_interval_time, end_interval_time, child_reqs, sum_ash_rows, mmin_timestamp, mmax_timestamp
        from dba_hist_snapshot, minmax_timestamp
       where (mmin_timestamp between begin_interval_time and end_interval_time
              OR mmax_timestamp between begin_interval_time and end_interval_time
              OR mmax_timestamp > end_interval_time and end_interval_time = (select max(end_interval_time) from dba_hist_snapshot)
              )
              and dbid = sys_context ('userenv','DBID')
--added for non-exist snapshot
union all
(select DBID, max(snap_id) as snap_id, max(begin_interval_time) as begin_interval_time, max(end_interval_time) as end_interval_time, child_reqs, sum_ash_rows, mmin_timestamp, mmax_timestamp
  from dba_hist_snapshot, minmax_timestamp
 where not exists (select 1 from dba_hist_snapshot where mmin_timestamp between begin_interval_time and end_interval_time)
   and mmin_timestamp > end_interval_time
   and dbid = sys_context ('userenv','DBID')
 group by DBID, child_reqs, sum_ash_rows, mmin_timestamp, mmax_timestamp)
union all
(select DBID, min(snap_id) as snap_id, min(begin_interval_time) as begin_interval_time, min(end_interval_time) as end_interval_time, child_reqs, sum_ash_rows, mmin_timestamp, mmax_timestamp
  from dba_hist_snapshot, minmax_timestamp
 where not exists (select 1 from dba_hist_snapshot where mmax_timestamp between begin_interval_time and end_interval_time)
   and mmax_timestamp < begin_interval_time
   and dbid = sys_context ('userenv','DBID')
 group by DBID, child_reqs, sum_ash_rows, mmin_timestamp, mmax_timestamp)
--added for non-exist snapshot
         )
group by DBID, child_reqs, sum_ash_rows--, con_id
, mmin_timestamp, mmax_timestamp
/
select &v_DBID as DBID, &v_min_snap_id as min_snap_id, &v_max_snap_id as max_snap_id, &v_child_reqs  as child_conc_reqs, &v_sum_ash_rows as sum_ash_rows from dual
/
select &v_DBID        , &v_min_snap_id               , &v_max_snap_id               , &v_child_reqs                    , &v_sum_ash_rows from dual
/
with sids as
      (select /*+ materialize */
       distinct module,
       CONNECT_BY_ROOT request_id as ROOT_request_id,
       request_id,
       b.CONCURRENT_PROGRAM_ID,
       parent_request_id,
       inst_id,
       sid,
       serial#,
       min(v_timestamp) over () as min_timestamp
       , case when STATUS_CODE='R' then sysdate
              when STATUS_CODE='W' then sysdate
              when STATUS_CODE in ('C','X','E','G') then nvl(actual_completion_date, sysdate)
              else max(v_timestamp) over () end as max_timestamp
       from system.fnd_concurrent_sessions join apps.fnd_concurrent_requests b using (request_id,parent_request_id)
       start with request_id in  (&1)
        connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null
        and module not like 'oratop@%'
union                  -- for action = 'XXYA_TLOG_TAXI_GRP_PKG'...
select distinct module,
       0 as ROOT_request_id,
       0 as request_id,
       0 as CONCURRENT_PROGRAM_ID,
       0 as parent_request_id,
       instance_number as inst_id,
       session_id as sid,
       session_serial# as serial#,
       min(sample_time) over () as min_timestamp,
       max(sample_time) over () as max_timestamp
from AWR_CDB_ACTIVE_SESS_HISTORY
      where snap_id between &v_min_snap_id and &v_max_snap_id and dbid = &v_DBID
and module = 'REQID='||'&1')
--select * from sids
--select count(distinct s.inst_id||' '||s.sid||' '||s.serial#), count(distinct s.request_id) from sids s
/*
, snaps as (select --+ materialize
                   DBID, con_id, min(snap_id) as min_snap_id, max(snap_id) as max_snap_id from dba_hist_snapshot, sids
                   where (min_timestamp between begin_interval_time and end_interval_time
                          OR max_timestamp between begin_interval_time and end_interval_time
                          OR max_timestamp > end_interval_time and end_interval_time = (select max(end_interval_time) from dba_hist_snapshot) )
            group by DBID, con_id)
*/
, a as
      (select--+ materialize --cardinality(a 1e6) OPTIMIZER_FEATURES_ENABLE('12.1.0.2') use_concat--
  decode(instr(upper('&2'), 'REQ'), 0, 'na', s.ROOT_request_id)           as ROOT_request_id
      , decode(instr(upper('&2'), 'REQ'), 0, 'na', s.parent_request_id)    as parent_request_id
      , decode(instr(upper('&2'), 'REQ'), 0, 'na', s.request_id)           as request_id
, decode(instr(upper('&2'), 'REQ'), 0, 'na', b1.CONCURRENT_PROGRAM_ID)           as root_PROGRAM_ID
, decode(instr(upper('&2'), 'REQ'), 0, 'na', b2.CONCURRENT_PROGRAM_ID)           as parent_PROGRAM_ID
, decode(instr(upper('&2'), 'REQ'), 0, 'na', s.CONCURRENT_PROGRAM_ID)            as CONCURRENT_PROGRAM_ID
      , decode(instr(upper('&2'), 'INST'), 0, 'na', inst_id)      as inst
      , decode(instr(upper('&2'), 'SID'), 0, 'na', sid)                  as sid
      , decode(instr(upper('&2'), 'SID'), 0, 'na', serial#)              as serial
      , decode(instr(upper('&2'), 'TOP'), 0, 'na', top_level_sql_id)     as top_level_sql_id
      , decode(instr(upper('&2'), 'SQL'), 0, 'na', a.sql_id)               as sql_id
      , decode(instr(upper('&2'), 'SQL'), 0, 'na', sql_plan_hash_value)  as sql_plan_hash_value
      , decode(instr(upper('&2'), 'SQL'), 0, 'na', replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' '))  as SQL_TEXT
      , decode(instr(upper('&2'), 'TOP'), 0, 'na', replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ')) as TOP_SQL_TEXT
      , decode(instr(upper('&2'), 'PL/'), 0, 'na', dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME)  as PLSQL
      , sql_exec_id----, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
      , decode(instr(upper('&2'), 'MOD'), 0, 'na', a.module)     as module
      , decode(instr(upper('&2'), 'MOD'), 0, 'na', action)     as action
      , decode(instr(upper('&2'), 'MOD'), 0, 'na', client_id)  as client_id
      --, xid
, decode(instr(upper('&2'), 'OBJ'), 0, 'na', a.current_obj#||':'||o.owner||'.'||o.object_name||'.'||o.subobject_name) as DATA_OBJECT
      , decode(session_state,'WAITING',event,session_state) as EVENT
      , count(distinct a.instance_number||a.sample_id) as ash_row
      , sum(count(distinct a.instance_number||a.sample_id)) over (partition by decode(instr(upper('&2'), 'REQ'), 0, 'na', s.parent_request_id)
                                                                             , decode(instr(upper('&2'), 'REQ'), 0, 'na', s.request_id)
                                                                             , decode(instr(upper('&2'), 'INST'), 0, 'na', inst_id)
                                                                             , decode(instr(upper('&2'), 'SID'), 0, 'na', sid)
                                                                             , decode(instr(upper('&2'), 'SID'), 0, 'na', serial#)
                                                                             , decode(instr(upper('&2'), 'TOP'), 0, 'na', top_level_sql_id)
                                                                             , decode(instr(upper('&2'), 'SQL'), 0, 'na', a.sql_id)
                                                                             , decode(instr(upper('&2'), 'SQL'), 0, 'na', sql_plan_hash_value)
                                                                             --, decode(instr(upper('&2'), 'SQL'), 0, 'na', replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' '))  as SQL_TEXT
                                                                             --, decode(instr(upper('&2'), 'SQL'), 0, 'na', replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ')) as TOP_SQL_TEXT
                                                                             --, decode(instr(upper('&2'), 'SQL'), 0, 'na', dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME)  as PLSQL
                                                                             , decode(instr(upper('&2'), 'MOD'), 0, 'na', a.module)
                                                                             , decode(instr(upper('&2'), 'MOD'), 0, 'na', action)
                                                                             , decode(instr(upper('&2'), 'MOD'), 0, 'na', client_id)
                                                                             , decode(instr(upper('&2'), 'OBJ'), 0, 'na', a.current_obj#||':'||o.owner||'.'||o.object_name||'.'||o.subobject_name)
                                                                             , decode(session_state,'WAITING',event,session_state)) as ash_row4event
      , min(sample_time) as min_sample_time
      , max(sample_time) as max_sample_time
      , min(snap_id) as min_snap_id
      , max(snap_id) as max_snap_id
--      , trim(to_char(RATIO_TO_REPORT(count(distinct a.instance_number||a.sample_id)) OVER() * 100, '990.99')||'%') AS DBTime_percent
--      , count(distinct a.instance_number||a.sample_id) OVER() AS DBTime_rows2
, a.instance_number, a.session_id, a.session_serial#, s.request_id as req
----      , count(distinct inst_id||' '||sid||' '||serial#) as sids_sids
----      , count(distinct s.request_id)                          as sids_reqs
        from AWR_CDB_ACTIVE_SESS_HISTORY a
        join sids s on ((a.instance_number, a.session_id, a.session_serial#) in ((s.inst_id, s.sid, s.serial#)) or (qc_instance_id, qc_session_id, qc_session_serial#) in ((s.inst_id, s.sid, s.serial#)))
         and a.SAMPLE_TIME between min_timestamp and max_timestamp
        left join dba_procedures   dp on OBJECT_ID = PLSQL_ENTRY_OBJECT_ID and SUBPROGRAM_ID = PLSQL_ENTRY_SUBPROGRAM_ID
        left join dba_hist_sqltext t  on t.sql_id  = a.sql_id
        left join dba_hist_sqltext t2 on t2.sql_id = a.top_level_sql_id
left join apps.fnd_concurrent_requests b1 on b1.request_id = s.ROOT_request_id
left join apps.fnd_concurrent_requests b2 on b2.request_id = s.parent_request_id
left join CDB_objects      o  on a.current_obj# = o.object_id and a.con_id = o.con_id
      where snap_id between &v_min_snap_id and &v_max_snap_id and a.dbid = &v_DBID
-----and a.sql_id = '8f3mzav4b845t'
      group by
--      , request_id, parent_request_id
--      , instance_number, sid, serial#
--      , top_level_sql_id, a.sql_id, sql_plan_hash_value
--      , dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME
--      , a.module, action, client_id
  decode(instr(upper('&2'), 'REQ'), 0, 'na', s.ROOT_request_id)
      , decode(instr(upper('&2'), 'REQ'), 0, 'na', s.parent_request_id)
      , decode(instr(upper('&2'), 'REQ'), 0, 'na', s.request_id)
, decode(instr(upper('&2'), 'REQ'), 0, 'na', b1.CONCURRENT_PROGRAM_ID)
, decode(instr(upper('&2'), 'REQ'), 0, 'na', b2.CONCURRENT_PROGRAM_ID)
, decode(instr(upper('&2'), 'REQ'), 0, 'na', s.CONCURRENT_PROGRAM_ID)
      , decode(instr(upper('&2'), 'INST'), 0, 'na', inst_id)
      , decode(instr(upper('&2'), 'SID'), 0, 'na', sid)
      , decode(instr(upper('&2'), 'SID'), 0, 'na', serial#)
      , decode(instr(upper('&2'), 'TOP'), 0, 'na', top_level_sql_id)
      , decode(instr(upper('&2'), 'SQL'), 0, 'na', a.sql_id)
      , decode(instr(upper('&2'), 'SQL'), 0, 'na', sql_plan_hash_value)
      , decode(instr(upper('&2'), 'SQL'), 0, 'na', replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' '))
      , decode(instr(upper('&2'), 'TOP'), 0, 'na', replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' '))
      , decode(instr(upper('&2'), 'PL/'), 0, 'na', dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME)
      , sql_exec_id----, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
      , decode(instr(upper('&2'), 'MOD'), 0, 'na', a.module)
      , decode(instr(upper('&2'), 'MOD'), 0, 'na', action)
      , decode(instr(upper('&2'), 'MOD'), 0, 'na', client_id)
, decode(instr(upper('&2'), 'OBJ'), 0, 'na', a.current_obj#||':'||o.owner||'.'||o.object_name||'.'||o.subobject_name)
      --, xid
      , decode(session_state,'WAITING',event,session_state)
, a.instance_number, a.session_id, a.session_serial#, s.request_id
      order by count(distinct a.instance_number||a.sample_id) desc)
--select * from a
--SELECT * FROM (
select /*+ monitor parallel(4)*/-- cardinality(a 1e6) OPTIMIZER_FEATURES_ENABLE('12.1.0.2') use_concat
    ROOT_request_id
  , parent_request_id, request_id
, root_PROGRAM_ID, parent_PROGRAM_ID, CONCURRENT_PROGRAM_ID as PROGRAM_ID
  , inst, sid, serial
  , top_level_sql_id, a.sql_id, sql_plan_hash_value
  --, sql_exec_id----, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
  , PLSQL
  , module, action, client_id
  --, xid
  , DATA_OBJECT
  , count(distinct sql_exec_id)                                                             as execs
  , count(distinct instance_number||' '||session_id||' '||session_serial#)                  as sids
----  , sids_sids                                                                                   as sids
----  , sids_reqs                                                                                   as requests
  , count(distinct req)                                                                     as reqs
  , sum(ash_row)                                                                            as ash_rows
  , round(sum(ash_row)/decode(count(distinct sql_exec_id),0,1,count(distinct sql_exec_id))) as per_execs
  , max(max_sample_time)-min(min_sample_time)                                               as rough_duration
  , round(((max(max_sample_time)+0)-(min(min_sample_time)+0))*86400)                        as rough_dur_secs
  , min(min_sample_time)                                                                    as min_sample_time
  , max(max_sample_time)                                                                    as max_sample_time
--, min(min_sample_time) over()                                                                   as min_sample_time_
--, max(max_sample_time) over()                                                                   as max_sample_time_
  , to_char(RATIO_TO_REPORT(sum(ash_row)) OVER() * 100, '990.99')                           AS "DBTime%"
  , substr(LISTAGG (distinct EVENT || '('||ash_row4event||')', '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY ash_row4event desc),1,200) as WAIT_PROFILE
  --, rtrim(xmlagg(xmlelement(s, EVENT || '(' || ash_row4event, '); ').extract('//text()') order by ash_row4event desc), '; ') as WAIT_PROFILE
  --, rtrim(xmlagg(xmlelement(s, EVENT || '(' || sum(ash_row), '); ').extract('//text()') order by sum(ash_row) desc), '; ') as WAIT_PROFILE
  --90207458, rtrim(xmlagg(xmlelement(s, EVENT || '(' || DBTime_percent, '); ').extract('//text()') order by ash_rows desc), '; ') as WAIT_PROFILE2
  , SQL_TEXT
  , TOP_SQL_TEXT
  , min(min_snap_id)                                                                        as mmin_snap_id
  , max(max_snap_id)                                                                        as mmax_snap_id
    from a
  group by
    ROOT_request_id
  , request_id, parent_request_id
, root_PROGRAM_ID, parent_PROGRAM_ID, CONCURRENT_PROGRAM_ID
  , inst, sid, serial
  , top_level_sql_id, a.sql_id, sql_plan_hash_value
  --, sql_exec_id----, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
  , PLSQL
  , a.module, action, client_id
  , DATA_OBJECT
  --, xid
  , SQL_TEXT
  , TOP_SQL_TEXT
  --, EVENT
----  , sids_sids
----  , sids_reqs
  order by sum(ash_row) desc--decode(upper('&4'), 'D'
                            -- , 24      --rough_dur_secs
                            -- , 21) desc--sum(ash_row)
----) where rownum <= nvl('&3', 10)
fetch first nvl('&3', 10) rows only
/
/*
UNION ALL
select
    'Summary' as ROOT_request_id
  , null,null--parent_request_id, request_id
, null,null,null--root_PROGRAM_ID, parent_PROGRAM_ID, CONCURRENT_PROGRAM_ID
  , null,null,null--inst, sid, serial
  , null,null,null--top_level_sql_id, a.sql_id, sql_plan_hash_value
  , null as PLSQL
  , null,null,null--module, action, client_id
  , count(distinct sql_exec_id)                                                             as execs
  , count(distinct instance_number||' '||session_id||' '||session_serial#)                  as sids
  , count(distinct req)                                                                     as reqs
  , sum(ash_row)                                                                            as ash_rows
  , null as per_execs
  , max(max_sample_time)-min(min_sample_time)                                               as rough_duration
  , min(min_sample_time)                                                                    as min_sample_time
  , max(max_sample_time)                                                                    as max_sample_time
  , to_char(RATIO_TO_REPORT(sum(ash_row)) OVER() * 100, '990.99')                           AS "DBTime%"
  , substr(LISTAGG (distinct EVENT || '('||ash_row4event||')', '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY ash_row4event desc),1,200) as WAIT_PROFILE
  , null
  , null
  , min(min_snap_id)                                                                        as mmin_snap_id
  , max(max_snap_id)                                                                        as mmax_snap_id
    from a
) ORDER BY ASH_ROWS DESC
FETCH FIRST NVL('&3', 10) ROWS ONLY
*/
set feedback on echo off VERIFY ON
