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
, to_char(RATIO_TO_REPORT(sum(sev.TIME_WAITED_micro) - nvl(sum(gev.TIME_WAITED_micro),0)) OVER() * 100, '990.99') AS WAIT_TIME_PCT
  from v$session_event sev left join gtt$session_event gev using (EVENT, wait_class)
 where sev.sid in (select sid from v$px_session where qcsid = &&1 and sid <> qcsid
                   union all
                   select &&1 from dual)
   and wait_class <> 'Idle'
 group by EVENT, wait_class
--having (sum(sev.TOTAL_WAITS) - nvl(sum(gev.TIME_WAITED_micro),0)) > 0--not return!!!
--   and (sum(sev.TOTAL_WAITS)       - nvl(sum(gev.TOTAL_WAITS),0)) > 0
 order by (sum(sev.TIME_WAITED_micro) - nvl(sum(gev.TIME_WAITED_micro),0)) desc
/
prompt
prompt
set VERIFY ON timi on