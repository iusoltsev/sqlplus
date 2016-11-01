--
-- AWR Latch History
-- Usage: SQL> @awr_latch_hist "redo copy" [11111          [22222]]
--                              ^latch_name ^start_snap_id ^finish_snap_id
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID          for 9999999
col SNAP_ID          for 9999999
col LATCH_NAME       for a64
col GETS             for a20
col IMMEDIATE_GETS   for a20
col IMMEDIATE_MISSES for a20

select 
 INST_ID,
 SNAP_ID,
 BEGIN_INTERVAL_TIME,
 LATCH_NAME,
 to_char(gets,'999,999,999,999,999')             as GETS,
 to_char(immediate_gets,'999,999,999,999,999')   as IMMEDIATE_GETS,
 to_char(immediate_misses,'999,999,999,999,999') as IMMEDIATE_MISSES
from (select
          instance_number as INST_ID,
          snap_id,
          to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
          latch_name as latch_name,
          case WHEN (LEAD(gets,1) over (PARTITION BY instance_number ORDER BY snap_id) <= gets)
                    THEN null
                    ELSE (LEAD(gets,1) over (PARTITION BY instance_number ORDER BY snap_id) - gets)
               END as gets,
          case WHEN (LEAD(immediate_gets,1) over (PARTITION BY instance_number ORDER BY snap_id) <= immediate_gets)
                    THEN null
                    ELSE (LEAD(immediate_gets,1) over (PARTITION BY instance_number ORDER BY snap_id) - immediate_gets)
               END as immediate_gets,
          case WHEN (LEAD(immediate_misses,1) over (PARTITION BY instance_number ORDER BY snap_id) <= immediate_misses)
                    THEN null
                    ELSE (LEAD(immediate_misses,1) over (PARTITION BY instance_number ORDER BY snap_id) - immediate_misses)
               END as immediate_misses
      from dba_hist_latch hss
           join dba_hist_snapshot sna using(snap_id, instance_number)
           where latch_name = '&1'
           and ('&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
and instance_number = 1
        order by 2 desc, 1
      )
  order by 2 desc, 1 nulls last
/

set feedback on echo off VERIFY ON