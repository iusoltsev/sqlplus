set verify off

col name for a40
col SQL_FEATURE for a24
col CLASS for a40
col INVERSE for a64
col TLVL for 9999
col PROP for 9999
col version for a16
col version_outline for a16

select name,
       sql_feature,
       class,
       inverse,
       target_level as TLVL,
       property as PROP,
       version,
       version_outline
  from v$sql_hint
 where name like '%'||upper('&&1')||'%'
/

set verify on