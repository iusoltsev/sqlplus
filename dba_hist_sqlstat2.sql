--
-- short SQL execution history
-- SQL> @dba_hist_sqlstat2 "6585ka4kkk8fs" 13703          14400
--                         ^sql_id        ^start_snap_id ^stop_snap_id
--
col ELA_PER_EXEC for 999,999,999,999
col CPU_PER_EXEC for 999,999,999,999
col GETS_PER_EXEC for 999,999,999,999
col IOWAITS_PER_EXEC for 999,999,999,999
col CLWAITS_PER_EXEC_uS for 999,999,999,999
col APWAITS_PER_EXEC for 999,999,999,999
col CCWAITS_PER_EXEC for 999,999,999,999


select 
    instance_number as inst,
    (snap_id - 1) as Begin_Snap_id,
    to_char(sn.begin_interval_time,'dd.mm hh24:mi') as begin_snap_time,
    round(st.executions_delta) as execs,
--    round(st.executions_delta * (st.rows_processed_delta/decode(st.executions_delta,0,1,st.executions_delta))) as rows_processed,
    st.rows_processed_delta as rows_processed,
    st.sql_id,
    st.plan_hash_value as plan,
    st.SQL_PROFILE,
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
 where sql_id = '&1'
   and snap_id between '&2' and nvl('&3', '&2')
--   and executions_delta > 0
and (st.elapsed_time_delta > 0 and st.executions_delta is not null)
order by snap_id, instance_number
/
with ash as
( select --+ parallel(4) materialize
  instance_number as inst
, sql_id
, sql_plan_hash_value
, sql_exec_id
, count(*) as ash_rows
, (cast(max(sample_time) as date)-cast(min(sample_time) as date)) as durn
, max(sample_time) - min(sample_time) as dur
, min(sample_time) as min_sample_time
, max(sample_time) as max_sample_time
, min(snap_id) as min_snap_id
, max(snap_id) as max_snap_id
, count(distinct session_id) as px
  from dba_hist_active_sess_history
 where (snap_id between '&2' and nvl('&3', '&2'))
   and sql_id = '&1'
   and sql_exec_id > 0
 group by instance_number, sql_id, sql_plan_hash_value, sql_exec_id
 having (cast(max(sample_time) as date)-cast(min(sample_time) as date)) < 1 and (cast(max(sample_time) as date)-cast(min(sample_time) as date)) > 0
 order by 3)
select inst, sql_id, sql_plan_hash_value, sql_exec_id, ash_rows
, round(durn*86400) as seconds
, min_sample_time
, max_sample_time
, min_snap_id
, max_snap_id
, px
,(select min(round(st.rows_processed_delta / decode(st.executions_delta, 0, 1, st.executions_delta)))
         ||' / '||
         max(round(st.rows_processed_delta / decode(st.executions_delta, 0, 1, st.executions_delta)))
  from dba_hist_sqlstat st
 where st.snap_id between min_snap_id and max_snap_id
   and st.instance_number = inst
   and st.sql_id = '&1'
   and st.plan_hash_value = sql_plan_hash_value
   and st.snap_id between '&2' and nvl('&3', '&2')) as min_max_rows
from ash
order by 3
/