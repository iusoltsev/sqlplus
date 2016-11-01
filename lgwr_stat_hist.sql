--
-- LGWR events and stat history
-- Usage: SQL> @lgwr_stat_hist [80300]        [80315]         [2]
--                             ^start snap_id ^finish snap_id ^instance number
--

break ON EVENT_NAME ON EVENT_NAME2
col EVENT_NAME for a13
col EVENT_NAME2 for a23
col REDO_SIZE for 999,999,999,999
col LOG_BUFFER for 999,999,999,999
col REDO_SIZE_PER_ENTRY for 999,999,999,999
set feedback off heading on timi off pages 1000 lines 500 verify off

with stat as (
select--+ materialize
    instance_number,
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    hse.event_name,
    case WHEN (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse.total_waits)
              THEN null
              ELSE (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse.total_waits)
         END as AVG_WAITS,
    case WHEN (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse.total_waits)
              THEN null
              ELSE round((LEAD(hse.time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse.time_waited_micro)
                        / (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse.total_waits))
         END as "AVG_TIME_nS",
    hse2.event_name as event_name2,
    case WHEN (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse2.total_waits)
              THEN null
              ELSE (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse2.total_waits)
         END as AVG_WAITS2,
    case WHEN (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse2.total_waits)
              THEN null
              ELSE round((LEAD(hse2.time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse2.time_waited_micro)
                        / (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse2.total_waits))
         END as "AVG_TIME_nS2",
    case WHEN (LEAD(hst.value,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hst.value)
              THEN null
         ELSE round((LEAD(hst.value,1) over (PARTITION BY instance_number ORDER BY snap_id) - hst.value))
         END as REDO_ENTRIES,
    case WHEN (LEAD(hst2.value,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hst2.value) THEN null
         ELSE round((LEAD(hst2.value,1) over (PARTITION BY instance_number ORDER BY snap_id) - hst2.value)) END as REDO_SIZE,
    hpa.value as LOG_BUFFER
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     join dba_hist_system_event hse2 using(snap_id, instance_number)
     join dba_hist_sysstat hst using(snap_id, instance_number)
     join dba_hist_sysstat hst2 using(snap_id, instance_number)
     join dba_hist_parameter hpa using(snap_id, instance_number)
     where snap_id between nvl('&1', snap_id) and nvl('&2', snap_id)
       and hse.event_name  = 'log file sync'
       and hse2.event_name = 'log file parallel write'
       and hst.stat_name   = 'redo entries'
       and hst2.stat_name  = 'redo size'
       and hpa.parameter_name = 'log_buffer'
)
select
--    instance_number as INST_ID,
    snap_id,
    begin_interval_time,
    event_name,
    AVG_WAITS as LOG_SYNC_WAITS,
    "AVG_TIME_nS",
    REDO_ENTRIES,
    REDO_SIZE,
    round(REDO_SIZE/REDO_ENTRIES) as REDO_SIZE_PER_ENTRY,
    event_name2,
    AVG_WAITS2 as LOG_WRITE_WAITS,
    "AVG_TIME_nS2",
    round(REDO_SIZE/AVG_WAITS) as REDO_SIZE_PER_LG_WRITE,
    to_number(LOG_BUFFER) as LOG_BUFFER
from stat
where nvl('&3', instance_number) = instance_number
  and AVG_WAITS is not null
  order by 1
/
set feedback on verify on timi on
