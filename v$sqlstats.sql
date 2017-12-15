set feedback off heading on timi off pages 200 lines 1000 echo off  VERIFY OFF
pro
pro --------------------------------------------------------------

pro SQL_ID=&&1 Shared Pool GV$SQLSTATS

pro --------------------------------------------------------------

select st.inst_id as "INST",
    st.executions as execs,
    st.sql_id,
    st.plan_hash_value as plan,
    round(st.elapsed_time/decode(st.executions,0,1,st.executions)) as ela_per_exec,
    round(st.cpu_time/decode(st.executions,0,1,st.executions)) as cpu_per_exec,
    round(st.buffer_gets/decode(st.executions,0,1,st.executions)) as gets_per_exec,
    round(st.concurrency_wait_time/decode(st.executions,0,1,st.executions)) as conc_per_exec,
    round(st.cluster_wait_time/decode(st.executions,0,1,st.executions)) as clu_per_exec,
    round(st.user_io_wait_time/decode(st.executions,0,1,st.executions)) as uio_per_exec,
    round(st.physical_read_bytes/decode(st.executions,0,1,st.executions)/1024/1024) as read_mb_per_exec,
    round(st.physical_read_requests/decode(st.executions,0,1,st.executions)) as reads_per_exec,
    round(st.disk_reads/decode(st.executions,0,1,st.executions)/1024/1024) as disk_reads_per_exec,
    round(st.physical_write_bytes/decode(st.executions,0,1,st.executions)/1024/1024) as writes_mb_per_exec,
    round(st.physical_write_requests/decode(st.executions,0,1,st.executions)) as writes_per_exec,
    round(st.direct_writes/decode(st.executions,0,1,st.executions)) as direct_writes_per_exec,
    round(st.rows_processed/decode(st.executions,0,1,st.executions)) as rows_per_exec,
    round(st.px_servers_executions/decode(st.executions,0,1,st.executions)) as px_per_exec
from gv$sqlstats st
where sql_id in ('&&1')
/

/*
select sql_exec_id, sql_plan_hash_value, module, action, CLIENT_ID,
       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb,
       max(px_used)                                             as max_px_used
  from (select sql_exec_id, sql_plan_hash_value, REGEXP_SUBSTR(client_id, '.+\#') as CLIENT_ID, module, action, sample_id,
               sum(temp_space_allocated)           as temp_space_allocated,
               sum(pga_allocated)                  as pga_allocated,
               count(distinct session_serial#) - 1 as px_used
          from gv$active_session_history
         where sql_id = '&&1'
           and sql_exec_id > 0
           and sql_plan_hash_value > 0
         group by sql_id, sql_exec_id, sql_plan_hash_value, module, action, sample_id, REGEXP_SUBSTR(client_id, '.+\#')
          having sum(temp_space_allocated) is not null)
group by sql_exec_id, sql_plan_hash_value, module, action, CLIENT_ID
--having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
order by 2

select round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb,
       count(distinct session_serial#) - 1                      as px_used
  from (select sum(temp_space_allocated) over(partition by sample_id) as temp_space_allocated,
               sum(pga_allocated)        over(partition by sample_id) as pga_allocated,
               session_serial#
          from gv$active_session_history
         where sql_id = '&&1')
*/

set feedback on VERIFY ON