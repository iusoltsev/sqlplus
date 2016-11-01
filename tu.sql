col INST_ID for a7
col USERNAME for a8
col SQL_ID for a13
col TEXT80 for a80
col CONTENTS for a20 just l
col SEGTYPE for a20

select tu.INST_ID,
       tu.USERNAME,
       NVL(s.SQL_ID, s.prev_sql_id) SQL_ID,
       substr(rpad(sa.SQL_TEXT, 80, '*'), 1, 80) as TEXT80,
       tu.CONTENTS,
       tu.SEGTYPE,
       count(distinct tu.SESSION_ADDR) PROC_COUNT,
       round(sum(tu.BLOCKS * t.BLOCK_SIZE) / 1024 / 1024) size_MB
  from gv$tempseg_usage tu, gv$session s, dba_tablespaces t, gv$sqlarea sa
 where tu.SESSION_ADDR = s.SADDR
   and tu.INST_ID = s.INST_ID
   and s.SQL_ID = sa.SQL_ID
   and s.INST_ID = sa.INST_ID
   and tu.TABLESPACE = t.TABLESPACE_NAME
 group by tu.INST_ID,
          tu.USERNAME,
          NVL(s.SQL_ID, s.prev_sql_id),
          substr(rpad(sa.SQL_TEXT, 80, '*'), 1, 80),
          tu.CONTENTS,
          tu.SEGTYPE
 order by sum(tu.BLOCKS) desc
/