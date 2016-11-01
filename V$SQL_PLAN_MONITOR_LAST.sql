set echo off feed off
SET VERIFY OFF
select sql_plan_hash_value,
         plan_operation,
         plan_options,
         plan_object_name,
         plan_cardinality,
         output_rows
    from V$SQL_PLAN_MONITOR
   where sql_id = '&&1'
   and last_refresh_time = (select max(last_refresh_time) from V$SQL_PLAN_MONITOR where sql_id = '&&1');
set feed on SET VERIFY ON