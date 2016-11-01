--
-- ASH Statistics History
-- Usage: SQL> @awr_param_hist log_buffer [14450         [14524]]
--                             ^param      ^start_snap_id ^finish_snap_id
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col SNAP_ID for 9999999
col EVENT for a64
col VALUE for a20

select instance_number as INST_ID,
       snap_id,
       end_interval_time as BEGIN_INTERVAL_TIME,
       to_char(VALUE,'999,999,999,999,999') as VALUE
  from dba_hist_parameter
  join dba_hist_snapshot sna
 using (snap_id, instance_number)
 where parameter_name = '&&1'
   and ('&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))
 order by snap_id, instance_number
/

set feedback on echo off VERIFY ON