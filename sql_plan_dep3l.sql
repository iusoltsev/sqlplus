--
-- SQL_PLAN Dependency Tree (Light)
-- @sql_plan_dep3l 4hnjr40pspnzk 2528178990 %CUST%
--                ^sql_id       ^phv       ^Obj.name pattern
--

set feedback on heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col DEP_TREE_BY_ID for a80
col DEP_TREE for a60
col DEPENDS_ON for a12
COLUMN LAST_TIME FORMAT A100 HEADING "LAST_DDL \\ LAST_ANALYZED \\ Temp? \\ DEGREE \\ Indices#"
col LAST_MODIFIED for a17
col last_analyzed for a19
col REFERENCED    for a60
col DOP    for a3

with sql_obj as
(select /*+ MATERIALIZE */ distinct object_owner, object_name
                       from v$sql_plan
                      where sql_id = '&&1'
                        and plan_hash_value =
                            nvl('&&2', plan_hash_value)
                        and object_owner is not null
                        and object_owner <> 'SYS'
                        and object_name is not null
                     union all
                     select object_owner, object_name
                       from dba_hist_sql_plan
                      where sql_id = '&&1'
                        and plan_hash_value =
                            nvl('&&2', plan_hash_value)
                        and object_owner is not null
                        and object_owner <> 'SYS'
                        and object_name is not null)
select * from (
select distinct
--       0 as "LEVEL",
--       'SQL_ID = ''' || '&&1' || ''' ; PHV = ' || '&&2' as DEP_TREE,
--       '' as DEPENDS_ON,
       'PLAN' as type,
       o.object_type || ' ' || o.owner || '.' || o.object_name as REFERENCED,
to_char(m.timestamp, 'DD.MM.YY hh24:mi:ss') as LAST_MODIFIED,
       to_char(o.last_ddl_time, 'YYYY.MM.DD hh24:mi:ss') as LAST_DDL
,trim(nvl(i.degree, t.degree)) as DOP
, nvl(t.last_analyzed, i.last_analyzed) as last_analyzed
from dba_objects o
left join (select table_owner, table_name, max(timestamp) as timestamp from dba_tab_modifications group by table_owner, table_name) m
       on m.table_owner = o.owner and m.table_name = o.object_name
          left join dba_tables t  on o.object_type = 'TABLE' and o.owner = t.owner and o.object_name = t.table_name
          left join dba_indexes i on o.object_type = 'INDEX' and o.owner = i.owner and o.object_name = i.index_name
where (o.owner, object_name) in (select object_owner, object_name from sql_obj)
  and object_type not in ('INDEX PARTITION','INDEX SUBPARTITION','TABLE PARTITION','TABLE SUBPARTITION'))
where REFERENCED like '%&&3%'
order by LAST_DDL desc
/

set feedback on VERIFY ON
