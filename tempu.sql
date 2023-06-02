col SQL_TEXT for a100
col USERNAME for a30
col OSUSER   for a20
SELECT--+ ordered
       sysdate,
       a.inst_id,
       NVL(a.username, 'SUMMARY') as username,
--       a.sid,
--       a.serial#,
       a.osuser,
--       a.program,
       a.sql_id,
       a.sql_child_number as child,
       q.plan_hash_value,
       a.sql_exec_id,
       a.sql_exec_start,
       b.tablespace,
       b.segtype,
       sum(b.blocks) as BLOCKS,
       count(distinct a.sid||a.serial#) as SIDS,
       substr(trim(replace(replace(replace(q.sql_text ,chr(10)),chr(13)),chr(9))),1,100) as sql_text
  FROM gv$tempseg_usage b, gv$session a, gv$sql q
 WHERE a.saddr = b.session_addr
   and q.address = a.sql_address
   and q.inst_id = a.inst_id
   and q.hash_value = a.sql_hash_value
   and q.CHILD_NUMBER = a.SQL_CHILD_NUMBER
   and a.INST_ID = b.INST_ID
 GROUP by GROUPING SETS((a.inst_id--, a.sid
 , a.username--, a.serial#
 , a.osuser--, a.program
 , a.sql_id, a.sql_exec_id, a.sql_child_number, a.sql_exec_start, substr(trim(replace(replace(replace(q.sql_text ,chr(10)),chr(13)),chr(9))),1,100), q.plan_hash_value, b.tablespace, b.segtype, sysdate),(sysdate),(a.inst_id))
order by BLOCKS desc
fetch first 10 rows only
/
pro -------------------
pro gv$temp_extent_pool
select tablespace_name, inst_id, round(sum(bytes_used)/1024/1024/1024) as bytes_used_GB, round(sum(bytes_cached)/1024/1024/1024) as bytes_cached
  from (select distinct file_id, tablespace_name, inst_id, bytes_used, bytes_cached from gv$temp_extent_pool)--dubbles???
 group by tablespace_name, inst_id
order by 1,2
/
pro ------------------
pro gv$temp_extent_map
select tablespace_name,
       inst_id,
       owner,
       round(sum(bytes) / 1024 / 1024 / 1024) as sum_bytes_gb
  from gv$temp_extent_map--(select distinct tablespace_name, inst_id, owner, bytes from gv$temp_extent_map)--dubbles???
 group by inst_id, owner, tablespace_name
 order by 1,2,3
/
