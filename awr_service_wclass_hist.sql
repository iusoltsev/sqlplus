--
-- ASH Service Waits Class History
-- Usage: SQL> @awr_service_wclass_hist "wait_class = 'User I/O' and snap_id > 54700 and service_name like 'SYS$%'"
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col SNAP_ID for 9999999
col EVENT for a64
col WAITS for 99999999
col AVG_WAIT_TIME_mS for 99999999

select INST_ID,
       SNAP_ID,
       BEGIN_INTERVAL_TIME,
       SERVICE_NAME,
       WAIT_CLASS,
       sum(WAITS) as WAITS, round(sum(AVG_WAIT_TIME_mS*WAITS)/sum(WAITS)) as AVG_WAIT_TIME_mS
 from (
select
    instance_number as INST_ID,
    snap_id,
    to_char(begin_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    service_name,
    wait_class,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, service_name, wait_class ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number, service_name, wait_class ORDER BY snap_id) - total_waits)
         END as WAITS,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, service_name, wait_class ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited,1) over (PARTITION BY instance_number, service_name, wait_class ORDER BY snap_id) - time_waited)*10
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number, service_name, wait_class ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_mS
from dba_hist_service_wait_class hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where &1
)
 where (WAITS is not null or AVG_WAIT_TIME_mS  is not null) and wait_class <> 'Idle'
  group by INST_ID,
           snap_id,
           begin_interval_time,
           rollup(service_name),
           wait_class
 order by 2 desc, 1, 4 nulls last, 5 nulls last
/

set feedback on echo off VERIFY ON