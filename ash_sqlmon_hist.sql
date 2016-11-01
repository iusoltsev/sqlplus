--
-- Real SQL Plan Execution Statistics by SQL_EXEC_ID, FROM_SNAP_ID from DBA_HIST_ACTIVE_SESS_HISTORY
-- Usage: SQL> @ash_sqlmon_hist &sql_id [&plan_hash_value] [&sql_exec_id] [&from_snap_id] [&to_snap_id]
-- http://iusoltsev.wordpress.com
--

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

col PLAN_OPERATION for a100
col WAIT_PROFILE for a200

with ash as
 (select sql_id,
         sql_plan_hash_value,
         nvl(sql_plan_line_id, 0) as SQL_PLAN_LINE_ID,
         decode(session_state,'WAITING',event,session_state) as EVENT,
         count(*) as WAIT_COUNT
, count(distinct session_id) as SID_COUNT
    from dba_hist_active_sess_history
   where sql_id = '&1'
     and sql_plan_hash_value = nvl('&2', sql_plan_hash_value)
     and NVL(sql_exec_id, 0) = nvl('&3', NVL(sql_exec_id, 0))
     and ((snap_id between nvl('&4', snap_id) and nvl('&5', snap_id))
           or 
          (snap_id >= nvl('&4', snap_id) and '&5' is null))
   group by sql_id, sql_plan_hash_value, sql_plan_line_id, decode(session_state,'WAITING',event,session_state)),
ash_stat as
(select  sql_id,
        sql_plan_hash_value,
        sql_plan_line_id,
        max(SID_COUNT)-1 as PX_COUNT,
        rtrim(xmlagg(xmlelement(s, EVENT || '(' ||WAIT_COUNT, '); ').extract('//text()') order by WAIT_COUNT desc),',') as WAIT_PROFILE
from ash
group by sql_id,
         sql_plan_hash_value,
         sql_plan_line_id),
pt as
 (select *
    from dba_hist_sql_plan
   where (sql_id, plan_hash_value) =
         (select distinct sql_id, sql_plan_hash_value from ash_stat))
SELECT pt.id,
       lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as PLAN_OPERATION,
       pt.object_owner,
       pt.object_name,
       pt.cost,
       pt.cardinality,
       pt.bytes,
       pt.qblock_name,
       pt.temp_space,
       ash_stat.PX_COUNT as PX,
       ash_stat.WAIT_PROFILE
  FROM pt
  left join ash_stat
    on pt.id = ash_stat.sql_plan_line_id
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0
order by pt.id
/
set feedback on VERIFY ON timi on