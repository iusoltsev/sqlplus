--
-- AWR sql period activity -> EBS concurrent action
-- Usage: SQL> @awr_sql2oebs_acty 123            456           5
--                                ^start_snap_id ^stop_snap_id ^topNsql
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col SQL_ID for a13
col ACTUAL_START_DATE  for a20
col ACTUAL_COMPLETION_DATE for a20
col ARGUMENT_TEXT for a200

with q as
--(select max(snap_id) as last_snap_id, max(BEGIN_INTERVAL_TIME) as BEGIN_INTERVAL_TIME from dba_hist_snapshot)
(select min(snap_id) as min_snap_id,
       max(snap_id) as max_snap_id,
       min(begin_interval_time) as BEGIN_INTERVAL_TIME,
       max(end_interval_time) as END_INTERVAL_TIME
  from dba_hist_snapshot
 where snap_id between &1 and &2)
, SNAP_INTERVAL as (select extract(second from SNAP_INTERVAL)+extract(minute from SNAP_INTERVAL)*60+extract(hour from SNAP_INTERVAL)*60*60 as SECS from DBA_HIST_WR_CONTROL)
, top10s as
       ((select 'ELAPSED' as top,
                 BEGIN_INTERVAL_TIME, END_INTERVAL_TIME,
                 min_snap_id, max_snap_id,
                 sql_id,
--                 plan_hash_value,
                 sum(executions_delta)                                                                            as sum_execs,
                 round(sum(ELAPSED_TIME_DELTA)/decode(sum(executions_delta),0,1,sum(executions_delta)))           as ev_per_exec,
--                 round(sum(ELAPSED_TIME_DELTA) / decode(avg(px_servers_execs_delta),0,1,avg(px_servers_execs_delta)) / decode(sum(executions_delta),0,1,sum(executions_delta)))           as elap_per_exec,
                 round(sum(ELAPSED_TIME_DELTA) / decode(avg(px_servers_execs_delta),0,1,avg(px_servers_execs_delta)) / decode(sum(executions_delta),0,1,sum(executions_delta)))           as elap_per_exec,
                 sum(ELAPSED_TIME_DELTA)                                                                          as sum_ev,
                 sum(ELAPSED_TIME_DELTA)                                                                          as sum_elap_time,
                 round((RATIO_TO_REPORT(sum(ELAPSED_TIME_DELTA)) OVER()) * 100, 2)                                AS Ev_Per_Cent
            from dba_hist_sqlstat
                 join q on snap_id between &1 and &2 and plan_hash_value > 0
           group by sql_id, min_snap_id, max_snap_id, BEGIN_INTERVAL_TIME, END_INTERVAL_TIME
           order by sum(ELAPSED_TIME_DELTA) desc nulls last
           fetch first &3 rows only)
   union
        (select 'READS' as top,
                 BEGIN_INTERVAL_TIME, END_INTERVAL_TIME,
                 min_snap_id, max_snap_id,
                 sql_id,
--                 plan_hash_value,
                 sum(executions_delta)                                                                            as sum_execs,
                 round(sum(PHYSICAL_READ_BYTES_DELTA)/decode(sum(executions_delta),0,1,sum(executions_delta)))    as ev_per_exec,
--                 round(sum(ELAPSED_TIME_DELTA) / decode(avg(px_servers_execs_delta),0,1,avg(px_servers_execs_delta)) / decode(sum(executions_delta),0,1,sum(executions_delta)))           as elap_per_exec,
                 round(sum(ELAPSED_TIME_DELTA) / decode(avg(px_servers_execs_delta),0,1,avg(px_servers_execs_delta)) / decode(sum(executions_delta),0,1,sum(executions_delta)))           as elap_per_exec,
                 sum(PHYSICAL_READ_BYTES_DELTA)                                                                   as sum_ev,
                 sum(ELAPSED_TIME_DELTA)                                                                          as sum_elap_time,
                 round((RATIO_TO_REPORT(sum(PHYSICAL_READ_BYTES_DELTA)) OVER()) * 100, 2)                         AS Ev_Per_Cent
            from dba_hist_sqlstat join q on snap_id between &1 and &2 and plan_hash_value > 0
           group by sql_id, min_snap_id, max_snap_id, BEGIN_INTERVAL_TIME, END_INTERVAL_TIME
           order by sum(PHYSICAL_READ_BYTES_DELTA) desc nulls last
           fetch first &3 rows only)
      union
        (select 'CPU' as top,
                 BEGIN_INTERVAL_TIME, END_INTERVAL_TIME,
                 min_snap_id, max_snap_id,
                 sql_id,
--                 plan_hash_value,
                 sum(executions_delta)                                                                            as sum_execs,
                 round(sum(CPU_TIME_DELTA)/decode(sum(executions_delta),0,1,sum(executions_delta)))               as ev_per_exec,
--                 round(sum(ELAPSED_TIME_DELTA) / decode(avg(px_servers_execs_delta),0,1,avg(px_servers_execs_delta)) / decode(sum(executions_delta),0,1,sum(executions_delta)))           as elap_per_exec,
                 round(sum(ELAPSED_TIME_DELTA) / decode(avg(px_servers_execs_delta),0,1,avg(px_servers_execs_delta)) / decode(sum(executions_delta),0,1,sum(executions_delta)))           as elap_per_exec,
                 sum(CPU_TIME_DELTA)                                                                              as sum_ev,
                 sum(ELAPSED_TIME_DELTA)                                                                          as sum_elap_time,
                 round((RATIO_TO_REPORT(sum(CPU_TIME_DELTA)) OVER()) * 100, 2)                                    AS Ev_Per_Cent
            from dba_hist_sqlstat join q on snap_id between &1 and &2 and plan_hash_value > 0
           group by sql_id, min_snap_id, max_snap_id, BEGIN_INTERVAL_TIME, END_INTERVAL_TIME
           order by sum(CPU_TIME_DELTA) desc nulls last
           fetch first &3 rows only)
)
-- select * from top10s
, top_sql as (SELECT /*+ materialize */ * FROM top10s PIVOT(avg(ev_per_cent) AS PER_CENT, avg(ev_per_exec) AS PER_EXEC, avg(sum_ev) AS SUM FOR (top) IN('ELAPSED' as ELA, 'READS' as READS, 'CPU' as CPU)))
--select * from top_sql
, ah as
(select--+ materialize
 sql_id,
 module,
 action,
 client_id,
 program,
 instance_number, session_id, session_serial#,
 min(sample_time) as min_sample_time, max(sample_time) as max_sample_time--, listagg(distinct sql_id, '; ')
, round(RATIO_TO_REPORT(count(*)) OVER(partition by sql_id)   * 100, 2) AS Percent_in_sql
 from dba_hist_active_sess_history ash
join top_sql using (sql_id)
 where snap_id between &1 and &2
--and sql_id in ('f1g74jt8n7shy')
and module not  in ('e:FND:cp:STANDART','e:FND:cp:STANDARD')
and module not like 'oracle@bi-db%'
group by instance_number, session_id, session_serial#, sql_id, module, action, client_id, program
)
--select * from a order by 11 desc
select--+ leading(q s) parallel(8)
--  distinct
  sql_id, ah.module, ah.action, s.request_id, s.parent_request_id
, sum_elap_time, sum_execs, ela_per_cent, cpu_per_cent, reads_per_cent
, sum(Percent_in_sql) as Pcent_inside_sql
, CONCURRENT_PROGRAM_ID, n.CONCURRENT_PROGRAM_NAME, p1.ARGUMENT_TEXT, p1.ACTUAL_START_DATE, p1.ACTUAL_COMPLETION_DATE
--select * 
from --system.fnd_concurrent_sessions--
(select distinct inst_id, sid, serial#, request_id, parent_request_id--, min(v_timestamp) over () as v_timestamp
 from system.fnd_concurrent_sessions s
 join q on s.v_timestamp between q.BEGIN_INTERVAL_TIME - 1 and q.END_INTERVAL_TIME + 1)
 s
-- join q on s.v_timestamp between q.BEGIN_INTERVAL_TIME - 1 and q.END_INTERVAL_TIME + 1
 join ah on 1=1
 join top_sql using (sql_id)
 join apps.fnd_concurrent_requests p1 on s.request_id = p1.request_id
 join (select distinct concurrent_program_id, CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl) n using (concurrent_program_id)
where (inst_id, sid, serial#) in ((instance_number, session_id, session_serial#))--select instance_number, session_id, session_serial# from a where rownum <= 1))
group by
  sql_id, ah.module, ah.action, s.request_id, s.parent_request_id
, sum_elap_time, sum_execs, ela_per_cent, cpu_per_cent, reads_per_cent
, CONCURRENT_PROGRAM_ID, n.CONCURRENT_PROGRAM_NAME, p1.ARGUMENT_TEXT, p1.ACTUAL_START_DATE, p1.ACTUAL_COMPLETION_DATE
order by sum_elap_time desc, sum(Percent_in_sql) desc
/
set feedback on echo off VERIFY ON