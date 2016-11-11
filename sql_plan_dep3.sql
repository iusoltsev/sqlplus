--
-- @sql_plan_dep3 4hnjr40pspnzk 2528178990 %CUST%
--                ^sql_id       ^phv       ^Obj.name pattern
--

set feedback on heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col DEP_TREE_BY_ID for a80
col DEP_TREE for a60
col DEPENDS_ON for a12
COLUMN LAST_TIME FORMAT A100 HEADING "LAST_DDL \\ LAST_ANALYZED \\ Temp? \\ DEGREE \\ Indices#"
col LAST_MODIFIED for a17
col REFERENCED    for a60

/*
with pd as
 (select 1 as object_id, object_id as referenced_object_id
    from dba_objects
   where (owner, object_name) in
         (select distinct object_owner, object_name
            from v$sql_plan
           where sql_id = '&&1' and plan_hash_value = nvl('&&2',plan_hash_value) -- and child_number = nvl('v2',0) --
             and object_owner is not null
             and object_name is not null)
  union all
  select * from public_dependency)
select distinct REGEXP_REPLACE(sys_connect_by_path(object_id, ' / '), '^ \/ 1', '&&1') as DEP_TREE_BY_ID,
                lpad(' ', 2 * level) ||
                (select object_type || ' ' || owner || '.' || object_name from dba_objects where object_id = pd.referenced_object_id) as DEP_TREE,
                --sys_connect_by_path((select object_type || ' ' || owner || '.' || object_name from dba_objects where object_id = pd.referenced_object_id), ' / ') as DEP_TREE_BY_NAME,
                (select to_char(o.last_ddl_time, 'DD-MON-YY') || ' \\ ' ||
                        to_char(nvl(i.last_analyzed, t.last_analyzed), 'DD-MON-YY hh24:mi:ss') || ' \\ ' ||
                        decode(nvl(i.TEMPORARY, t.TEMPORARY), 'Y', ' GTT!', '') || ' \\ ' ||
                        'DOP=' || trim( i.degree || t.degree ) || ' \\ ' ||
                        (select count(index_name) from dba_indexes where table_owner = o.owner and table_name = o.object_name and index_type <> 'LOB') -- by LeBorchuk
                   from dba_objects o
                   left join dba_tables t on o.object_type = 'TABLE' and o.owner = t.owner and o.object_name = t.table_name
                   left join dba_indexes i on o.object_type = 'INDEX' and o.owner = i.owner and o.object_name = i.index_name
                  where o.object_id = pd.referenced_object_id) as  "DDL/ANALYZED/TMP/DOP/IDX_CNT"
  from pd
connect by prior referenced_object_id = object_id
 start with object_id = 1
 ORDER BY 1
*/

with sql_obj as
(select object_owner, object_name
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
       0 as "LEVEL",
       'SQL_ID = ''' || '&&1' || ''' ; PHV = ' || '&&2' as DEP_TREE,
       '' as DEPENDS_ON,
       'PLAN' as type,
       o.object_type || ' ' || o.owner || '.' || o.object_name as REFERENCED,
       to_char(m.timestamp, 'DD.MM.YY hh24:mi:ss') as LAST_MODIFIED,
       to_char(o.last_ddl_time, 'DD.MM.YY hh24:mi:ss') as LAST_DDL
,trim(nvl(i.degree, t.degree)) as DOP
from dba_objects o
left join (select table_owner, table_name, max(timestamp) as timestamp from dba_tab_modifications group by table_owner, table_name) m
       on m.table_owner = o.owner and m.table_name = o.object_name
          left join dba_tables t  on o.object_type = 'TABLE' and o.owner = t.owner and o.object_name = t.table_name
          left join dba_indexes i on o.object_type = 'INDEX' and o.owner = i.owner and o.object_name = i.index_name
where (o.owner, object_name) in (select object_owner, object_name from sql_obj)
  and object_type not in ('INDEX PARTITION','INDEX SUBPARTITION')
union all
select level,
       lpad('  ', 2 * level) || type || ' ' || owner || '.' || name as DEP_TREE,
       lpad('>', level, '>') as DEPENDS_ON,
       dependency_type as type,
       referenced_type || ' ' || referenced_owner || '.' || referenced_name as REFERENCED,
       to_char(m.timestamp, 'DD.MM.YY hh24:mi:ss') as LAST_MODIFIED
,'' as LAST_DDL
,'' as DOP
  from dba_dependencies
  left join (select table_owner, table_name, max(timestamp) as timestamp from dba_tab_modifications group by table_owner, table_name) m
    on m.table_owner = referenced_owner and m.table_name = referenced_name
where not (dependency_type = 'REF' and type = 'MATERIALIZED VIEW')
connect by nocycle type  = prior referenced_type
               and owner = prior referenced_owner
               and name  = prior referenced_name
               and not (prior dependency_type = 'REF' and prior type = 'MATERIALIZED VIEW')
 start with (owner, name) in
            (select object_owner, object_name from sql_obj)
) where DEP_TREE like '%&&3%' or REFERENCED like '%&&3%'
/

set feedback on VERIFY ON
