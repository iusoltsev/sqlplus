set verify off
select * from v$session_fix_control where session_id = sys_context('USERENV', 'SID') and bugno = &&1
/
set verify on