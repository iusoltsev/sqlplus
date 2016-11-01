--
-- 2find SQL text
-- Usage: SQL> @sql_id &sqlid
--

set verify off lines 200

col sql_fulltext for a100
col sql_id for a13

select distinct sql_id, dbms_lob.substr(sql_fulltext, 4000) as sql_fulltext
  from gv$sqlarea a
 where sql_id = '&&1'
union
select distinct sql_id, dbms_lob.substr(h.sql_text, 4000) as sql_fulltext
  from dba_hist_sqltext h
 where sql_id = '&&1'
/
set verify on