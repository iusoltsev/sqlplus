--
-- Session query statistics
-- Usage:
-- SQL> @sesson &SID
-- SQL> @sessof
--
-- For summary (QC+PX) execution only stats (without fetch stats):
-- SQL> set pages 1 pau on
--
-- For summary execution and fetch stats:
-- SQL> set pages 0 arraysize 5000
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
prompt Session Time Model

select stm.stat_name, sum(stm.value) - nvl(sum(gtm.value),0) as delta
  from v$sess_time_model stm left join gtt$sess_time_model gtm using (stat_id)
 where stm.sid in (select sid from v$px_session where qcsid = &&1 and sid <> qcsid
                   union all
                   select &&1 from dual)
 group by stm.stat_name
having sum(stm.value) - nvl(sum(gtm.value),0) > 0
 order by 2 desc
/

prompt
prompt
prompt Session Statistics

select --+ RULE
 v$statname.name, sum(sst.value) - nvl(sum(gst.value),0) as delta
  from v$sesstat sst
       join v$statname using (statistic#)
       left join gtt$sesstat gst using (statistic#)
 where sst.sid in (select sid from v$px_session where qcsid = &&1 and sid <> qcsid
                   union all
                   select &&1 from dual)
 group by v$statname.name, gst.value
having sum(sst.value) - nvl(sum(gst.value),0) > 0
 order by 2 desc
/

prompt
prompt
prompt Session Wait Events

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
  from v$session_event sev left join gtt$session_event gev using (EVENT, wait_class)
 where sev.sid in (select sid from v$px_session where qcsid = &&1 and sid <> qcsid
                   union all
                   select &&1 from dual)
   and wait_class <> 'Idle'
 group by EVENT, wait_class
having (sum(sev.TOTAL_WAITS) - nvl(sum(gev.TIME_WAITED_micro),0)) > 0
--   and (sum(sev.TOTAL_WAITS)       - nvl(sum(gev.TOTAL_WAITS),0)) > 0
 order by (sum(sev.TIME_WAITED_micro) - nvl(sum(gev.TIME_WAITED_micro),0)) desc
/
prompt
prompt
set VERIFY ON timi on