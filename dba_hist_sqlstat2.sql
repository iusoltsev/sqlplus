--
-- SQL execution extended analysis with rows_per_exec,... values from ASH, sqlstats
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
col min_snap_id for a20
col max_snap_id for a20
col SQL_OPNAME for a20

with ash as
( select --+ parallel(8) materialize
  instance_number as inst
, nvl(qc_session_id, session_id) as sid, nvl(qc_session_serial#, session_serial#) as serial#
, sql_id
, sql_opname
, listagg(distinct top_level_sql_id, ';') within group (order by top_level_sql_id nulls last) as top_level_sqls
, sql_plan_hash_value
, sql_full_plan_hash_value
, sql_exec_id
, listagg(distinct RAWTOHEX(xid), ';') within group (order by RAWTOHEX(xid) nulls last) as xids
, service_hash
, count(*) as ash_rows
, (cast(max(sample_time) as date)-cast(min(sample_time) as date)) as durn
, max(sample_time) - min(sample_time) as dur
, min(sample_time) as min_sample_time
, max(sample_time) as max_sample_time
, min(snap_id) as min_snap_id
, max(snap_id) as max_snap_id
, count(distinct session_id) as px
, max(temp_space_allocated)  as max_tmp_allocated
, max(pga_allocated)         as max_pga_allocated
  from dba_hist_active_sess_history
 where (snap_id between '&2' and nvl('&3', '&2'))
   and sql_id in ('&1')
   and sql_exec_id > 0
 group by instance_number, sql_id, sql_opname--, top_level_sql_id
, sql_plan_hash_value, sql_full_plan_hash_value, sql_exec_id, nvl(qc_session_id, session_id), nvl(qc_session_serial#, session_serial#), service_hash--, xid
 having --(cast(max(sample_time) as date)-cast(min(sample_time) as date)) < 1 and
        (cast(max(sample_time) as date)-cast(min(sample_time) as date)) >= 0
 order by 3)
select inst, sid, serial#, xids
, sql_id, sql_opname, top_level_sqls, sql_plan_hash_value, sql_full_plan_hash_value, sql_exec_id, service_hash, ash_rows
, round(durn*86400) as seconds
, max_sample_time-min_sample_time as duration
, min_sample_time
, max_sample_time
, min_snap_id
, max_snap_id
, px
,(select 'min/max/sum rows: '||
         min(round(st.rows_processed_delta / decode(st.executions_delta, 0, 1, st.executions_delta)))
         ||' / '||
         max(round(st.rows_processed_delta / decode(st.executions_delta, 0, 1, st.executions_delta)))
         ||' / '||
         round(sum(st.rows_processed_delta) / decode(sum(st.executions_delta), 0, 1, sum(st.executions_delta)))
         ||'; min/max/sum execs: '||
         min(round(st.executions_delta)) ||' / '|| max(round(st.executions_delta)) ||' / '|| sum(st.executions_delta)
  from dba_hist_sqlstat st
 where st.snap_id between min_snap_id and max_snap_id
   and st.instance_number = inst
   and st.sql_id in ('&1')
   and st.sql_id = ash.sql_id
   and st.plan_hash_value = ash.sql_plan_hash_value
   and st.snap_id between '&2' and nvl('&3', '&2')) as min_max_rows
, max_tmp_allocated as max_tmp_per_sid
, max_pga_allocated as max_pga_per_sid
from ash
order by --sql_plan_hash_value,
 min_sample_time
/
