--
-- ASH Waits Event History
-- Usage: SQL> @awr_event_hist "direct path read temp" 59310          59316
--                              ^event                 ^start_snap_id ^finish_snap_id
-- http://iusoltsev.wordpress.com
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col SNAP_ID for 9999999
col EVENT for a64
col WAITS for 99999999
col AVG_WAIT_TIME_nS for 99999999

select * from (
select
    instance_number as INST_ID,
    snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name as EVENT,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits)
         END as WAITS,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits))
         END as "AVG_WAIT_TIME_nS"
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where event_name = '&1'
     and ('&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
--     and instance_number = NVL(to_number(&&4), instance_number)
  order by 2 desc, 1
) where WAITS is not null or "AVG_WAIT_TIME_nS"  is not null
/

/* Comparision???
select * from
(select
    instance_number as INST_ID,
    snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    decode(event_name, 'log file parallel write', event_name, null) as EVENT1,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - decode(event_name, 'log file parallel write', total_waits, null))
         END as WAITS1,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - decode(event_name, 'log file parallel write', total_waits, null)))
         END as "AVG_WAIT_TIME_nS1",
    decode(event_name, 'direct path write temp', event_name, null) as EVENT2,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - decode(event_name, 'direct path write temp', total_waits, null))
         END as WAITS2,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - decode(event_name, 'direct path write temp', total_waits, null)))
         END as "AVG_WAIT_TIME_nS2"
 from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where event_name in ('log file parallel write','direct path write temp')
--     and ('&&3' is null OR snap_id between '&&3' and nvl('&&4', '&&3'))
and snap_id between 59400 and 59500
  order by 2 desc, 1
) where (WAITS1 is not null or "AVG_WAIT_TIME_nS1" is not null)
     or (WAITS2 is not null or "AVG_WAIT_TIME_nS2" is not null)
*/

set feedback on echo off VERIFY ON