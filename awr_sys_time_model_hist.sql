--
-- ASH Time Model History
-- Usage: SQL> @awr_sys_time_model_hist "DB time" [67215           [67220]]
--                                       ^StatName ^start_snap_id   ^finish_snap_id
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col SNAP_ID for 9999999
col STAT_NAME for a64
col VALUE for a20

select 
 INST_ID,
 SNAP_ID,
 BEGIN_INTERVAL_TIME,
 STAT_NAME,
 to_char(VALUE,'999,999,999,999,999') as VALUE
from (
select
    instance_number as "INST_ID",
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    stat_name,
    case WHEN (LEAD(hst.value,1) over (PARTITION BY instance_number, stat_name ORDER BY snap_id) <= hst.value)
              THEN 0
              ELSE (LEAD(hst.value,1) over (PARTITION BY instance_number, stat_name ORDER BY snap_id) - hst.value)
         END as VALUE
from dba_hist_sys_time_model hst
     join dba_hist_snapshot sna using(snap_id, instance_number)
          where stat_name = '&1'
           and ('&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
  order by 2,1
	    ) where VALUE is not null
/

set feedback on echo off VERIFY ON