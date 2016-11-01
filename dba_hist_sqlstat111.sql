select
      instance_number,
      snap_id,
      to_char(sn.begin_interval_time, 'dd.mm.yyyy hh24:mi')||' - '||to_char(sn.end_interval_time, 'dd.mm.yyyy hh24:mi') as "INTERVAL",
      sql_id,
      round(st.executions_delta) as EXECS_DELTA,
      st.plan_hash_value,
      st.optimizer_cost,
      st.sql_profile,
      st.optimizer_mode,
      st.loaded_versions,
      st.version_count,
      round(st.elapsed_time_delta/decode(st.executions_delta,0,1,st.executions_delta)) as ELA_PER_EXEC,
      round(st.cpu_time_delta/decode(st.executions_delta,0,1,st.executions_delta)) as CPU_PER_EXEC,
      round(st.buffer_gets_delta/decode(st.executions_delta,0,1,st.executions_delta)) as GETS_PER_EXEC,
      round(st.rows_processed_delta/decode(st.executions_delta,0,1,st.executions_delta)) as ROWS_PER_EXEC,
      round(st.iowait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as IOW_PER_EXEC,
      round(st.disk_reads_delta/decode(st.executions_delta,0,1,st.executions_delta)) as READS_PER_EXEC,
      round(st.direct_writes_delta/decode(st.executions_delta,0,1,st.executions_delta)) as DIR_WRITES_PER_EXEC,
      round(st.ccwait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as CC_PER_EXEC,
      round(st.fetches_delta/decode(st.executions_delta,0,1,st.executions_delta)) as FTCH_PER_EXEC,
      round(st.rows_processed_delta/decode(st.fetches_delta,0,1,st.fetches_delta)) as ROWS_PER_FTCH,
      round(st.px_servers_execs_delta/decode(st.executions_delta,0,1,st.executions_delta)) as PX_PER_EXEC
from dba_hist_sqlstat st join dba_hist_snapshot sn using (instance_number, snap_id)
where &1
order by snap_id, instance_number
/