set verify off

rem col DESCRIPTION for a80
col SQL_FEATURE for a40

select *
  from v$session_fix_control
 where session_id = sys_context('USERENV', 'SID')
   and (upper(description) like '%'||upper('&&1')||'%'
        or sql_feature     like '%'||upper('&&1')||'%'
        or to_char(bugno)  like '%'||upper('&&1')||'%')
order by
      to_number(regexp_substr(OPTIMIZER_FEATURE_ENABLE,'([^.]+).?',1,1,'i',1)),
      to_number(regexp_substr(OPTIMIZER_FEATURE_ENABLE,'.?([^.]+).?',1,2,'i',1)),
      to_number(regexp_substr(OPTIMIZER_FEATURE_ENABLE,'.?([^.]+).?',1,3,'i',1)),
      to_number(regexp_substr(OPTIMIZER_FEATURE_ENABLE,'.?([^.]+).?',1,4,'i',1))
/
set verify on