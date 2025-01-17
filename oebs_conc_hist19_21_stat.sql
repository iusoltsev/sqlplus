--
-- EBS concurrent analysis from DBA_HIST_ASH
-- Usage: SQL> @oebs_conc_hist19_21_stat "91911537,3332222111"
--                                       ^Request_id
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
col PLSQL for a70
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
col REQUESTED_START_DATE for a20
col actual_completion_date for a20
col MIN_SAMPLE_TIME        for a26
col MAX_SAMPLE_TIME        for a26
col "ROOT_id(program_id)"  for a30
col COMPLETION_TEXT for a200

DEFINE v_DBID        = 0
DEFINE v_min_snap_id = 0
DEFINE v_max_snap_id = 0
DEFINE v_child_reqs  = 0
DEFINE v_sum_ash_rows  = 0

col DBID          new_value v_DBID         noprint
col min_snap_id   new_value v_min_snap_id  noprint
col max_snap_id   new_value v_max_snap_id  noprint
col child_reqs    new_value v_child_reqs   noprint
col sum_ash_rows  new_value v_sum_ash_rows noprint

select
(select request_id||'('||concurrent_program_id||')'
 from apps.fnd_concurrent_requests
 where CONNECT_BY_ISLEAF = 1
  start with request_id = q.request_id
 connect by nocycle prior parent_request_id = request_id and RESUBMIT_INTERVAL is null) as "ROOT_id(program_id)",
       parent_request_id,
       request_id,
       concurrent_program_id,
       REQUESTED_START_DATE,
       actual_start_date,
       actual_completion_date,
       STATUS_CODE,
       PHASE_CODE
     ,(select distinct CONCURRENT_PROGRAM_NAME||'|'||USER_CONCURRENT_PROGRAM_NAME||'--'||EXECUTABLE_NAME||'|'||USER_EXECUTABLE_NAME
         from apps.fnd_concurrent_programs_vl p left join apps.fnd_executables_vl e on p.EXECUTABLE_APPLICATION_ID=e.APPLICATION_ID and p.EXECUTABLE_ID=e.EXECUTABLE_ID
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
, trim(replace(replace(replace(substr(COMPLETION_TEXT,1,200),chr(10),CHR(32)),chr(13),CHR(32)),chr(9),CHR(32))) as COMPLETION_TEXT
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
, q as (
select  distinct
        max(s.ROOT_request_id) over(partition by s.ROOT_request_id) as ROOT_request_id
      , min(sample_time) over(partition by s.ROOT_request_id) as min_sample_time
      , max(sample_time) over(partition by s.ROOT_request_id) as max_sample_time
      , min(snap_id)     over(partition by s.ROOT_request_id) as min_snap_id
      , max(snap_id)     over(partition by s.ROOT_request_id) as max_snap_id
--      , trim(to_char(RATIO_TO_REPORT(count(distinct a.instance_number||a.sample_id)) OVER() * 100, '990.99')||'%') AS DBTime_percent
--      , count(distinct a.instance_number||a.sample_id) OVER() AS DBTime_rows2
      , sum(pga_allocated)        over (partition by s.ROOT_request_id, instance_number, sample_id) as max_pga_allocated
      , sum(temp_space_allocated) over (partition by s.ROOT_request_id, instance_number, sample_id) as max_temp_allocated
        from AWR_CDB_ACTIVE_SESS_HISTORY a
        join sids s on ((a.instance_number, a.session_id, a.session_serial#) in ((s.inst_id, s.sid, s.serial#))
                        or (qc_instance_id, qc_session_id, qc_session_serial#) in ((s.inst_id, s.sid, s.serial#)))
         and a.SAMPLE_TIME between min_timestamp and max_timestamp
----        left join dba_procedures   dp on OBJECT_ID = PLSQL_ENTRY_OBJECT_ID and SUBPROGRAM_ID = PLSQL_ENTRY_SUBPROGRAM_ID
----        left join dba_hist_sqltext t  on t.sql_id  = a.sql_id
----        left join dba_hist_sqltext t2 on t2.sql_id = a.top_level_sql_id
----left join apps.fnd_concurrent_requests b1 on b1.request_id = s.ROOT_request_id
----left join apps.fnd_concurrent_requests b2 on b2.request_id = s.parent_request_id
----left join CDB_objects      o  on a.current_obj# = o.object_id and a.con_id = o.con_id
----left join dba_services     s  on a.service_hash = name_hash
      where snap_id between &v_min_snap_id and &v_max_snap_id and a.dbid = &v_DBID)
----group by s.ROOT_request_id
----order by 6 desc)
select ROOT_request_id,
       min_sample_time,
       max_sample_time,
       min_snap_id,
       max_snap_id,
       max(max_pga_allocated) as max_pga_allocated,
       max(max_temp_allocated) as max_temp_allocated
  from q
 group by ROOT_request_id,
          min_sample_time,
          max_sample_time,
          min_snap_id,
          max_snap_id
 order by 6 desc
/
set feedback on echo off VERIFY ON
