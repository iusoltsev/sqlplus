--
-- Redo generation SQL top estimation from AWR history
-- Usage: SQL> @redogen_sql_hist "03-Sep-13 16:00" "03-Sep-13 17:00" 10
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col WHEN for a34
col INST_ID for 9999999
col COMMAND for a20
col SQL_ID for a13
col SQL_TEXT for a100
col buffer_gets_range for a12

select * from (
SELECT 
      dhss.instance_number inst_id,
      to_char(min(begin_interval_time),'DD-Mon-YY HH24:MI') || ' - ' ||
      to_char(max(end_interval_time),'DD-Mon-YY HH24:MI') as WHEN,
--      dhcn.command_name as COMMAND,					-- 11.2+
      sum(executions_delta) exec_delta,
      sum(rows_processed_delta) rows_proc_delta,
      sum(dhss.buffer_gets_delta) buffer_gets_delta,
      ROW_NUMBER () OVER (ORDER BY sum(dhss.buffer_gets_delta) DESC) as buffer_range,
      dhss.sql_id,
      replace(dbms_lob.substr(sql_text, 100, 1),chr(10),' ') sql_text
 FROM dba_hist_sqlstat dhss,
      dba_hist_snapshot dhs,
      dba_hist_sqltext dhst
--     ,dba_hist_sqlcommand_name dhcn                                   -- 11.2+
WHERE dhst.command_type not in (3,47) -- != SELECT, PL/SQL EXECUTE
  AND dhss.snap_id = dhs.snap_id
  AND dhss.instance_Number = dhs.instance_number
  AND dhss.sql_id = dhst.sql_id
--  and dhst.command_type = dhcn.command_type                           -- 11.2+
  AND begin_interval_time BETWEEN to_date('&1', 'DD-Mon-YY HH24:MI')
                              AND to_date('&2', 'DD-Mon-YY HH24:MI')
GROUP BY 
--       dhcn.command_name,                                             -- 11.2+
         replace(dbms_lob.substr(sql_text, 100, 1),chr(10),' '),
         dhss.instance_number,
         dhss.sql_id
--order by buffer_gets_delta desc, rows_proc_delta desc
order by rows_proc_delta desc nulls last, buffer_gets_delta desc
) where rownum <= &3
/

set feedback on echo off VERIFY ON