--
-- Create SQL Patch for given sql_id
-- Usage: SQL> @sqlpatch- "da0qdhtw4mhqh_NO_ADAPT" da0qdhtw4mhqh
--

set echo off feedback on heading on VERIFY OFF serveroutput on
col sql_id for a13
col name for a30
col category for a30
col sql_text for a60
col created for a21
col last_modified for a21
col description for a40
col status for a8
col force_matching for a5

begin
  dbms_sqldiag.drop_sql_patch('&1', ignore => TRUE);
end;
/

prompt
prompt SPM Elements (SQL Profile, or SQL Plan Baseline, or SQL Patch) List for SQL_ID = &&2

@@spm_check4sql_id &&2

set feedback on echo off VERIFY ON serveroutput off