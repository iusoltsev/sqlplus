--
-- ASH SQL Plan Statistics query block Summary info
-- Usage: SQL> @ash_sqlmon12s &sql_id [&plan_hash_value] [&sql_exec_id] "where sample_time > trunc(sysdate,'hh24')"
--                                                                      ^ additional ASH condition
-- http://iusoltsev.wordpress.com/
--

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

undefine &1
undefine &2
undefine &3
undefine &4

col PLAN_OPERATION  for a170
col WAIT_PROFILE    for a200
col LAST_PLSQL      for a45
col ID              for a5 head "   ID"
col DISP            for a5 head " DISP"
col OBJECT_OWNER    for a16
col OBJECT_NAME     for a30
col QBLOCK_NAME     for a15
col MIN_SAMPLE_TIME for a25
col MAX_SAMPLE_TIME for a25
col SDATE           for a21 NOPRI
col CHAR_DATE new_value SYS_DATE
 
SET TERMOUT OFF
 
--select to_char(sysdate,'dd.mm.yyyy hh24:mi:ss') CHAR_DATE from dual;
 
SET TERMOUT ON

with
  ash0 as (select * from Gv$active_session_history &4)
, ash1 as (select sample_time,
                  session_id,
                  session_serial#,
                  sql_id,
                  sql_opname,
                  sql_exec_id,
                  sql_plan_hash_value,
                  sql_plan_line_id,
                  session_state,
                  event,
                  sum(temp_space_allocated) over (partition by sample_id) as temp_space_allocated, -- summary
                  sum(pga_allocated)        over (partition by sample_id) as pga_allocated        -- --//--
             from ash0
            where sql_id              = '&1'                                -- direct SQL exec ONLY
              and sql_plan_hash_value = nvl('&2', sql_plan_hash_value)
              and NVL(sql_exec_id, 0) = nvl('&3', NVL(sql_exec_id, 0)))
, ash as (                               -- ASH part, consisting of direct SQL exec ONLy
  select count(distinct sh.session_id||','||sh.session_serial#) as SID_COUNT,
         sh.sql_id,
         sql_opname,
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
   group by sh.sql_id, NVL2(sql_exec_id,1,null), nvl(sql_plan_hash_value, 0), nvl(sql_plan_line_id, 0), decode(session_state,'WAITING',event,session_state),sql_opname)
, pt as( -- Plan Tables for all excuted SQLs (direct ONLY)
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
   where (sql_id, plan_hash_value, child_number, inst_id) in (select ash.sql_id, sql_plan_hash_value, min(child_number), min(inst_id) from ash join gv$sql_plan p on ash.sql_id = p.sql_id and ash.sql_plan_hash_value = p.plan_hash_value group by ash.sql_id, ash.sql_plan_hash_value))
select  ash.sql_id,
        ash.sql_plan_hash_value,
        pt.qblock_name,
        sum(ash.WAIT_COUNT) as ASH_ROWS,
        substr(rtrim(xmlagg(xmlelement(s, ash.EVENT || '(' || ash.WAIT_COUNT, '); ').extract('//text()') order by ash.WAIT_COUNT desc)--.getclobval ()
                                                                                                                   ,'; '), 1, 200) as WAIT_PROFILE,
        max(SID_COUNT)-1     as MAX_PX_COUNT,
        min(MIN_SAMPLE_TIME) as MIN_SAMPLE_TIME,
        max(MAX_SAMPLE_TIME) as MAX_SAMPLE_TIME,
        max(MAX_TEMP_SPACE_ALLOCATED) as MAX_TEMP_SPACE_ALLOCATED,
        max(max_pga_allocated) as max_pga_allocated
    FROM ash join pt
      on pt.id                = ash.sql_plan_line_id and
         pt.sql_id            = ash.sql_id and
         pt.plan_hash_value   = ash.sql_plan_hash_value and         -- sql_plan_hash_value > 0
         ash.sql_exec_id is not null
group by ash.sql_id,
         ash.sql_plan_hash_value,
         pt.qblock_name
order by ash.sql_id, ash.sql_plan_hash_value, pt.qblock_name nulls first
/*
, mainq as (
  SELECT case when pt.id =0 then 'Main Query' -- direct SQL plan+stats
              when ash_stat.MAX_SAMPLE_TIME > sysdate - 10/86400 then '>>>'
              when ash_stat.MAX_SAMPLE_TIME > sysdate - 30/86400 then '>> '
              when ash_stat.MAX_SAMPLE_TIME > sysdate - 60/86400 then '>  '
              else '   ' end                                       as LAST_PLSQL,
         decode(pt.id, 0, pt.sql_id, null)                         as SQL_ID,
         decode(pt.id, 0, pt.plan_hash_value, null)                as PLAN_HASH_VALUE,
         pt.skip || lpad(pt.id,4)                                  as ID,
         lpad(pt.disp,4)                                           as DISP,
         lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as PLAN_OPERATION,
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
         ash_stat.MIN_SAMPLE_TIME                                  as MIN_SAMPLE_TIME,
         ash_stat.MAX_SAMPLE_TIME                                  as MAX_SAMPLE_TIME,
         ash_stat.WAIT_PROFILE
         , '&&SYS_DATE'                                            as SDATE
    FROM pt
    left join ash_stat
    on pt.id                = NVL(ash_stat.sql_plan_line_id,0) and
  --  on pt.DISP              = NVL(ash_stat.sql_plan_line_id,0) and pt.operation || ' ' || pt.options = ash_stat.sql_plan_operation and
       pt.sql_id            = ash_stat.sql_id and
       pt.plan_hash_value   = ash_stat.sql_plan_hash_value and         -- sql_plan_hash_value > 0
       ash_stat.sql_exec_id is not null
    where pt.sql_id in (select sql_id from ash_stat)
  CONNECT BY PRIOR pt.id              = pt.parent_id
         and PRIOR pt.sql_id          = pt.sql_id
         and PRIOR pt.plan_hash_value = pt.plan_hash_value
   START WITH pt.id = 0)
select * from mainq
UNION ALL
select 'Main SQL Stats'                                                     as LAST_PLSQL, -- SQL_ID Summary
       ''                                                                   as SQL_ID,
       null                                                                 as PLAN_HASH_VALUE,
       ''                                                                   as ID,
       ''                                                                   as DISP,
       'ASH fixed ' || count(distinct sql_exec_id) || ' execs from ' ||
        count(distinct session_id || ' ' || session_serial#) || ' sessions' as PLAN_OPERATION,
       null,
       null,
       null,
       null,
       null,
       null,
       null,
       null                                                                 as TEMP_SPACE,
       null                                                                 as PX,
       null                                                                 as MAX_PGA_ALLOCATED,
       null                                                                 as MAX_TEMP_SPACE_ALLOCATED,
       count(*)                                                             as ASH_ROWS,
       min(SAMPLE_TIME)                                                     as MIN_SAMPLE_TIME,
       max(SAMPLE_TIME)                                                     as Max_SAMPLE_TIME,
--       ' ash rows were fixed from ' || to_char(min(SAMPLE_TIME),'dd.mm.yyyy hh24:mi:ss') || ' to ' || to_char(max(SAMPLE_TIME),'dd.mm.yyyy hh24:mi:ss')
       ''                                                                   as WAIT_PROFILE
       , '&&SYS_DATE'                                                       as SDATE       
  from ash1
   where sql_id              = '&&1' and                                -- direct SQL exec ONLY
         sql_plan_hash_value = nvl('&&2', sql_plan_hash_value) and
         NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0))
UNION ALL
select 'Stats by QBlock Name'                                    as LAST_PLSQL, -- SQL_ID Summary
       min(sql_id)                                               as SQL_ID,
       min(plan_hash_value)                                      as PLAN_HASH_VALUE,
       min(id)                                                   as ID,
       max(id)                                                   as DISP,
       null                                                      as PLAN_OPERATION,
       QBLOCK_NAME,
       null,
       null,
       null,
       null,
       null,
       null,
       null                                                      as temp_space,
       max(px)                                                   as PX,
       max(max_pga_allocated)                                    as max_pga_allocated,
       max(max_temp_space_allocated)                             as MAX_TEMP_SPACE_ALLOCATED,
       sum(ash_rows) as ASH_ROWS,
       min(MIN_SAMPLE_TIME) as MIN_SAMPLE_TIME,       
       max(MAX_SAMPLE_TIME) as MAX_SAMPLE_TIME,       
       '' as WAIT_PROFILE
       , '&&SYS_DATE' as SDATE       
  from mainq
 group by QBLOCK_NAME
having sum(ASH_ROWS) > 0
*/
/
set feedback on VERIFY ON timi on
