--
-- SQL Plan Statistics from ASH (including recursive queries and PL/SQL)
--  including 12c Adaptive Plan Processing
-- Usage: SQL> @ash_sqlmon12_temp &sql_id [&plan_hash_value] [&sql_exec_id] "where sample_time > trunc(sysdate,'hh24')"
--                                                                      ^ additional ASH condition

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

undefine &1
undefine &2
undefine &3
undefine &4

col PLAN_OPERATION for a170
col WAIT_PROFILE   for a200
col LAST_PLSQL     for a45
col ID             for a5 head "   ID"
col DISP           for a5 head " DISP"
col OBJECT_OWNER   for a16
col OBJECT_NAME    for a30
col QBLOCK_NAME    for a15
col SDATE          for a21 NOPRI
col CHAR_DATE new_value SYS_DATE
 
SET TERMOUT OFF
 
select to_char(sysdate,'dd.mm.yyyy hh24:mi:ss') CHAR_DATE from dual;
 
SET TERMOUT ON

with
 ash0 as (select * from --ASH_201605271205--ASH_201605201818--Gv$active_session_history-- 
          &4),
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
                  sql_plan_operation || ' ' || sql_plan_options as SQL_PLAN_OPERATION,
                  session_state,
                  event,
                  sum(temp_space_allocated) over (partition by sample_id, sql_exec_id) as temp_space_allocated, -- summary
                  sum(pga_allocated)        over (partition by sample_id, sql_exec_id) as pga_allocated        -- --//--
             from ash0
            where sql_id              = '&&1'                                -- direct SQL exec ONLY
              and sql_plan_hash_value = nvl('&&2', sql_plan_hash_value)
              and NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0)))
, ash as (select count(distinct sh.session_id||','||sh.session_serial#) as SID_COUNT,
                 0 as plsql_entry_object_id,     -- important for recrsv queries only
                 0 as plsql_entry_subprogram_id, -- --//--
                 sh.sql_id,
                 NVL2(sql_exec_id,1,null)                            as SQL_EXEC_ID,
                 nvl(sql_plan_hash_value, 0)                         as SQL_PLAN_HASH_VALUE,
                 nvl(sql_plan_line_id, 0)                            as SQL_PLAN_LINE_ID,
                 sql_plan_operation,
                 decode(session_state,'WAITING',event,session_state) as EVENT,
                 count(*)                                            as WAIT_COUNT,
                 min(sample_time)                                    as MIN_SAMPLE_TIME,
                 max(sample_time)                                    as MAX_SAMPLE_TIME,
                 max(temp_space_allocated)                           as MAX_TEMP_SPACE_ALLOCATED,
                 max(pga_allocated)                                  as max_pga_allocated
            from ash1 sh
           group by sh.sql_id, NVL2(sql_exec_id,1,null), nvl(sql_plan_hash_value, 0), nvl(sql_plan_line_id, 0), sql_plan_operation, decode(session_state,'WAITING',event,session_state))
, ash_stat as ( -- direct SQL exec stats
               select sql_id,
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
   where ((sh.top_level_sql_id = sid_time.sql_id and sh.sql_id != sid_time.sql_id or sh.sql_id is null) and-- recursive SQLs
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
-- Adaptive Plan for main query only
, display_map AS
 (SELECT X.*
  FROM dba_hist_sql_plan,
       XMLTABLE ( '/other_xml/display_map/row' passing XMLTYPE(other_xml ) COLUMNS 
                        op  NUMBER PATH '@op',    -- operation
                        dis NUMBER PATH '@dis',   -- display
                        par NUMBER PATH '@par',   -- parent
                        prt NUMBER PATH '@prt',   -- ?
                        dep NUMBER PATH '@dep',   -- depth
                        skp NUMBER PATH '@skp' )  -- skip
                    AS X
  WHERE (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)
  AND other_xml   IS NOT NULL
  union
  SELECT X.*
  FROM gv$sql_plan,
       XMLTABLE ( '/other_xml/display_map/row' passing XMLTYPE(other_xml ) COLUMNS 
                        op  NUMBER PATH '@op',    -- operation
                        dis NUMBER PATH '@dis',   -- display
                        par NUMBER PATH '@par',   -- parent
                        prt NUMBER PATH '@prt',   -- ?
                        dep NUMBER PATH '@dep',   -- depth
                        skp NUMBER PATH '@skp' )  -- skip
                    AS X
  WHERE (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)
  AND other_xml   IS NOT NULL
  and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash) and rownum <= 1))
/*, hist_fphv as (select p.sql_id,
                       p.plan_hash_value,
                       to_number(extractvalue(h.column_value, '/info')) as FULL_PLAN_HASH_VALUE
                  from dba_hist_sql_plan p,
                       table(xmlsequence(extract(xmltype(p.other_xml), '/other_xml/info'))) h
                 where p.other_xml is not null
     and extractvalue(h.column_value, '/info/@type') = 'plan_hash_full'
     and (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash))
*/
, p1 as -- Adaptive Plan Table for direct SQL only
 (select  nvl(s.SQL_ID,h.SQL_ID) as SQL_ID,
          nvl(s.PLAN_HASH_VALUE,h.PLAN_HASH_VALUE) as PLAN_HASH_VALUE,
--          nvl(s.FULL_PLAN_HASH_VALUE,h.FULL_PLAN_HASH_VALUE) as FULL_PLAN_HASH_VALUE,
          nvl(s.ID,h.ID) as ID,
          nvl(s.OPERATION,h.OPERATION) as OPERATION,
--          nvl(s.OPTIMIZER,h.OPTIMIZER) as OPTIMIZER,
          nvl(s.OPTIONS,h.OPTIONS) as OPTIONS,
--          nvl(s.ACCESS_PREDICATES,h.ACCESS_PREDICATES) as ACCESS_PREDICATES,
--          nvl(s.CPU_COST,h.CPU_COST) as CPU_COST,
--          nvl(s.DEPTH,h.DEPTH) as DEPTH,
--          nvl(s.DISTRIBUTION,h.DISTRIBUTION) as DISTRIBUTION,
--          nvl(s.FILTER_PREDICATES,h.FILTER_PREDICATES) as FILTER_PREDICATES,
          nvl(s.IO_COST,h.IO_COST) as IO_COST,
--          nvl(s.OBJECT#,h.OBJECT#) as OBJECT#,
          nvl(s.QBLOCK_NAME,h.QBLOCK_NAME) as QBLOCK_NAME,
          nvl(s.OBJECT_ALIAS,h.OBJECT_ALIAS) as OBJECT_ALIAS,
          nvl(s.OBJECT_OWNER,h.OBJECT_OWNER) as OBJECT_OWNER,
          nvl(s.OBJECT_NAME,h.OBJECT_NAME) as OBJECT_NAME,
--          nvl(s.OBJECT_NODE,h.OBJECT_NODE) as OBJECT_NODE,
--          nvl(s.OBJECT_TYPE,h.OBJECT_TYPE) as OBJECT_TYPE,
          nvl(s.CARDINALITY,h.CARDINALITY) as CARDINALITY,
          nvl(s.BYTES,h.BYTES) as BYTES,
          nvl(s.COST,h.COST) as COST,
--          nvl(s.OTHER,h.OTHER) as OTHER,
--          nvl(s.OTHER_TAG,h.OTHER_TAG) as OTHER_TAG,
--          nvl(s.PARTITION_ID,h.PARTITION_ID) as PARTITION_ID,
--          nvl(s.PARTITION_START,h.PARTITION_START) as PARTITION_START,
--          nvl(s.PARTITION_STOP,h.PARTITION_STOP) as PARTITION_STOP,
--          nvl(s.PLAN_HASH_VALUE,h.PLAN_HASH_VALUE) as PLAN_HASH_VALUE,
--          nvl(s.POSITION,h.POSITION) as POSITION,
--          nvl(s.PROJECTION,h.PROJECTION) as PROJECTION,
--          nvl(s.REMARKS,h.REMARKS) as REMARKS,
--          nvl(s.SEARCH_COLUMNS,h.SEARCH_COLUMNS) as SEARCH_COLUMNS,
--          nvl(s.SQL_ID,h.SQL_ID) as SQL_ID,
          nvl(s.TEMP_SPACE,h.TEMP_SPACE) as TEMP_SPACE,
--          nvl(s.TIME,h.TIME) as TIME,
--          nvl(s.TIMESTAMP,h.TIMESTAMP) as TIMESTAMP
          nvl(nvl(s.PARENT_ID,h.PARENT_ID), -1) as PARENT_ID
    from (select * from gv$sql_plan
          where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)
            and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash) and rownum <= 1)) s
    full outer join 
         (select * from dba_hist_sql_plan h
--                   join hist_fphv using (sql_id, plan_hash_value)
                  where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)) h
      on s.id = h.id)
, pt as (-- Plan Tables for all excuted SQLs (direct+recursive)
  SELECT -- Direct+Adaptive
         p1.sql_id,
         p1.PLAN_HASH_VALUE,
--         p1.FULL_PLAN_HASH_VALUE,
         NVL(m.dis, p1.ID) as DISP,
         p1.ID as ID,
         p1.operation,
         p1.options,
         p1.QBLOCK_NAME,
         p1.OBJECT_ALIAS,
         p1.object_owner,
         p1.object_name,
         p1.CARDINALITY,
         p1.BYTES,
         p1.cost,
--         to_char(p1.cost) || '(' || to_char(p1.io_cost) || ')' as "COST(IO)",
         p1.temp_space,
         nvl(p1.parent_id, -1) as parent_id,
         decode(nvl(m.skp,0),1,'-',' ') as SKIP
    FROM p1 left join display_map m on p1.id = m.op
--    where nvl(m.skp,0) <> 1
  union -- Plan Tables for excuted recursive SQLs
  select sql_id,
         plan_hash_value,
--         0 as FULL_PLAN_HASH_VALUE,
         ID as DISP,
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
         nvl(parent_id, -1) as parent_id,
         ' ' as SKIP
    from dba_hist_sql_plan
   where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash_recrsv)
     and not exists (select 1 from gv$sql_plan where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash_recrsv))
  union -- for recursive plans not in dba_hist_sql_plan yet
  select distinct 
         sql_id,
         plan_hash_value,
--         0 as FULL_PLAN_HASH_VALUE,
         ID as DISP,
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
         nvl(parent_id, -1) as parent_id,
         ' ' as SKIP
    from gv$sql_plan
-- about v$sql_plan.child_number multi
   where (sql_id, plan_hash_value, child_number) in (select ash_recrsv.sql_id, sql_plan_hash_value, min(child_number) from ash_recrsv join gv$sql_plan p on ash_recrsv.sql_id = p.sql_id and ash_recrsv.sql_plan_hash_value = p.plan_hash_value group by ash_recrsv.sql_id, sql_plan_hash_value)
  union -- for plans not in dba_hist_sql_plan not v$sql_plan (read-only standby for example)
  select distinct 
         sql_id,
         sql_plan_hash_value as plan_hash_value,
--         0                   as FULL_PLAN_HASH_VALUE,
         sql_plan_line_id    as DISP,
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
         -2                  as parent_id,
         ' ' as SKIP
    from ash0 left join dba_objects on current_obj# = object_id
   where (sql_id, sql_plan_hash_value) in (select sql_id, sql_plan_hash_value from ash union select sql_id, sql_plan_hash_value from ash_recrsv)
     and (sql_id, sql_plan_hash_value) not in (select sql_id, plan_hash_value from gv$sql_plan union all select sql_id, plan_hash_value from dba_hist_sql_plan))
select 'Hard Parse' as LAST_PLSQL, -- the hard parse phase, sql plan does not exists yet, sql_plan_hash_value = 0
       sql_id,
       sql_plan_hash_value as plan_hash_value,
       lpad(ash_stat.sql_plan_line_id,5) as ID,
       ''                                as DISP,
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
       , '&&SYS_DATE' as SDATE       
  from ash_stat
 where sql_plan_hash_value = 0
UNION ALL
select 'Soft Parse' as LAST_PLSQL, -- the soft parse phase, sql plan exists but execution didn't start yet, sql_exec_id is null
       sql_id,              
       sql_plan_hash_value               as plan_hash_value,
       lpad(ash_stat.sql_plan_line_id,5) as ID,
--       ''                                as ID,
       ''                                as DISP,
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
       , '&&SYS_DATE' as SDATE       
  from ash_stat
 where sql_plan_hash_value > 0
   and sql_exec_id is null
UNION ALL
SELECT 'Main Query w/o saved plan'       -- direct SQL which plan not in gv$sql_plan, dba_hist_sql_plan (ro-standby)
                                                                 as LAST_PLSQL,
       pt.sql_id                                                 as SQL_ID,
       pt.plan_hash_value                                        as plan_hash_value,
       lpad(pt.id,5)                                             as ID,
       ''                                                        as DISP,
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
       , '&&SYS_DATE' as SDATE       
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
       decode(pt.id, 0, pt.sql_id, null)          as SQL_ID,
       decode(pt.id, 0, pt.plan_hash_value, null) as plan_hash_value,
       pt.skip || lpad(pt.id,4)                   as ID,
       lpad(pt.disp,4)                            as DISP,
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
       , '&&SYS_DATE' as SDATE       
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
 START WITH pt.id = 0
UNION ALL
SELECT decode(pt.id, 0, p.object_name||'.'||p.procedure_name, null) as LAST_PLSQL, -- recursive SQLs plan+stats
       decode(pt.id, 0, pt.sql_id, null) as SQL_ID,
       decode(pt.id, 0, pt.plan_hash_value, null) as plan_hash_value,
       lpad(pt.id,5)                              as ID,
       ''                                         as DISP,
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
       , '&&SYS_DATE' as SDATE       
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
       lpad(ash_stat.sql_plan_line_id,5) as ID,
       ''                                as DISP,
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
       , '&&SYS_DATE' as SDATE       
  from ash_stat_recrsv ash_stat
 where sql_id is null
   and ash_stat.plsql_entry_object_id is null
UNION ALL
select 'PL/SQL' as LAST_PLSQL, -- non-identified SQL (PL/SQL?) exec stats
       '',
       0 as plan_hash_value,
       lpad(ash_stat.sql_plan_line_id,5) as ID,
       ''                                as DISP,
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
       , '&&SYS_DATE' as SDATE       
  from ash_stat_recrsv ash_stat
  join dba_procedures p on ash_stat.plsql_entry_object_id     = p.object_id and
                                ash_stat.plsql_entry_subprogram_id = p.subprogram_id
 where sql_id is null
UNION ALL
select 'Main SQL Summary' as LAST_PLSQL, -- SQL_ID Summary
       '',
       0       as plan_hash_value,
       ''      as id,
       ''      as DISP,
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
       , '&&SYS_DATE' as SDATE       
  from ash1
   where sql_id              = '&&1' and                                -- direct SQL exec ONLY
         sql_plan_hash_value = nvl('&&2', sql_plan_hash_value) and
         NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0))
/
set feedback on VERIFY ON timi on
