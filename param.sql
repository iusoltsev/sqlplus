SET VERIFY OFF
set linesize 200
set pagesize 200
column name format a42
column value format a40
column dsc format a84
column is_def format a8
column is_mod format a10
column is_adj format a8

select name,
       value,
       isdefault is_def,
       ismodified is_mod,
       description dsc
  from V$PARAMETER
 where name like lower('%'||'&&1'||'%')
    OR lower(description) like lower('%'||'&&1'||'%')
    OR lower(to_char(value)) like lower('%'||'&&1'||'%')
order by name
/
SET VERIFY ON