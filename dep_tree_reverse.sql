--
-- Full dependency tree for db object
-- Usage: SQL> @dep_tree_reverse SCOTT EMP
--

set echo off feedback off heading on VERIFY OFF serveroutput on

select level,
       lpad('  ', 2 * (level - 1)) || referenced_type || ' ' || referenced_owner || '.' || referenced_name as DEP_TREE,
       lpad('<', level, '<')                                                                               as DEPENDENCY,
       type                                                                                                as REF_TYPE,
       owner || '.' || name                                                                                as REFERENCING_OBJ
       , (select status || ' ' || to_char(last_ddl_time,'dd.mm.yyyy hh24:mi:ss')
            from dba_objects o
           where d.owner = o.owner
             and d.name = o.object_name
             and d.type = o.object_type)                                                                   as "STATUS___LAST_DDL_TIME"
  from dba_dependencies d
connect by nocycle prior type  = decode(referenced_type, 'TABLE', 'MATERIALIZED VIEW', referenced_type)
               and prior owner = referenced_owner
               and prior name  = referenced_name
 start with (referenced_owner, referenced_name) in ((upper('&1'), upper('&2')))
/
set feedback on echo off VERIFY ON serveroutput off