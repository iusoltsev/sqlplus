--
-- Current session cumulative waits
-- Usage: SQL> @my_waits
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col event          for a60
col wait_class     for a30
col waits          for 999,999,999
col time_waited_cs for 999,999,999
col avg_wait_cs    for 990.999

select event,
       wait_class,
       sum(total_waits)  as waits,
       sum(time_waited)  as time_waited_cs,
       avg(average_wait) as avg_wait_cs
  from V$session_event
 where sid = sys_context('USERENV', 'SID')
   and wait_class <> 'Idle'
 group by event, wait_class
 having sum(time_waited) > 0
 order by 4 desc
/
set feedback on echo off VERIFY ON