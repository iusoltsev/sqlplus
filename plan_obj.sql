set feedback off timi off pages 1000 lines 500 VERIFY OFF

col OBJECT_TREE for a20
col OWNER for a30
col OBJECT_NAME for a30
col LAST_ANALYZED for a20

select lpad(' ', 2 * (level - 1)) || o.object_type as OBJECT_TREE,
       o.OWNER,
       o.OBJECT_NAME,
       to_char(nvl(t.last_analyzed, i.last_analyzed), 'dd.mm.yyyy hh24:mi') as LAST_ANALYZED
  from dba_objects o
  left join public_dependency pd
    on o.object_id = pd.object_id
  left join dba_tables t
    on t.owner = o.owner
   and t.table_name = o.object_name
   and o.object_type = 'TABLE'
  left join dba_indexes i
    on i.owner = o.owner
   and i.index_name = o.object_name
   and o.object_type = 'INDEX'
connect by prior nvl(pd.referenced_object_id,0) = o.object_id
 start with (o.owner, o.object_name) in
            (select object_owner, object_name
               from gv$sql_plan
              where sql_id = '&&1'
                and child_number = nvl('&&2',0)
                and object_owner is not null
                and object_name is not null)
/
prompt ""
prompt ""
prompt Non-Default Optimizer Env
select name, value
  from gv$sql_optimizer_env
 where sql_id = '&&1'
   and child_number = nvl('&&2',0)
   and isdefault <> 'YES'
/
set feedback on echo off VERIFY ON timi on