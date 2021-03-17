--
-- SQL execution extended analysis with rows_per_exec,... values
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
, max_sample_time-min_sample_time as duration
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
order by sql_plan_hash_value
       , min_sample_time
/