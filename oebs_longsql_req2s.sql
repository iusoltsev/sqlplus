--
-- Top long sql and EBS concurrent analysis from DBA_HIST_ASH (Summary)
-- Usage: SQL> @oebs_longsql_req2s 53024          55994          %XXHR%
--                                 ^start_snap_id ^stop_snap_id  ^USER_CONCURRENT_PROGRAM_NAME like condition
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
col PHV_HIST                                for a200
col "CONCURRENT_PROGRAM_NAME|MODULE:ACTION" for a200
col REQUESTS_LIST                           for a200
col "CONCURRENT_ID:PROGRAM_NAME"            for a200
col "MODULE:ACTION:PROGRAM"                 for a200
col mini_snap_time for a20
col maxi_snap_time for a20

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

/*
select  min(snap_id) as deep_snap_id, to_char(min(begin_interval_time),'dd.mm.yy hh24:mi') as deep_snap_time
        from dba_hist_snapshot
       where begin_interval_time >= trunc(to_date('&v_min_snap_time','dd.mm.yy hh24:mi') - nvl('&3',10))--add_months(sysdate, - 1)
         and dbid = sys_context ('userenv','DBID')
order by begin_interval_time
*/

select
  &v_min_snap_id                                 as mini_snap_id
, &v_max_snap_id                                 as maxi_snap_id
--, &v_deep_snap_id as deepi_snap_id
, to_date('&v_min_snap_time','dd.mm.yy hh24:mi') as mini_snap_time
, to_date('&v_max_snap_time','dd.mm.yy hh24:mi') as maxi_snap_time
--, to_date('&v_deep_snap_time','dd.mm.yy hh24:mi') as deepi_snap_time
 from dual
/

with ash as (select --+ parallel(8) INLINE
             * from dba_hist_active_sess_history a
             where snap_id between &v_min_snap_id and &v_max_snap_id)
--             where snap_id between 53024 and 55994)
,long_q_sql as (select -- 
                   instance_number, session_id, session_serial#
                 , top_level_sql_id, sql_id, sql_plan_hash_value
                 , sql_exec_id, sql_exec_start
                 , least(cast(min(sample_time) as date), sql_exec_start) as min_sample_time
                 , cast(max(sample_time) as date)                        as max_sample_time
                 , count(*)
                 , min(snap_id)                                          as min_snap_id
                 , max(snap_id)                                          as max_snap_id
                    from ash a
                  where sql_plan_hash_value > 0
                    and sql_exec_id > 0
                    and sql_id not in ('32wwktufvq9zf')--strange EDO UPDATE
                    and module <> 'DBMS_SCHEDULER'
                    and module not like 'emagent%'
                    and module not like 'java@oebsapi-wto%'
                    and action not like 'apps.xxya_oebsapi_pkg.bot_dispatcher%'
                    group by instance_number, session_id, session_serial#
                             , top_level_sql_id, sql_id, sql_plan_hash_value
                             , sql_exec_id, sql_exec_start
                having (cast(max(sample_time) as date) - least(cast(min(sample_time) as date), sql_exec_start))*86400 >= 7200
                and count(*) >= 10--? strange sql_id='32wwktufvq9zf' 01d0w1bphwhxa
               )
--select * from long_q_sql where sql_id = '3fmbs5958cpdp' and top_level_sql_id = 'ggp7pncbz8r6g'
,long_q as (
   select--+ parallel(8) materialize
   distinct
      instance_number, session_id, session_serial#
    , top_level_sql_id, sql_id, sql_plan_hash_value
    , sql_exec_id, sql_exec_start
    , module, action, program
    , decode(session_state,'WAITING',event,session_state) as EVENT
    , wait_class
--    , xid--not always const4query duration, 4u23tfcqqn2p3
    , min_snap_id
    , min_sample_time
    , max_snap_id
    , max_sample_time
    , round((max_sample_time-min_sample_time)*86400) as duration_sec
    , count(distinct instance_number||a.sample_id) over (partition by --instance_number,
                                                         top_level_sql_id, sql_id--, sql_plan_hash_value, sql_exec_id, sql_exec_start, decode(session_state,'WAITING',event,session_state), wait_class
                                                         )
     as ash_event_rows
    , count(distinct instance_number||a.sample_id) over (partition by instance_number, session_id, session_serial#, top_level_sql_id, sql_id, sql_plan_hash_value, sql_exec_id, sql_exec_start)
     as ash_sql_exec_rows
-------------, concurrent_program_id, n.USER_CONCURRENT_PROGRAM_NAME
-------------, s.request_id, r.status_code, r.actual_start_date, r.actual_completion_date
    from ash a
    join long_q_sql l using( instance_number, session_id, session_serial#
                           , top_level_sql_id, sql_id, sql_plan_hash_value, sql_exec_id, sql_exec_start)
/*
left join (select distinct request_id, inst_id, sid, serial# from system.FND_CONCURRENT_SESSIONS) s on instance_number=inst_id and session_id=sid and session_serial#=serial#
left join (select distinct request_id
                         , concurrent_program_id
                         , argument_text
                         , status_code
                         , actual_completion_date
                         , actual_start_date from APPLSYS.FND_CONCURRENT_REQUESTS) r on r.request_id = s.request_id
      and l.min_sample_time between r.actual_start_date and r.actual_completion_date
      and l.max_sample_time between r.actual_start_date and r.actual_completion_date
left join (select distinct concurrent_program_id, USER_CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl) n using(concurrent_program_id)
*/
)
--select * from long_q where sql_id = '3fmbs5958cpdp' and top_level_sql_id = 'ggp7pncbz8r6g'
--select sql_id, count(distinct sql_exec_id), count(distinct sql_plan_hash_value) from long_q group by sql_id order by count(distinct sql_plan_hash_value) desc
select --distinct
      q.top_level_sql_id, q.sql_id
    , LISTAGG (distinct q.sql_plan_hash_value||'('||q.duration_sec||')', '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY duration_sec desc) as PHV_LIST
    , min(q.duration_sec)             as min_duration_sec
    , round(avg(q.duration_sec))      as avg_duration_sec
    , max(q.duration_sec)             as min_duration_sec
    , COUNT(DISTINCT s.request_id)  AS requests
    , COUNT(DISTINCT q.sql_exec_id) as sql_execs
-----    , substr(LISTAGG(distinct nvl2(concurrent_program_id, concurrent_program_id||':'||n.USER_CONCURRENT_PROGRAM_NAME, NVL2(q.module || q.action, q.module||':'||q.action, q.program)), '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY q.duration_sec desc),1,200) as "CONCURRENT_PROGRAM_NAME|MODULE:ACTION"
    , substr(LISTAGG(distinct concurrent_program_id||':::'||n.USER_CONCURRENT_PROGRAM_NAME, '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY q.duration_sec desc),1,200)    as "PROGRAM_ID:PROGRAM_NAME"
    , substr(LISTAGG(distinct NVL2(q.module || q.action, q.module||':::'||q.action, q.program), '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY q.duration_sec desc),1,200) as "MODULE:ACTION:PROGRAM"
    , substr(LISTAGG (distinct s.request_id||':'||r.status_code||'('||round((r.actual_completion_date - r.actual_start_date)*86400)||'s'||')', '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY q.duration_sec desc),1,200) as REQUESTS_LIST
---    , r.argument_text
    , substr(LISTAGG (distinct q.EVENT || '('|| q.ash_event_rows||')', '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY q.ash_event_rows desc),1,200) as WAIT_PROFILE
---    , min(min_snap_id)
---    , min(min_sample_time)
---    , max(max_snap_id)
---    , max(max_sample_time)
 from long_q q
left join (select distinct request_id, inst_id, sid, serial# from system.FND_CONCURRENT_SESSIONS) s on q.instance_number=inst_id and q.session_id=sid and q.session_serial#=serial#
left join (select distinct request_id
                         , concurrent_program_id
                         , argument_text
                         , status_code
                         , actual_completion_date
                         , actual_start_date from APPLSYS.FND_CONCURRENT_REQUESTS) r on r.request_id = s.request_id
-------      and q.min_sample_time between r.actual_start_date and r.actual_completion_date
-------      and q.max_sample_time between r.actual_start_date and r.actual_completion_date
      and r.actual_start_date      <= q.max_sample_time
      and r.actual_completion_date >= q.min_sample_time
left join (select distinct concurrent_program_id, USER_CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl) n using(concurrent_program_id)
--------left join (select distinct sql_id, sql_phv_hist from hist_long_stats) h on q.sql_id = h.sql_id
/*
where upper(nvl(n.USER_CONCURRENT_PROGRAM_NAME,' ')) like upper('%'||'&&3'||'%')
   or upper(nvl(q.module ,' ')) like upper('%'||'&&3'||'%')
   or upper(nvl(q.action ,' ')) like upper('%'||'&&3'||'%')
*/
where nvl(n.USER_CONCURRENT_PROGRAM_NAME,' ') like '%'||'&&3'||'%'
   or nvl(q.module ,' ')                      like '%'||'&&3'||'%'
   or nvl(q.action ,' ')                      like '%'||'&&3'||'%'
group by q.top_level_sql_id, q.sql_id
order by avg(q.duration_sec) desc
/
set feedback on echo off VERIFY ON
