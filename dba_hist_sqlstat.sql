--
-- short SQL execution history
-- SQL> @dba_hist_sqlstat "sql_id = '8d49sjc17xwuc' and snap_id between 86116 and 86260 and executions_delta > 0"
--
select 
    instance_number as inst,
    (snap_id - 1) as Begin_Snap_id,
    to_char(sn.begin_interval_time,'dd.mm hh24:mi') as begin_snap_time,
    round(st.executions_delta) as execs,
--    round(st.executions_delta * (st.rows_processed_delta/decode(st.executions_delta,0,1,st.executions_delta))) as rows_processed,
    st.rows_processed_delta as rows_processed,
    st.sql_id,
    st.plan_hash_value as plan,
    st.optimizer_cost as cost,
    round(st.parse_calls_delta/decode(st.executions_delta,0,1,st.executions_delta))                   as PARSE_PER_EXEC,
    round(st.elapsed_time_delta/decode(st.executions_delta,0,1,st.executions_delta))                    as ELA_PER_EXEC,
    round(st.cpu_time_delta/decode(st.executions_delta,0,1,st.executions_delta))                        as CPU_PER_EXEC,
    round(st.buffer_gets_delta/decode(st.executions_delta,0,1,st.executions_delta))                     as GETS_PER_EXEC,
    round(st.disk_reads_delta/decode(st.executions_delta,0,1,st.executions_delta))                      as disk_reads_per_exec,
    round(st.physical_read_bytes_delta/decode(st.executions_delta,0,1,st.executions_delta)/1024/1024)   as READ_MB_PER_EXEC,
    round(st.physical_read_requests_delta/decode(st.executions_delta,0,1,st.executions_delta))          as READS_PER_EXEC,
    round(st.physical_write_bytes_delta/decode(st.executions_delta,0,1,st.executions_delta)/1024/1024)  as WRITES_MB_PER_EXEC,
    round(st.physical_write_requests_delta/decode(st.executions_delta,0,1,st.executions_delta))         as WRITES_PER_EXEC,
    round(st.direct_writes_delta/decode(st.executions_delta,0,1,st.executions_delta))                   as DIRECT_WRITES_PER_EXEC,
    round(st.rows_processed_delta/decode(st.executions_delta,0,1,st.executions_delta))                  as ROWS_PER_EXEC,
    round(st.fetches_delta/decode(st.executions_delta,0,1,st.executions_delta))                         as FETCHES_PER_EXEC,
    round(st.iowait_delta/decode(st.executions_delta,0,1,st.executions_delta))                          as IOWAITS_PER_EXEC,
    round(st.clwait_delta/decode(st.executions_delta,0,1,st.executions_delta))                          as CLWAITS_PER_EXEC_uS,
    round(st.apwait_delta/decode(st.executions_delta,0,1,st.executions_delta))                          as APWAITS_PER_EXEC,
    round(st.ccwait_delta/decode(st.executions_delta,0,1,st.executions_delta))                          as CCWAITS_PER_EXEC,
    round(st.parse_calls_delta/decode(st.executions_delta,0,1,st.executions_delta))                     as PARSE_PER_EXEC,
    round(st.plsexec_time_delta/decode(st.executions_delta,0,1,st.executions_delta))                    as PLSQL_PER_EXEC,
    round(st.px_servers_execs_delta/decode(st.executions_delta,0,1,st.executions_delta))                as PX_PER_EXEC,
    round(st.clwait_delta/1000000) as clwaits_sec
from dba_hist_sqlstat st join dba_hist_snapshot sn using(snap_id,instance_number)
 where --sql_id = '
	&&1
--   and snap_id between &&2 and nvl('&&3', &&2)
--   and executions_delta > 0
order by snap_id, instance_number
/*
select to_char(sql_exec_start,'dd.mm.yyyy hh24:mi:ss')           as SQL_EXEC_START,
       max(sample_time) - SQL_EXEC_START                         as duration,
       sql_exec_id,
       sql_plan_hash_value,
       module,
       action,
       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb,
       max(px_used)                                             as max_px_used
  from (select sql_exec_start, sql_exec_id, sql_plan_hash_value, module, action, sample_id,
               sum(temp_space_allocated)           as temp_space_allocated,
               sum(pga_allocated)                  as pga_allocated,
               count(distinct session_serial#) - 1 as px_used,
               sample_time
          from dba_hist_active_sess_history
         where sql_id = '&&1'
           and snap_id between &2 and nvl('&&3', &&2)
           and sql_exec_id > 0
         group by sql_exec_start, sql_id, sql_exec_id, sql_plan_hash_value, module, action, sample_id, sample_time
          having sum(temp_space_allocated) is not null)
group by SQL_EXEC_START, sql_exec_id, sql_plan_hash_value, module, action
--having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
order by 1
*/
/