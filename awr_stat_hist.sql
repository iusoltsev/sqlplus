--
-- ASH Statistics History
-- Usage: SQL> @awr_stat_hist "data blocks consistent reads - undo records applied" 302770 302780
--                              ^event                           ^start_snap_id ^finish_snap_id
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col SNAP_ID for 9999999
col EVENT for a64
col VALUE for a20

select 
 INST_ID,
 SNAP_ID,
 BEGIN_INTERVAL_TIME,
 EVENT,
 to_char(VALUE,'999,999,999,999,999') as VALUE
from (
      select
       nvl(inst_id, 0) as inst_id,
       snap_id,
       begin_interval_time,
       event,
       sum(waits) as value
      from (
      select
          instance_number as INST_ID,
          snap_id,
          to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
          stat_name as EVENT,
          case WHEN (LEAD(value,1) over (PARTITION BY instance_number ORDER BY snap_id) <= value)
                    THEN null
                    ELSE (LEAD(value,1) over (PARTITION BY instance_number ORDER BY snap_id) - value)
               END as WAITS
      from dba_hist_sysstat hss
           join dba_hist_snapshot sna using(snap_id, instance_number)
           where stat_name = '&1'
           and ('&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
        order by 2 desc, 1
      ) where WAITS is not null
      --and inst_id is null
      group by --rollup(
inst_id
--)
, snap_id, begin_interval_time, event
     ) 
--where inst_id = 0
  order by 2 desc, 1 nulls last
/

set feedback on echo off VERIFY ON