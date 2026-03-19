-- for ORA-04061_existing_state_of_package__APPS_FND_PROFILE__has_been_invalidated dignostics
-- SQL> @dba_obj_mtime APPS FND% 30
-- Check for last      ^ days

SET VERIFY OFF echo off
col OWNER         for a30
col OBJECT_NAME   for a30
col LAST_DDL_TIME for a20
col MTIME         for a20

select * from 
 (select OWNER, OBJECT_NAME, OBJECT_TYPE
 , (select max(MTIME) from obj$ where DATAOBJ# = o.object_id) as MTIME
 , LAST_DDL_TIME, TIMESTAMP, STATUS
  from dba_objects o where object_name like '&2' and owner = '&1')
where MTIME > LAST_DDL_TIME
  and MTIME > sysdate - &3
/
SET VERIFY on echo on