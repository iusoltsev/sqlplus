--
-- Hint.sql script based on
--                          hinth.sql by Tanel Poder
--                          http://orasql.org/2019/05/28/vsql_hint-target_level/
-- Usage:       @hint <hint_name_part>
--              @hint MERG
--
set verify off

col name for a40
col SQL_FEATURE for a80
col CLASS for a40
col INVERSE for a64
col TLVL for 9999
col PROP for 9999
col version for a16
col version_outline for a16

WITH fh AS (
SELECT 
    f.sql_feature
  , SYS_CONNECT_BY_PATH(REPLACE(f.sql_feature, 'QKSFM_', ''), ' -> ') path
FROM 
    v$sql_feature f
  , v$sql_feature_hierarchy fh 
WHERE 
    f.sql_feature = fh.sql_feature 
CONNECT BY fh.parent_id = PRIOR f.sql_Feature 
START WITH fh.sql_feature = 'QKSFM_ALL'
)
select name,
       REGEXP_REPLACE(fh.path, '^ -> ', '')        sql_feature,
       class,
       inverse,
       target_level                                TLVL,
       property                                    PROP,
       version,
       version_outline
      ,decode(bitand(target_level,1),0,'no','yes') Statement_level
      ,decode(bitand(target_level,2),0,'no','yes') Query_block_level
      ,decode(bitand(target_level,4),0,'no','yes') Object_level
      ,decode(bitand(target_level,8),0,'no','yes') Join_level
  from v$sql_hint hi
     , fh
 where (hi.name like '%'||upper('&&1')||'%'
        or path like '%'||upper('&&1')||'%')
   and hi.sql_feature = fh.sql_feature
order by 1
/
set verify on