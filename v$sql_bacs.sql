set echo off feedback off
set lines 500
col IS_BIND_SENSITIVE for a17
col IS_BIND_AWARE for a17
col IS_SHAREABLE  for a17
col first_load_time for a19
col last_load_time for a19
col last_active_time for a19
select inst_id,
       first_load_time,
       last_load_time,
       to_char(last_active_time, 'dd.mm.yyyy hh24:mi:ss') as last_active_time,
       child_number,
       optimizer_cost,
       plan_hash_value,
       OBJECT_STATUS,
       is_bind_sensitive,
       is_bind_aware,
       is_shareable,
       sql_plan_baseline,
       executions,
       round(ELAPSED_TIME / decode(executions,0,1,executions) / 1000000, 3) ELAPSED_per_exec,
       round(ROWS_PROCESSED / decode(executions,0,1,executions)) rows_per_exec
  from gv$sql
 where SQL_ID = '&&1'
-- and is_shareable = nvl('&&2', is_shareable)
/
set echo on feedback on