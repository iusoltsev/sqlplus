--
-- Full dependency tree for db object
-- Usage: SQL> @dep_tree SCOTT EMP
--

set echo off feedback off heading on VERIFY OFF serveroutput on
alter session set nls_date_format='dd.mm.yyyy hh24:mi:ss'
/
select * from (
select level,
       lpad('  ', 2 * (level - 1)) || type || ' ' || owner || '.' || name   as DEP_TREE,
       lpad('>', level, '>')                                                as DEPENDENCY,
       referenced_type,
       referenced_owner || '.' || referenced_name as REFERENCED_OBJ
       , (select last_ddl_time
            from dba_objects o
           where d.referenced_owner = o.owner
             and d.referenced_name = o.object_name
             and d.referenced_type = o.object_type) as LAST_DDL_TIME
  from dba_dependencies d
connect by nocycle type = prior decode(referenced_type, 'TABLE', 'MATERIALIZED VIEW', referenced_type)
       and owner        = prior referenced_owner
       and name         = prior referenced_name
-- start with (owner, name) in ((upper('&1'), upper('&2'))
 start with owner = upper('&1') and name = upper('&2')
) &3
/
set feedback on echo off VERIFY ON serveroutput off