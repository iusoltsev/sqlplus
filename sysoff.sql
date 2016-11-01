--
-- System query statistics
-- Usage:
-- SQL> @sys_on
-- SQL> @sysoff "log file"
--

col name for a64
col delta for 999999999999
col waits for 999999999999
col time_ms for 999999999999
col TIMEOUTS for 999999999999
col avg_wait_ms for 999,999

set pagesize 1000 feedback off VERIFY OFF timi off

prompt
prompt
prompt System Time Model

select * from (
select stm.stat_name, sum(stm.value) - nvl(sum(gtm.value),0) as delta
  from v$sys_time_model stm left join gtt$sys_time_model gtm using (stat_id)
 group by stm.stat_name
having sum(stm.value) - nvl(sum(gtm.value),0) > 0
 order by 2 desc
) where upper(stat_name) like upper('%&&1%')
/

prompt
prompt
prompt System Statistics

select * from (
select --+ RULE
 v$statname.name, sum(sst.value) - nvl(sum(gst.value),0) as delta
  from v$sysstat sst
       join v$statname using (statistic#)
       left join gtt$sysstat gst using (statistic#)
 group by v$statname.name, gst.value
having sum(sst.value) - nvl(sum(gst.value),0) > 0
 order by 2 desc
) where upper(name) like upper('%&&1%')
/

prompt
prompt
prompt System Wait Events

select * from (
select EVENT as name,
       wait_class,
       sum(sev.TOTAL_WAITS)              - nvl(sum(gev.TOTAL_WAITS),0)                as WAITS,
       round((sum(sev.TIME_WAITED_micro) - nvl(sum(gev.TIME_WAITED_micro),0)) / 1000) as TIME_MS,
       sum(sev.TOTAL_TIMEOUTS)           - nvl(sum(gev.TOTAL_TIMEOUTS),0)             as TIMEOUTS,
       round((sum(sev.TIME_WAITED_micro) - nvl(sum(gev.TIME_WAITED_micro),0)) / 1000 /
             decode((sum(sev.TOTAL_WAITS)- nvl(sum(gev.TOTAL_WAITS),0))
                   , 0, 1
                   ,(sum(sev.TOTAL_WAITS)    - nvl(sum(gev.TOTAL_WAITS),0)))
         , 1)                                                                         as AVG_WAIT_MS
  from v$system_event sev left join gtt$system_event gev using (EVENT, wait_class)
 group by EVENT, wait_class
having (sum(sev.TOTAL_WAITS) - nvl(sum(gev.TIME_WAITED_micro),0)) > 0
--   and (sum(sev.TOTAL_WAITS)       - nvl(sum(gev.TOTAL_WAITS),0)) > 0
 order by (sum(sev.TIME_WAITED_micro) - nvl(sum(gev.TIME_WAITED_micro),0)) desc
) where upper(name) like upper('%&&1%')
/
prompt
prompt
set VERIFY ON timi on