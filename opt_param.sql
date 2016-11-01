set verify off
select * from V$SES_OPTIMIZER_ENV where sid = sys_context('USERENV', 'SID') and upper(name) like upper('%&&1%')
/
select * from V$session_Fix_Control where session_id = sys_context('USERENV', 'SID') and (upper(description) like upper('%&&1%') or BUGNO like upper('%&&1%'))
/
set verify on