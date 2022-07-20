--
-- Top long sql and EBS concurrent analysis from DBA_HIST_ASH
-- Usage: SQL> @oebs_longsql_req2 [11110]        [11119]       [30]                           [ELA|APP|UIO|CPU]
--                                 ^start_snap_id ^stop_snap_id ^Deep_dive4PHV period, in days ^order by
--

set echo off feedback off heading on timi on pages 1000 lines 2000 VERIFY OFF

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
col WAIT_PROFILE for a200
col PARENT_REQUEST_ID for 99999999999
col PARENT_ID         for 99999999999
col SID for 999999
col SERIAL for 99999999
col actual_start_date for a20
col actual_completion_date for a20
col SQL_PHV_HIST for a400

undefine v_deep_snap_id v_min_snap_id v_max_snap_id v_min_snap_time v_max_snap_time v_deep_snap_time 
DEFINE v_deep_snap_id = 0
DEFINE v_min_snap_id  = 0
DEFINE v_max_snap_id  = 0
DEFINE v_min_snap_time = ''
DEFINE v_max_snap_time = ''
DEFINE v_deep_snap_time = ''

col deep_snap_id   new_value v_deep_snap_id   noprint
col deep_snap_time new_value v_deep_snap_time noprint
col min_snap_id    new_value v_min_snap_id    noprint
col max_snap_id    new_value v_max_snap_id    noprint
col min_snap_time  new_value v_min_snap_time  noprint
col max_snap_time  new_value v_max_snap_time  noprint

select  nvl('&1',min(snap_id))                               as min_snap_id
      , nvl('&2',max(snap_id))                               as max_snap_id
      , to_char(min(begin_interval_time),'dd.mm.yy hh24:mi') as min_snap_time
      , to_char(max(begin_interval_time),'dd.mm.yy hh24:mi') as max_snap_time
        from dba_hist_snapshot
       where --begin_interval_time >= sysdate - 1 and end_interval_time   <= sysdate -- default
         snap_id between &1 and &2
         and dbid = sys_context ('userenv','DBID')
group by DBID
/

select  min(snap_id) as deep_snap_id, to_char(min(begin_interval_time),'dd.mm.yy hh24:mi') as deep_snap_time
        from dba_hist_snapshot
       where begin_interval_time >= trunc(to_date('&v_min_snap_time','dd.mm.yy hh24:mi') - nvl('&3',10))--add_months(sysdate, - 1)
         and dbid = sys_context ('userenv','DBID')
order by begin_interval_time
/

select
  &v_min_snap_id as mini_snap_id
, &v_max_snap_id as maxi_snap_id
, &v_deep_snap_id as deepi_snap_id
, to_date('&v_min_snap_time','dd.mm.yy hh24:mi') as mini_snap_time
, to_date('&v_max_snap_time','dd.mm.yy hh24:mi') as maxi_snap_time
, to_date('&v_deep_snap_time','dd.mm.yy hh24:mi') as deepi_snap_time
 from dual
/

with ash as (select --+ parallel(8) INLINE
             * from dba_hist_active_sess_history a
             where snap_id between &v_min_snap_id and &v_max_snap_id)
,long_q as (
   select--+ parallel(8) materialize
      instance_number, session_id, session_serial#
--    , sql_opname
    , top_level_sql_id, a.sql_id, sql_plan_hash_value
    , sql_exec_id, sql_exec_start
    , module, action
    , decode(session_state,'WAITING',event,session_state) as EVENT
--    , xid--not always const4query duration, 4u23tfcqqn2p3
    , min(snap_id)     as min_snap_id
    , min(sample_time) as min_sample_time
    , max(snap_id)     as max_snap_id
    , max(sample_time) as max_sample_time
    , least(cast(min(sample_time) as date), sql_exec_start)   as exec_start
    , count(distinct a.instance_number||a.sample_id) as ash_rows
--, sum(count(*)) over (partition by instance_number, session_id, session_serial#, sql_opname, top_level_sql_id, a.sql_id, sql_plan_hash_value, sql_exec_id, sql_exec_start, module, action) as ash_rows4class
, sum(case when wait_class    = 'Application' then 1 else 0 end) as waits4app
, sum(case when wait_class    = 'User I/O'    then 1 else 0 end) as waits4io
, sum(case when session_state = 'ON CPU'      then 1 else 0 end) as waits4cpu
    , max(sample_time) - min(sample_time) as duration
    , (cast(max(sample_time) as date)-cast(min(sample_time) as date))*86400 as duration_secs
    , (cast(max(sample_time) as date)-least(cast(min(sample_time) as date), sql_exec_start) )*86400 as duration_secs2
--, trim(replace(replace(replace(dbms_lob.substr(sql_text,200),chr(10)),chr(13)),chr(9)))
----, listagg(distinct wait_class) 
--     from dba_hist_active_sess_history a where snap_id between &v_min_snap_id and &v_max_snap_id
    from ash a
  where sql_plan_hash_value > 0
    and sql_exec_id > 0
    and a.sql_id not in ('32wwktufvq9zf')--strange EDO UPDATE
    and module <> 'DBMS_SCHEDULER'
    and module not like 'emagent%'
    and module not like 'java@oebsapi-wto%'
    and action not like 'apps.xxya_oebsapi_pkg.bot_dispatcher%'
    group by instance_number, session_id, session_serial#--, sql_opname
           , top_level_sql_id, a.sql_id, sql_plan_hash_value, sql_exec_id, sql_exec_start
--, trim(replace(replace(replace(dbms_lob.substr(sql_text,200),chr(10)),chr(13)),chr(9)))
    , module, action
    , decode(session_state,'WAITING',event,session_state)
    having (cast(max(sample_time) as date)-least(cast(min(sample_time) as date), sql_exec_start))*86400 > 7200
       and count(*) >= 10--? strange sql_id='32wwktufvq9zf' 01d0w1bphwhxa
-------order by (cast(max(sample_time) as date)-least(cast(min(sample_time) as date), sql_exec_start)) desc
)
--, a_stat
--select * from long_q
, hist_long_q as (
   select--+ parallel(8) INLINE --materialize
--  instance_number, session_id, session_serial#,
      top_level_sql_id, sql_id, sql_plan_hash_value, sql_exec_id, sql_exec_start--, module, action
    , least(cast(min(sample_time) as date), sql_exec_start) as min_sample_time
    , cast(max(sample_time) as date)                        as max_sample_time
, sum(case when wait_class    = 'Application' then 1 else 0 end) as waits4app
, sum(case when wait_class    = 'User I/O'    then 1 else 0 end) as waits4io
, sum(case when session_state = 'ON CPU'      then 1 else 0 end) as waits4cpu
    , count(*) as ash_rows
    , count(distinct session_id) as sess_cows
    , round((cast(max(sample_time) as date)-least(cast(min(sample_time) as date), sql_exec_start) )*86400) as duration_secs
--    , max(sample_time) - min(sample_time) as duration
--    , (cast(max(sample_time) as date)-cast(min(sample_time) as date))*86400 as duration_secs
--, (select trim(replace(replace(replace(dbms_lob.substr(sql_text,200),chr(10)),chr(13)),chr(9))) from dba_hist_sqltext where sql_id = a.sql_id) as sql_text
     from dba_hist_active_sess_history a --top_level_sql_id = '02apq7ft0d5h0'--sql_id = '5vcrg87mfn3tg'--
--left join dba_hist_sqltext using(sql_id)
     where snap_id between &v_deep_snap_id and &v_min_snap_id - 1
    and sql_plan_hash_value > 0
    and sql_exec_id > 0
and (--top_level_sql_id,
     sql_id) in (select distinct --top_level_sql_id,
     sql_id from long_q --where waits4App < ash_rows/2
     )
    group by
-- instance_number, session_id, session_serial#,
 top_level_sql_id, sql_id, sql_plan_hash_value, sql_exec_id, sql_exec_start
order by sql_id, (cast(max(sample_time) as date)-least(cast(min(sample_time) as date), sql_exec_start)) desc
)
, hist_long_stats as (
select
  sql_id,
  sql_plan_hash_value as phv,
  count(sql_exec_id)  as execs,
  min(duration_secs)  as min_dur,
  max(duration_secs)  as max_dur,
  min(sess_cows)      as min_px,
  max(sess_cows)      as max_px
, min(round(100*waits4app/ash_rows)) as apps_pc_min
, max(round(100*waits4app/ash_rows)) as apps_pc_max
, min(round(100*waits4io /ash_rows)) as uio_pc_min
, max(round(100*waits4io /ash_rows)) as uio_pc_max
, min(round(100*waits4cpu/ash_rows)) as cpu_pc_min
, max(round(100*waits4cpu/ash_rows)) as cpu_pc_max
, substr(LISTAGG (sql_id||'_'||sql_plan_hash_value||' Execs:'||count(sql_exec_id)||' Secs:'||min(duration_secs)||'-'||max(duration_secs)||' Px:'||min(sess_cows)||'-'||max(sess_cows) , '; ' ON OVERFLOW TRUNCATE '..') WITHIN GROUP (ORDER BY max(duration_secs)) over (partition by sql_id), 1, 400) as sql_phv_hist
 from hist_long_q
 group by sql_id, sql_plan_hash_value)
--select * from hist_long_stats
--substr(LISTAGG (sql_id||'_'||phv||' Execs:'||execs||' Secs:'||min_dur||'/'||max_dur||' Px:'||min_px||'/'||max_px , '; ' ON OVERFLOW TRUNCATE '..') WITHIN GROUP (ORDER BY max_dur), 1, 400) as sql_phv_hist
select --distinct
--session data
      q.instance_number as inst, q.session_id as sid, q.session_serial# as serial#
--sql data
    , q.top_level_sql_id, q.sql_id, q.sql_plan_hash_value, q.sql_exec_id
--    , q.xid
    , q.module, q.action
    , min(min_snap_id) as min_snap_id
    , max(max_snap_id) as max_snap_id
    , min(q.min_sample_time) as min_sample_time
    , max(q.max_sample_time) as max_sample_time
    , sum(q.ash_rows)  as ash_rows
    , sum(q.waits4app) as apps_rows
    , sum(q.waits4io)  as uio_rows
    , sum(q.waits4cpu) as cpu_rows
    , round(100*sum(q.waits4app)/sum(q.ash_rows)) as apps_pc
    , round(100*sum(q.waits4io) /sum(q.ash_rows)) as uio_pc
    , round(100*sum(q.waits4cpu)/sum(q.ash_rows)) as cpu_pc
--    , sum(q.duration) as duration
--    , sum(q.duration_secs) as duration_secs
    , (cast(max(q.max_sample_time) as date)-cast(min(q.min_sample_time) as date))*86400 as ash_duration_secs
    , (cast(max(q.max_sample_time) as date)-least(cast(min(q.min_sample_time) as date), q.exec_start))*86400 as sql_duration_secs2
    , s.request_id
    , n.USER_CONCURRENT_PROGRAM_NAME
    , r.argument_text
    , r.status_code
    , round((r.actual_completion_date - r.actual_start_date)*86400) as REQUEST_DUR_SEC
    , r.actual_start_date
    , r.actual_completion_date
    , h.sql_phv_hist
    , substr(LISTAGG (distinct q.EVENT || '('||q.ash_rows||')', '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY q.ash_rows desc),1,200) as WAIT_PROFILE
 from long_q q
left join (select distinct request_id, inst_id, sid, serial# from system.FND_CONCURRENT_SESSIONS) s on q.instance_number=inst_id and q.session_id=sid and q.session_serial#=serial#
left join (select distinct request_id
                         , concurrent_program_id
                         , argument_text
                         , status_code
                         , actual_completion_date
                         , actual_start_date from APPLSYS.FND_CONCURRENT_REQUESTS) r on r.request_id = s.request_id
      and q.min_sample_time between r.actual_start_date and r.actual_completion_date
      and q.max_sample_time between r.actual_start_date and r.actual_completion_date
left join (select distinct concurrent_program_id, USER_CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl) n using(concurrent_program_id)
left join (select distinct sql_id, sql_phv_hist from hist_long_stats) h on q.sql_id = h.sql_id
group by 
      q.instance_number, q.session_id, q.session_serial#
--sql data
    , q.top_level_sql_id, q.sql_id, q.sql_plan_hash_value, q.sql_exec_id
--    , q.xid
    , q.module, q.action
    , s.request_id
    , n.USER_CONCURRENT_PROGRAM_NAME
    , r.argument_text
    , r.status_code
    , round((r.actual_completion_date - r.actual_start_date)*86400)
    , r.actual_start_date
    , r.actual_completion_date
    , h.sql_phv_hist
    , q.exec_start
order by decode(upper(nvl('&4','Ela')), 'ELA', (cast(max(q.max_sample_time) as date)-least(cast(min(q.min_sample_time) as date), q.exec_start))
, 'APP', sum(q.waits4app)
, 'UIO', sum(q.waits4io)
, 'CPU', sum(q.waits4cpu)
, (cast(max(q.max_sample_time) as date)-least(cast(min(q.min_sample_time) as date), q.exec_start)))
 desc
/
set feedback on echo off VERIFY ON
