--
-- SQL AWR Top by metric based on SYSTEM.PKG_INFR_SESS_MANAGE package
-- Usage: SQL> @SQL_AWR_TOP_BY_METRIC "disk_reads" "10.07.2018 13:00" "10.07.2018 13:30"
--                                     ^ elapsed_time, cpu_time, disk_reads, buffer_gets, parse_calls, iowait, clwait, apwait, ccwait, direct_writes

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col EVENT for a58
col PROGRAMS for a60 HEADING 'PROGRAMS BY TYPES                                           '
col t0 for 999
col t1 for 999
col t2 for 999
col t3 for 999
col t4 for 999
col t5 for 999
col t6 for 999
col t7 for 999
col t8 for 999
col t9 for 999

SELECT * from table(SYSTEM.PKG_INFR_SESS_MANAGE.SF_TOP_BY_METRIC(
  '&1',
-- elapsed_time, cpu_time, disk_reads, buffer_gets, parse_calls, iowait, clwait, apwait, ccwait, direct_writes
  to_date('&2', 'dd.mm.yyyy hh24:mi'),
  to_date('&3', 'dd.mm.yyyy hh24:mi')
))
/
set feedback on echo off VERIFY ON