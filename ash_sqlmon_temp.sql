--
-- SQL Plan Statistics for SQL_EXEC_ID from ASH
-- Usage: SQL> @ash_sqlmon &sql_id [&plan_hash_value] [&sql_exec_id]
--

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

col PLAN_OPERATION for a180
col WAIT_PROFILE for a200

with ash as
 (select sql_id,
         sql_plan_hash_value,
         nvl(sql_plan_line_id, 0) as SQL_PLAN_LINE_ID,
         decode(session_state,'WAITING',event,session_state) as EVENT,
         count(*) as WAIT_COUNT,
         max(sample_time) as MAX_SAMPLE_TIME
, count(distinct session_id) as SID_COUNT
    from ash_201408071200
   where sql_id = '&1'
     and sql_plan_hash_value = nvl('&2', sql_plan_hash_value)
     and NVL(sql_exec_id, 0) = nvl('&3', NVL(sql_exec_id, 0))
   group by sql_id, sql_plan_hash_value, nvl(sql_plan_line_id, 0), decode(session_state,'WAITING',event,session_state)),
ash_stat as
(select sql_id,
        sql_plan_hash_value,
        sql_plan_line_id,
        rtrim(xmlagg(xmlelement(s, EVENT || '(' ||WAIT_COUNT, '); ').extract('//text()') order by WAIT_COUNT desc),',') as WAIT_PROFILE,
        max(SID_COUNT)-1 as PX_COUNT,
        max(MAX_SAMPLE_TIME) as MAX_SAMPLE_TIME
from ash where sql_plan_hash_value > 0
group by sql_id,
         sql_plan_hash_value,
         sql_plan_line_id),
pt as
 (select
        id,
        operation,
        options,
        object_owner,
        object_name,
        qblock_name,
        parent_id
    from dba_hist_sql_plan
   where (sql_id, plan_hash_value) =
         (select distinct sql_id, sql_plan_hash_value from ash_stat where sql_plan_hash_value > 0)
  union -- for plans not in dba_hist_sql_plan yet
  select
        id,
        operation,
        options,
        object_owner,
        object_name,
        qblock_name,
        parent_id
    from v$sql_plan
   where (sql_id, plan_hash_value) =
         (select distinct sql_id, sql_plan_hash_value from ash_stat where sql_plan_hash_value > 0))
SELECT case when ash_stat.MAX_SAMPLE_TIME > sysdate - 10/86400 then '>>>'
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 30/86400 then '>> '
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 60/86400 then '>  '
            else '   ' end as NOW,
       pt.id,
       lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as PLAN_OPERATION,
       pt.object_owner,
       pt.object_name,
       pt.qblock_name,
       ash_stat.PX_COUNT as PX,
       ash_stat.WAIT_PROFILE
  FROM pt
  left join ash_stat
    on pt.id = ash_stat.sql_plan_line_id
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0
ORDER BY ID
/
set feedback on VERIFY ON timi on