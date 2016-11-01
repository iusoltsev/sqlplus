undef 1
col cache_id for a30
col cache_key for a30
col name for a30

SELECT inst_id,
       id,
       cache_id,
       cache_key,
       status,
       name,
       namespace as SPACE,
       to_char(creation_timestamp,'dd.mm.yyyy hh24:mi:ss') as timestamp,
       depend_count,
       block_count,
       column_count,
       scan_count,
       row_count,
       build_time,
       space_unused,
       space_overhead
  FROM GV$RESULT_CACHE_OBJECTS
WHERE CACHE_ID like nvl('%'||'&&1'||'%','%')
/