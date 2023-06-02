--
-- SQL Plan Statistics for SQL executions with PHV=0 from ASH (w/o recursive queries and PL/SQL)
--
-- Usage: SQL> @ash_sqlmon2phv0 &sql_id [&test_PHV] [&sql_exec_id] "Gv$active_session_history where sample_time > trunc(sysdate,'hh24')"
-- 

set feedback off heading on timi off pages 500 lines 1000 echo off  VERIFY OFF

--undefine &1
--undefine &2
--undefine &3
--undefine &4

col PLAN_OPERATION for a120
col WAIT_PROFILE for a200
col LAST_PLSQL for a20
col ID for a9
col OBJECT_OWNER for a16
col OBJECT_NAME for a30
col OBJECT_ALIAS for a60
col QBLOCK_NAME for a15
col ACCESS_PREDICATES for a60
col FILTER_PREDICATES for a60
col SQL_ID for a13
col plan_hash_value for a15
col ASH_PLAN_OPERATION for a45
col ASH_ID for 99999

with
  ash0 as (select * from &4)
, ash1 as (select sample_time,
                 session_id,
                 session_serial#,
                 sql_id,
                 sql_opname,
                 sql_exec_id,
                 sql_plan_hash_value,
                 sql_full_plan_hash_value,
                 sql_plan_line_id,
                 sql_plan_operation||' '||sql_plan_options as sql_plan_operation,
                 session_state,
                 event,
                 sum(temp_space_allocated) over (partition by sample_id) as temp_space_allocated, -- summary
                 sum(pga_allocated)        over (partition by sample_id) as pga_allocated        -- --//--
            from ash0
           where sql_id              = '&&1'                                -- direct SQL exec ONLY
--             and (sql_plan_hash_value = nvl('&&2', sql_plan_hash_value) or nvl('&&2',1) = 0)
and sql_plan_hash_value = 0 -- start here
             and (NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0)) or nvl('&&3',1) = 0)
          )
, ash as (                               -- ASH part, consisting of direct SQL exec ONLy
  select count(distinct sh.session_id||','||sh.session_serial#) as SID_COUNT,
         0 as plsql_entry_object_id,     -- important for recrsv queries only
         0 as plsql_entry_subprogram_id, -- --//--
         sh.sql_id,
         sql_opname,
         NVL2(sql_exec_id,1,null)                            as SQL_EXEC_ID,
         nvl(sql_plan_hash_value, 0)                         as SQL_PLAN_HASH_VALUE,
         nvl(sql_full_plan_hash_value, 0)                    as SQL_FULL_PLAN_HASH_VALUE,
         nvl(sql_plan_line_id, 0)                            as SQL_PLAN_LINE_ID,
         sql_plan_operation,
         decode(session_state,'WAITING',event,session_state) as EVENT,
         count(*)                                            as WAIT_COUNT,
         min(sample_time)                                    as MIN_SAMPLE_TIME,
         max(sample_time)                                    as MAX_SAMPLE_TIME,
         max(temp_space_allocated)                           as MAX_TEMP_SPACE_ALLOCATED,
         max(pga_allocated)                                  as max_pga_allocated
    from ash1 sh
   group by sh.sql_id, NVL2(sql_exec_id,1,null), nvl(sql_plan_hash_value, 0), nvl(sql_full_plan_hash_value, 0), nvl(sql_plan_line_id, 0), decode(session_state,'WAITING',event,session_state),sql_opname
, sql_plan_operation)
, ash_stat as ( -- direct SQL exec stats
select  sql_id,
        sql_opname,
        SQL_EXEC_ID,
        sql_plan_hash_value,
        SQL_FULL_PLAN_HASH_VALUE,
        sql_plan_line_id,
        sql_plan_operation,
        sum(WAIT_COUNT) as ASH_ROWS,
        rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT, '); ').extract('//text()') order by WAIT_COUNT desc)--.getclobval ()
                                                                                                                   ,'; ') as WAIT_PROFILE,
        max(SID_COUNT)-1 as PX_COUNT,
        max(MAX_SAMPLE_TIME) as MAX_SAMPLE_TIME,
        min(MIN_SAMPLE_TIME) as MIN_SAMPLE_TIME,
        max(MAX_TEMP_SPACE_ALLOCATED) as MAX_TEMP_SPACE_ALLOCATED,
        max(max_pga_allocated) as max_pga_allocated
from ash
group by sql_id,
         sql_opname,
         sql_exec_id,
         sql_plan_hash_value,
         SQL_FULL_PLAN_HASH_VALUE,
         sql_plan_line_id
        ,sql_plan_operation)
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
  WHERE sql_id        = '&&1'
  AND plan_hash_value =  &&2
  AND other_xml   IS NOT NULL
  and dbid in (select dbid from v$database)
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
  WHERE sql_id        = '&&1'
  AND plan_hash_value =  &&2
  AND other_xml   IS NOT NULL
  and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&1' and plan_hash_value = &&2 and rownum <= 1))
, pt as( -- Plan Tables for all excuted SQLs (direct+recursive)
select   sql_id,
         plan_hash_value,
         id,
--NVL(m.dis, p.ID) as ID,
         operation,
         options,
         qblock_name,
         object_alias,
         object_owner,
         object_name,
--||' ('||(select LISTAGG(column_name, ',' --ON OVERFLOW TRUNCATE '***'
--) WITHIN GROUP (ORDER BY column_position) from dba_ind_columns where index_owner = object_owner and index_name = object_name)||')' as object_name,
-- access_predicates, filter_predicates,
         cardinality,
         bytes,
         cost,
         temp_space,
         nvl(parent_id, -1) as parent_id
--NVL(m.par, nvl(parent_id, -1)) as  parent_id
, nvl(m.skp,0) as SKP
    from dba_hist_sql_plan p
left join display_map m on p.id = m.op
   where --(sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)
         sql_id = '&&1'                                -- direct SQL exec ONLY
         and plan_hash_value = nvl('&&2', plan_hash_value)
     and (sql_id, plan_hash_value) Not in (select sql_id, plan_hash_value from gv$sql_plan)
     and dbid in (select dbid from v$database)
----and nvl(m.skp,0) <> 1
  union                                          -- for plans not in dba_hist_sql_plan yet
  select distinct 
         sql_id,
         plan_hash_value,
         id,
--NVL(m.dis, p.ID) as ID,
         operation,
         options,
         qblock_name,
         object_alias,
         object_owner,
         object_name,
--||' ('||(select LISTAGG(column_name, ',' --ON OVERFLOW TRUNCATE '***'
--) WITHIN GROUP (ORDER BY column_position) from dba_ind_columns where index_owner = object_owner and index_name = object_name)||')' as object_name,
-- access_predicates, filter_predicates,
         cardinality,
         bytes,
         cost,
         temp_space,
         nvl(parent_id, -1) as parent_id
--NVL(m.par, nvl(parent_id, -1)) as  parent_id
, nvl(m.skp,0) as SKP
    from gv$sql_plan p
left join display_map m on p.id = m.op
-- about v$sql_plan.child_number multi and multi/adaptive PHV
   where (sql_id, plan_hash_value, child_number, inst_id) in
            (select sql_id, plan_hash_value, child_number, inst_id
              from (select p.sql_id,p.plan_hash_value,p.child_number,p.inst_id,ROW_NUMBER() OVER(PARTITION BY p.sql_id, p.plan_hash_value ORDER BY p.timestamp) as rn
                      from gv$sql_plan p
                     where sql_id = '&&1'                                -- direct SQL exec ONLY
                       and plan_hash_value = nvl('&&2', plan_hash_value)
                       and p.id = 0) where rn = 1)
----and nvl(m.skp,0) <> 1
)
, pt_adapt as (
select sql_id,
       plan_hash_value,
       pt.id,
       lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as PLAN_OPERATION,
       pt.qblock_name,
       pt.object_alias,
       pt.object_owner,
       pt.object_name,
-- pt.access_predicates, pt.filter_predicates,
       cardinality,
       bytes,
       cost,
       temp_space
, SKP
  FROM pt
CONNECT BY PRIOR pt.id = pt.parent_id
       and PRIOR pt.sql_id = pt.sql_id
       and PRIOR pt.plan_hash_value = pt.plan_hash_value
 START WITH pt.id = 0)
SELECT 3,case when pt.id =0 then 'Main Query' -- direct SQL plan+stats
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 10/86400 then '>>>'
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 30/86400 then '>> '
            when ash_stat.MAX_SAMPLE_TIME > sysdate - 60/86400 then '>  '
            else '   ' end as LAST_PLSQL,
       decode(pt.id, 0, pt.sql_id, null) as SQL_ID,
       decode(pt.id, 0, to_char(pt.plan_hash_value), null) as plan_hash_value,
ash_stat.sql_plan_line_id   as ASH_ID,
ash_stat.sql_plan_operation as ASH_PLAN_OPERATION,
       ash_stat.ASH_ROWS,
       pt.id,
       decode(SKP, 1, ' (-)', '') as SKP,
       pt.PLAN_OPERATION || decode(SKP, 1, ' (-)', '') as PLAN_OPERATION,
       pt.qblock_name,
       pt.object_alias,
       pt.object_owner,
       pt.object_name,
-- pt.access_predicates, pt.filter_predicates,
--       cardinality,
--       bytes,
--       cost,
--       temp_space,
       ash_stat.PX_COUNT as PX,
       ash_stat.max_pga_allocated,
       ash_stat.MAX_TEMP_SPACE_ALLOCATED,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
, to_char(ash_stat.MIN_SAMPLE_TIME,'dd.mm hh24:mi:ss') as MIN_SAMPLE_TIME, to_char(ash_stat.MAX_SAMPLE_TIME,'dd.mm hh24:mi:ss') as MAX_SAMPLE_TIME
  FROM pt_adapt pt
  full outer join ash_stat
  on pt.id              = ash_stat.sql_plan_line_id--NVL(ash_stat.sql_plan_line_id,0)
 and pt.sql_id          = ash_stat.sql_id
----and pt.operation || ' ' || pt.options = ash_stat.sql_plan_operation
 and ash_stat.sql_exec_id is not null
UNION ALL
select 6,'SQL Summary' as LAST_PLSQL, -- SQL_ID Summary
       '&&1',
       '0' as sql_plan_hash_value,
       null as ASH_ID,
       'ASH fixed ' || count(distinct sql_exec_id) || ' execs from ' || count(distinct session_id || ' ' || session_serial#) || ' sessions' as ASH_PLAN_OPERATION,
       null,
       null as sql_plan_line_id,
       null as SKP,
       null as PLAN_OPERATION,
       null,
       null,
       null,
       null,
-- '' as access_predicates, '' as filter_predicates,
--       null,
--       null,
--       null,
--       null as temp_space,
       null as PX,
       null as max_pga_allocated,
       null as MAX_TEMP_SPACE_ALLOCATED,
       count(*) as ASH_ROWS,
       ' ash rows were fixed from ' || to_char(min(SAMPLE_TIME),'dd.mm.yyyy hh24:mi:ss') || ' to ' || to_char(max(SAMPLE_TIME),'dd.mm.yyyy hh24:mi:ss') as WAIT_PROFILE
, '' as MIN_SAMPLE_TIME, '' as MAX_SAMPLE_TIME
  from ash0
   where sql_id              = '&&1' -- direct SQL exec ONLY
AND sql_plan_hash_value = 0
--         (sql_plan_hash_value = nvl('&&2', sql_plan_hash_value) or nvl('&&2',1) = 0)
     and (NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0)) or nvl('&&3',1) = 0)
UNION ALL
select 7,'SQL Summary by PHV' as LAST_PLSQL, -- SQL_ID Summary-2
       sql_id,
       to_char(sql_plan_hash_value) as sql_plan_hash_value,
       null as ASH_ID,
       'ASH rows: ' || count(*) || '; Dist.Execs: ' || count(distinct sql_exec_id) as ASH_PLAN_OPERATION,
       null,
       null as sql_plan_line_id,
       null as SKP,
       null as PLAN_OPERATION,
       null,
       null,
       null,
       null,
-- '' as access_predicates, '' as filter_predicates,
--       null,
--       null,
--       null,
--       null as temp_space,
       null as PX,
       null as max_pga_allocated,
       null as MAX_TEMP_SPACE_ALLOCATED,
       null as ASH_ROWS,
       null as WAIT_PROFILE
, '' as MIN_SAMPLE_TIME, '' as MAX_SAMPLE_TIME
  from ash0
   where sql_id               = '&&1' -- direct SQL exec ONLY
AND sql_plan_hash_value = 0
--         (sql_plan_hash_value = nvl('&&2', sql_plan_hash_value) or nvl('&&2',1) = 0)
     and (NVL(sql_exec_id, 0) = nvl('&&3', NVL(sql_exec_id, 0)) or nvl('&&3',1) = 0)
  group by sql_id, sql_plan_hash_value
order by 1,8,5
/
set feedback on VERIFY ON timi on
