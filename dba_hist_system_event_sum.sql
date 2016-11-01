select * from (
select
    instance_number as "INST_ID",
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits)
         END as WAIT_COUNT,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_nS
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where &1
  order by 2,1
	    ) where WAIT_COUNT is not null
/