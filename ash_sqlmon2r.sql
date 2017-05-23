--
-- SQL Plan Statistics from ASH (including recursive queries and PL/SQL)
-- Usage: SQL> @ash_sqlmon2 &sql_id [&plan_hash_value] [&sql_exec_id] "where sample_time > trunc(sysdate,'hh24')"
-- 

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

undefine &1
undefine &2
undefine &3
undefine &4

col PLAN_OPERATION for a170
col WAIT_PROFILE for a200
col LAST_PLSQL for a45
col ID for 9999
col OBJECT_OWNER for a12
col OBJECT_NAME for a30
col QBLOCK_NAME for a15

with
 ash0 as (select * from Gv$active_session_history &4),
 sid_time as -- List of sessions and their start/stop times
 (select nvl(qc_session_id, session_id) as qc_session_id,
         session_id,
         session_serial#,
         sql_id,
         min(sample_time)            as MIN_SQL_EXEC_TIME,
         max(sample_time)            as MAX_SQL_EXEC_TIME
    from ash0
   where sql_id = '&&1'
     and NVL(sql_plan_hash_value, 0) = nvl('&&2', NVL(sql_plan_hash_value, 0))
     and NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0))
   group by nvl(qc_session_id, session_id), session_id, session_serial#, sql_id, sql_plan_hash_value, sql_exec_id)
, ash1 as (select sample_time,
                 session_id,
                 session_serial#,
                 sql_id,
                 sql_exec_id,
                 sql_plan_hash_value,
                 sql_plan_line_id,
                 session_state,
                 event,
                 sum(temp_space_allocated) over (partition by sample_id) as temp_space_allocated, -- summary
                 sum(pga_allocated)        over (partition by sample_id) as pga_allocated        -- --//--
            from ash0
           where sql_id              = '&&1'                                -- direct SQL exec ONLY
             and sql_plan_hash_value = nvl('&&2', sql_plan_hash_value)
             and NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0)))
, ash as (                               -- ASH part, consisting of direct SQL exec ONLy
  select count(distinct sh.session_id||','||sh.session_serial#) as SID_COUNT,
         0 as plsql_entry_object_id,     -- important for recrsv queries only
         0 as plsql_entry_subprogram_id, -- --//--
         sh.sql_id,
         NVL2(sql_exec_id,1,null)                            as SQL_EXEC_ID,
         nvl(sql_plan_hash_value, 0)                         as SQL_PLAN_HASH_VALUE,
         nvl(sql_plan_line_id, 0)                            as SQL_PLAN_LINE_ID,
         decode(session_state,'WAITING',event,session_state) as EVENT,
         count(*)                                            as WAIT_COUNT,
         min(sample_time)                                    as MIN_SAMPLE_TIME,
         max(sample_time)                                    as MAX_SAMPLE_TIME,
         max(temp_space_allocated)                           as MAX_TEMP_SPACE_ALLOCATED,
         max(pga_allocated)                                  as max_pga_allocated
    from ash1 sh
   group by sh.sql_id, NVL2(sql_exec_id,1,null), nvl(sql_plan_hash_value, 0), nvl(sql_plan_line_id, 0), decode(session_state,'WAITING',event,session_state))
, ash_stat as ( -- direct SQL exec stats
select  sql_id,
        SQL_EXEC_ID,
        sql_plan_hash_value,
        sql_plan_line_id,
        sum(WAIT_COUNT) as ASH_ROWS,
        rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT, '); ').extract('//text()') order by WAIT_COUNT desc)--.getclobval ()
                                                                                                                   ,'; ') as WAIT_PROFILE,
        max(SID_COUNT)-1 as PX_COUNT,
        max(MAX_SAMPLE_TIME) as MAX_SAMPLE_TIME,
        max(MAX_TEMP_SPACE_ALLOCATED) as MAX_TEMP_SPACE_ALLOCATED,
        max(max_pga_allocated) as max_pga_allocated
from ash
group by sql_id,
         sql_exec_id,
         sql_plan_hash_value,
         sql_plan_line_id)
, ash_recrsv as ( -- ASH part, consisting of indirect / recursive SQLs execs ONLy
  select count(distinct sh.session_id||sh.session_serial#) as SID_COUNT,
         decode(sh.sql_id, sid_time.sql_id, 0, sh.plsql_entry_object_id)     as plsql_entry_object_id,    -- for recrsv queries only
         decode(sh.sql_id, sid_time.sql_id, 0, sh.plsql_entry_subprogram_id) as plsql_entry_subprogram_id,-- --//--
         sh.sql_id,
         nvl(sql_plan_hash_value, 0)                         as SQL_PLAN_HASH_VALUE,
         nvl(sql_plan_line_id, 0)                            as SQL_PLAN_LINE_ID,
         decode(session_state,'WAITING',event,session_state) as EVENT,
         count(*)                                            as WAIT_COUNT,
         min(sample_time)                                    as MIN_SAMPLE_TIME,
         max(sample_time)                                    as MAX_SAMPLE_TIME
    from ash0 sh, sid_time
   where (--(sh.top_level_sql_id = sid_time.sql_id and sh.sql_id != sid_time.sql_id or sh.sql_id is null) and-- recursive SQLs
          sh.session_id       = sid_time.session_id and
          sh.session_serial#  = sid_time.session_serial# and
          nvl(sh.qc_session_id, sh.session_id) = sid_time.qc_session_id and
          sh.sample_time between sid_time.MIN_SQL_EXEC_TIME and sid_time.MAX_SQL_EXEC_TIME)
   group by sh.sql_id, nvl(sql_plan_hash_value, 0), nvl(sql_plan_line_id, 0), decode(session_state,'WAITING',event,session_state),
            decode(sh.sql_id, sid_time.sql_id, 0, sh.plsql_entry_object_id),
            decode(sh.sql_id, sid_time.sql_id, 0, sh.plsql_entry_subprogram_id))
, ash_stat_recrsv as ( -- recursive SQLs stats
select  ash.plsql_entry_object_id,
        ash.plsql_entry_subprogram_id,
        ash.sql_id,
        sql_plan_hash_value,
        sql_plan_line_id,
        sum(WAIT_COUNT) as ASH_ROWS,
        rtrim(xmlagg(xmlelement(s, EVENT || '(' ||WAIT_COUNT, '); ').extract('//text()') order by WAIT_COUNT desc)--.getclobval ()
                                                                                                                  ,'; ') as WAIT_PROFILE,
        max(SID_COUNT)-1 as PX_COUNT,
        max(MAX_SAMPLE_TIME) as MAX_SAMPLE_TIME
from ash_recrsv ash --join sid_time on ash.sql_id <> sid_time.sql_id or ash.sql_id is null
group by ash.plsql_entry_object_id,
         ash.plsql_entry_subprogram_id,
         ash.sql_id,
         sql_plan_hash_value,
         sql_plan_line_id)
, pt as( -- Plan Tables for all excuted SQLs (direct+recursive)
select   sql_id,
         plan_hash_value,
         id,
         operation,
         options,
         qblock_name,
         object_alias,
         object_owner,
         object_name,
         cardinality,
         bytes,
         cost,
         temp_space,
         nvl(parent_id, -1) as parent_id
    from dba_hist_sql_plan
   where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)
     and not exists (select 1 from gv$sql_plan where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash))
  union
select   sql_id,
         plan_hash_value,
         id,
         operation,
         options,
         qblock_name,
         object_alias,
         object_owner,
         object_name,
         cardinality,
         bytes,
         cost,
         temp_space,
         nvl(parent_id, -1) as parent_id
    from dba_hist_sql_plan
   where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash_recrsv)
     and not exists (select 1 from gv$sql_plan where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash_recrsv))
  union                                          -- for plans not in dba_hist_sql_plan yet
  select distinct 
         sql_id,
         plan_hash_value,
         id,
         operation,
         options,
         qblock_name,
         object_alias,
         object_owner,
         object_name,
         cardinality,
         bytes,
         cost,
         temp_space,
         nvl(parent_id, -1) as parent_id
    from gv$sql_plan
-- about v$sql_plan.child_number multi
   where (sql_id, plan_hash_value, child_number) in (select ash.sql_id, sql_plan_hash_value, min(child_number) from ash join gv$sql_plan p on ash.sql_id = p.sql_id and ash.sql_plan_hash_value = p.plan_hash_value group by ash.sql_id, ash.sql_plan_hash_value
                                                     union
                                                     select ash_recrsv.sql_id, sql_plan_hash_value, min(child_number) from ash_recrsv join gv$sql_plan p on ash_recrsv.sql_id = p.sql_id and ash_recrsv.sql_plan_hash_value = p.plan_hash_value group by ash_recrsv.sql_id, sql_plan_hash_value)
--   where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash union select sql_id, sql_plan_hash_value from ash_recrsv)
--                    and child_number = (select min(child_number) from v$sql_plan where sql_id = '671hgg4ck0dpx' and plan_hash_value = nvl('3479296038',0))
  union                                          -- for plans not in dba_hist_sql_plan not v$sql_plan (read-only standby for example)
  select distinct 
         sql_id,
         sql_plan_hash_value as plan_hash_value,
         sql_plan_line_id    as id,
         sql_plan_operation  as operation,
         sql_plan_options    as options,
         ''                  as qblock_name,
         ''                  as object_alias,
         owner               as object_owner,
         object_name,
         null                as cardinality,
         null                as cost,
         null                as bytes,
         null                as temp_space,
         -2                  as parent_id
    from ash0 left join dba_objects on current_obj# = object_id
   where (sql_id, sql_plan_hash_value) in (select sql_id, sql_plan_hash_value from ash union select sql_id, sql_plan_hash_value from ash_recrsv)
     and (sql_id, sql_plan_hash_value) not in (select sql_id, plan_hash_value from gv$sql_plan union all select sql_id, plan_hash_value from dba_hist_sql_plan))
select 'Hard Parse' as LAST_PLSQL, -- the hard parse phase, sql plan does not exists yet, sql_plan_hash_value = 0
       sql_id,
       sql_plan_hash_value as plan_hash_value,
       ash_stat.sql_plan_line_id as ID,
       'sql_plan_hash_value = 0' as PLAN_OPERATION,
       null as QBLOCK_NAME,
       null as object_alias,
       null as object_owner,
       null as object_name,
       null as cardinality,
       null as bytes,
       null as cost,
       null as temp_space,
       ash_stat.PX_COUNT as PX,
       ash_stat.max_pga_allocated,
       ash_stat.MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  from ash_stat
 where sql_plan_hash_value = 0
UNION ALL
select 'Soft Parse' as LAST_PLSQL, -- the soft parse phase, sql plan exists but execution didn't start yet, sql_exec_id is null
       sql_id,              
       sql_plan_hash_value as plan_hash_value,
       ash_stat.sql_plan_line_id as ID,
       'sql_plan_hash_value > 0; sql_exec_id is null' as PLAN_OPERATION,
       null as QBLOCK_NAME,
       null as object_alias,
       null as object_owner,
       null as object_name,
       null as cardinality,
       null as bytes,
       null as cost,
       null as temp_space,
       ash_stat.PX_COUNT as PX,
       ash_stat.max_pga_allocated,
       ash_stat.MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  from ash_stat
 where sql_plan_hash_value > 0
   and sql_exec_id is null
UNION ALL
SELECT 'Main Query w/o saved plan'       -- direct SQL which plan not in gv$sql_plan, dba_hist_sql_plan (ro-standby)
                                                                 as LAST_PLSQL,
       pt.sql_id                                                 as SQL_ID,
       pt.plan_hash_value                                        as plan_hash_value,
       pt.id,
       lpad(' ', id) || pt.operation || ' ' || pt.options        as PLAN_OPERATION,
       pt.qblock_name,
       pt.object_alias,
       pt.object_owner,
       pt.object_name,
       cardinality,
       bytes,
       cost,
       temp_space,
       ash_stat.PX_COUNT                                         as PX,
       ash_stat.max_pga_allocated,
       ash_stat.MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  FROM pt
  left join ash_stat
  on --pt.parent_id       = -2 and
     pt.id              = NVL(ash_stat.sql_plan_line_id,0) and
     pt.sql_id          = ash_stat.sql_id and
     pt.plan_hash_value = ash_stat.sql_plan_hash_value         -- sql_plan_hash_value > 0
                      and ash_stat.sql_exec_id is not null
  where pt.parent_id       = -2
UNION ALL
SELECT case when pt.id =0 then 'Main Query' -- direct SQL plan+stats
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 10/86400 then '>>>'
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 30/86400 then '>> '
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 60/86400 then '>  '
            else '   ' end as LAST_PLSQL,
       decode(pt.id, 0, pt.sql_id, null) as SQL_ID,
       decode(pt.id, 0, pt.plan_hash_value, null) as plan_hash_value,
       pt.id,
       lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as PLAN_OPERATION,
       pt.qblock_name,
       pt.object_alias,
       pt.object_owner,
       pt.object_name,
       cardinality,
       bytes,
       cost,
       temp_space,
       ash_stat.PX_COUNT as PX,
       ash_stat.max_pga_allocated,
       ash_stat.MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  FROM pt
  left join ash_stat
  on pt.id              = NVL(ash_stat.sql_plan_line_id,0) and
     pt.sql_id          = ash_stat.sql_id and
     pt.plan_hash_value = ash_stat.sql_plan_hash_value         -- sql_plan_hash_value > 0
                      and ash_stat.sql_exec_id is not null
  where pt.sql_id in (select sql_id from ash_stat)
CONNECT BY PRIOR pt.id = pt.parent_id
       and PRIOR pt.sql_id = pt.sql_id
       and PRIOR pt.plan_hash_value = pt.plan_hash_value
 START WITH pt.id = 0
UNION ALL
SELECT decode(pt.id, 0, p.object_name||'.'||p.procedure_name, null) as LAST_PLSQL, -- recursive SQLs plan+stats
       decode(pt.id, 0, pt.sql_id, null) as SQL_ID,
       decode(pt.id, 0, pt.plan_hash_value, null) as plan_hash_value,
       pt.id,
       lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as PLAN_OPERATION,
       pt.qblock_name,
       pt.object_alias,
       pt.object_owner,
       pt.object_name,
       cardinality,
       bytes,
       cost,
       temp_space,
       ash_stat.PX_COUNT as PX,
       0 as max_pga_allocated,
       0 as MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  FROM pt
  left join ash_stat_recrsv ash_stat
  on pt.id              = NVL(ash_stat.sql_plan_line_id,0) and
     pt.sql_id          = ash_stat.sql_id and
    (pt.plan_hash_value = ash_stat.sql_plan_hash_value or ash_stat.sql_plan_hash_value = 0)
  left join dba_procedures p on ash_stat.plsql_entry_object_id     = p.object_id and
                                ash_stat.plsql_entry_subprogram_id = p.subprogram_id
  where pt.sql_id in (select sql_id from ash_stat_recrsv)
CONNECT BY PRIOR pt.id = pt.parent_id
       and PRIOR pt.sql_id = pt.sql_id
       and PRIOR pt.plan_hash_value = pt.plan_hash_value
 START WITH pt.id = 0
UNION ALL
select 'Recurs.waits' as LAST_PLSQL, -- non-identified SQL (PL/SQL?) exec stats
       '',
       0 as plan_hash_value,
       ash_stat.sql_plan_line_id,
       'sql_id is null and plsql[_entry]_object_id is null' as PLAN_OPERATION,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null as temp_space,
       ash_stat.PX_COUNT as PX,
       0 as max_pga_allocated,
       0 as MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  from ash_stat_recrsv ash_stat
 where sql_id is null
   and ash_stat.plsql_entry_object_id is null
UNION ALL
select 'PL/SQL' as LAST_PLSQL, -- non-identified SQL (PL/SQL?) exec stats
       '',
       0 as plan_hash_value,
       ash_stat.sql_plan_line_id,
       p.owner ||' '|| p.object_name||'.'||p.procedure_name as PLAN_OPERATION,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null as temp_space,
       ash_stat.PX_COUNT as PX,
       0 as max_pga_allocated,
       0 as MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  from ash_stat_recrsv ash_stat
  join dba_procedures p on ash_stat.plsql_entry_object_id     = p.object_id and
                                ash_stat.plsql_entry_subprogram_id = p.subprogram_id
 where sql_id is null
UNION ALL
select 'SQL Summary' as LAST_PLSQL, -- SQL_ID Summary
       '',
       0 as plan_hash_value,
       0 as sql_plan_line_id,
       'ASH fixed ' || count(distinct sql_exec_id) || ' execs from ' || count(distinct session_id || ' ' || session_serial#) || ' sessions' as PLAN_OPERATION,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null as temp_space,
       null as PX,
       null as max_pga_allocated,
       null as MAX_TEMP_SPACE_ALLOCATED,
       count(*) as ASH_ROWS,
       ' ash rows were fixed from ' || to_char(min(SAMPLE_TIME),'dd.mm.yyyy hh24:mi:ss') || ' to ' || to_char(max(SAMPLE_TIME),'dd.mm.yyyy hh24:mi:ss') as WAIT_PROFILE
  from ash0
   where sql_id              = '&&1' and                                -- direct SQL exec ONLY
         sql_plan_hash_value = nvl('&&2', sql_plan_hash_value) and
         NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0))
/
set feedback on VERIFY ON timi on
