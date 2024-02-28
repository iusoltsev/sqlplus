col INST_ID for  a7
col USERNAME for a30
col CLIENT_ID for a40
set pages 100

SELECT s.inst_id,
       to_char(RATIO_TO_REPORT(sum(pga_alloc_mem)) OVER(partition by s.inst_id)   * 100, '990.99') AS "alloc%",
       s.username,
       REGEXP_SUBSTR(client_identifier, '.+\#') as CLIENT_ID,
       nvl(s.sql_id, s.PREV_SQL_ID) as sql_id,
       ROUND(sum(pga_used_mem) / 1024 / 1024) Used_MB,
       ROUND(sum(pga_alloc_mem) / 1024 / 1024) Alloc_MB,
       ROUND(sum(pga_freeable_mem) / 1024 / 1024) Freeable_MB,
       ROUND(sum(pga_max_mem) / 1024 / 1024) Max_MB,
       count(distinct s.inst_id || '*' || s.sid) as sids,
       trim(replace(replace(replace(dbms_lob.substr(a.sql_text, 100), chr(10)), chr(13)), chr(9))) as sql_text
  FROM gv$session s
  join gv$process p
    on p.addr = s.paddr
   and p.inst_id = s.inst_id
  left join gv$sqlarea a
    on nvl(s.sql_id, s.PREV_SQL_ID) = a.sql_id
   and a.inst_id = s.inst_id
 group by s.inst_id,
          s.username,
          REGEXP_SUBSTR(client_identifier, '.+\#'),
          nvl(s.sql_id, s.PREV_SQL_ID),
          trim(replace(replace(replace(dbms_lob.substr(a.sql_text, 100), chr(10)), chr(13)), chr(9)))
 ORDER BY sum(pga_alloc_mem) desc
fetch first &1 rows only
/