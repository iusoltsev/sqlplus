select * from (
select
    instance_number as "INST_ID",
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    stat_name,
    case WHEN (LEAD(value,1) over (PARTITION BY instance_number, stat_name ORDER BY snap_id) <= value)
              THEN null
              ELSE (LEAD(value,1) over (PARTITION BY instance_number, stat_name ORDER BY snap_id) - value)
         END as "Value"
from dba_hist_sys_time_model hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where &1 -- stat_name = 'DB time' and instance_number = 1 --
  order by 2,1
      ) where WAIT_COUNT is not null
/
