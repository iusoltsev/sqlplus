CREATE OR REPLACE PROCEDURE system.TEMP_TEMP_SEG_USAGE_INSERT IS
BEGIN
  insert into SYSTEM.TEMP_TEMP_SEG_USAGE
    SELECT sysdate,
           NVL(a.username, 'SUMMARY'),
           a.sid,
           a.serial#,
           a.osuser,
           a.program,
           a.sql_id,
           a.sql_child_number,
           a.sql_exec_start,
           q.plan_hash_value,
           b.tablespace,
           b.segtype,
           sum(b.blocks) as BLOCKS,
           q.sql_text
      FROM gv$session a, gv$tempseg_usage b, gv$sql q
     WHERE a.saddr = b.session_addr
       and q.address = a.sql_address
       and q.inst_id = a.inst_id
       and q.hash_value = a.sql_hash_value
       and q.CHILD_NUMBER = a.SQL_CHILD_NUMBER
       and a.INST_ID = b.INST_ID
     GROUP by GROUPING SETS((a.sid, a.username, a.serial#, a.osuser, a.program, a.sql_id, a.sql_child_number, a.sql_exec_start, q.sql_text, q.plan_hash_value, b.tablespace, b.segtype, sysdate),(sysdate));
  COMMIT;
END;
/