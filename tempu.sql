SELECT sysdate,
       a.inst_id,
       NVL(a.username, 'SUMMARY'),
       a.sid,
       a.serial#,
       a.osuser,
       a.program,
       a.sql_id,
       a.sql_exec_id,
       a.sql_exec_start,
       a.sql_child_number,
       q.plan_hash_value,
       b.tablespace,
       b.segtype,
       sum(b.blocks) as BLOCKS,
       trim(replace(replace(replace(q.sql_text ,chr(10)),chr(13)),chr(9))) as sql_text
  FROM gv$session a, gv$tempseg_usage b, gv$sql q
 WHERE a.saddr = b.session_addr
   and q.address = a.sql_address
   and q.inst_id = a.inst_id
   and q.hash_value = a.sql_hash_value
   and q.CHILD_NUMBER = a.SQL_CHILD_NUMBER
   and a.INST_ID = b.INST_ID
 GROUP by GROUPING SETS((a.inst_id, a.sid, a.username, a.serial#, a.osuser, a.program, a.sql_id, a.sql_exec_id, a.sql_child_number, a.sql_exec_start, trim(replace(replace(replace(q.sql_text ,chr(10)),chr(13)),chr(9))), q.plan_hash_value, b.tablespace, b.segtype, sysdate),(sysdate),(a.inst_id))
order by BLOCKS desc
/
select inst_id, round(sum(bytes_used)/1024/1024/1024) as bytes_used_GB, round(sum(bytes_cached)/1024/1024/1024) as bytes_cached
  from gv$temp_extent_pool
 where tablespace_name = 'TEMP'
 group by inst_id
/
