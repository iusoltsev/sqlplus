set feedback off heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col DEP_TREE_BY_ID for a80
col DEP_TREE for a60
COLUMN LAST_TIME FORMAT A60 HEADING 'LAST_DDL \\ LAST_ANALYZED \\ DEGREE'

with pd as
 (select /*+ materialize*/
   1 as object_id, object_id as referenced_object_id
    from dba_objects
   where (owner, object_name) in -- (('OWNER', 'OBJECT_NAME'))
         (select distinct object_owner, object_name
            from dba_hist_sql_plan
           where sql_id = '&1' and plan_hash_value = nvl('&2', plan_hash_value)
             and object_owner is not null
             and object_name is not null)
  union all
  select * from public_dependency)
select distinct REGEXP_REPLACE(sys_connect_by_path(object_id, ' / '), '^ \/ 1', '&&1') as DEP_TREE_BY_ID,
                lpad(' ', 2 * level) ||
                (select object_type || ' ' || owner || '.' || object_name from dba_objects where object_id = pd.referenced_object_id) as DEP_TREE,
                --sys_connect_by_path((select object_type || ' ' || owner || '.' || object_name from dba_objects where object_id = pd.referenced_object_id), ' / ') as DEP_TREE_BY_NAME,
                (select to_char(o.last_ddl_time, 'DD-MON-YY') || ' \\ ' ||
                        to_char(nvl(i.last_analyzed, t.last_analyzed), 'DD-MON-YY') || ' \\ ' ||
                        'degree=' || nvl(i.degree, t.degree)
                   from dba_objects o
                   left join dba_tables t on o.object_type = 'TABLE' and o.owner = t.owner and o.object_name = t.table_name
                   left join dba_indexes i on o.object_type = 'INDEX' and o.owner = i.owner and o.object_name = i.index_name
                  where o.object_id = pd.referenced_object_id) as LAST_TIME
  from pd
connect by prior referenced_object_id = object_id
 start with object_id = 1
 ORDER BY 1
/

set feedback on VERIFY ON
