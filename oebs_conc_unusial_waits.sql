--
-- EBS concurrent with unusial waits analysis
-- Usage: SQL> @oebs_conc_unusial_waits
-- 
--

set echo off feedback off heading on timi off pages 1000 lines 2000 VERIFY OFF

col CONCURRENT_PROGRAM_NAME for a100
col SQL_LIST                for a100
col PROGRAM_ID              for a10
col dt_start                for a20

select * from (
with s as
 (select --+ materialize
  distinct request_id, inst_id, sid, serial#, concurrent_program_id
    from system.fnd_concurrent_sessions
    join apps.fnd_concurrent_requests
   using (request_id)
   where concurrent_program_id in (select concurrent_program_id from system.ash_conc_prog_wait7) --142079
     and actual_start_date > sysdate - 6 / 24
     and v_timestamp > sysdate - 6 / 24)
--select * from s
--select * from gv$active_session_history a
--             join s on nvl(a.qc_instance_id, a.inst_id) = s.inst_id and nvl(a.qc_session_id, a.session_id) = s.sid and nvl(a.qc_session_serial#, a.session_serial#) = s.serial#
, ash0 as (select --+ materialize
                  a.inst_id,
                  sql_id,
                  nvl(a.event, a.session_state) as event,
                  a.sample_id,
                  a.sample_time
                 ,count(distinct request_id) over(partition by s.concurrent_program_id) as req_count
--                 ,count(count(distinct a.inst_id || '*' || a.sample_id)) over(partition by sql_id) as ash_sql_count
                 ,count(distinct a.inst_id || '*' || a.sample_id) over(partition by sql_id, nvl(a.event, a.session_state), s.concurrent_program_id) as ash_sql_wait_count
, s.concurrent_program_id
             from gv$active_session_history a
             join s on nvl(a.qc_instance_id, a.inst_id) = s.inst_id and nvl(a.qc_session_id, a.session_id) = s.sid and nvl(a.qc_session_serial#, a.session_serial#) = s.serial#
          )
--select * from ash0
--, last_log as (select distinct concurrent_program_id, max(log_date) over () as d from system.ash_conc_prog_wait7)
select a.concurrent_program_id,
       a.event,
       to_char(RATIO_TO_REPORT(count(distinct a.inst_id || '*' || a.sample_id)) OVER(partition by a.concurrent_program_id) * 100, '990.99') as actual_pct,
       RATIO_TO_REPORT(count(distinct a.inst_id || '*' || a.sample_id)) OVER(partition by a.concurrent_program_id) as actual_pct_,
       e.wait_pct as average_pct
, req_count
, sum(count(distinct a.inst_id || '*' || a.sample_id)) OVER(partition by a.event, a.concurrent_program_id) as ash_rows
, min(min(sample_time)) OVER(partition by a.event, a.concurrent_program_id)                                as min_sample_time
, max(max(sample_time)) OVER(partition by a.event, a.concurrent_program_id)                                as max_sample_time
, substr(listagg(distinct sql_id||'('||ash_sql_wait_count||')','; ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY ash_sql_wait_count desc),1,100) as sql_list --OVER(partition by a.concurrent_program_id) as sql_profile
  from ash0 a
  left join (select distinct concurrent_program_id, max(log_date) over () as d from system.ash_conc_prog_wait7) l
    on l.concurrent_program_id = a.concurrent_program_id--142079
  left join system.ash_conc_prog_wait7
          e on e.event = a.event
           and (e.concurrent_program_id, e.log_date) in ((l.concurrent_program_id, l.d))
 group by a.event, req_count, e.wait_pct, a.concurrent_program_id
order by
 a.concurrent_program_id
, RATIO_TO_REPORT(count(distinct a.inst_id || '*' || a.sample_id)) OVER(partition by a.concurrent_program_id) desc
)
 where actual_pct_ > 2/100
   and (actual_pct_ / average_pct > 1.25)
   and ash_rows > 10
/
set feedback on echo off VERIFY ON
