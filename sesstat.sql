--
-- Session statistics
-- Usage:
-- SQL> connect ...
-- SQL> select ...
-- SQL> @sesstat
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

select stm.stat_name, sum(stm.value) delta
  from v$sess_time_model stm
 where stm.sid in (select sid from v$px_session where qcsid = SYS_CONTEXT('USERENV', 'SID') and sid <> qcsid
                   union all
                   select to_number(SYS_CONTEXT('USERENV','SID')) from dual)
   and stm.value > 0
 group by stm.stat_name
 order by 2 desc
/

prompt
prompt
prompt Session Statistics

select --+ RULE
 v$statname.name, sum(sst.value) as delta
  from v$sesstat sst, v$statname
 where sst.sid in (select sid from v$px_session where qcsid = SYS_CONTEXT('USERENV', 'SID') and sid <> qcsid
                   union all
                   select to_number(SYS_CONTEXT('USERENV','SID')) from dual)
   and sst.statistic# = v$statname.statistic#
   and sst.value > 0
 group by v$statname.name
 order by 2 desc
/

prompt
prompt
prompt Session Wait Events

select sev.EVENT                                                              as name,
       sum(sev.TOTAL_WAITS)                                                   as waits,
       round((sum(sev.TIME_WAITED_micro)) / 1000)                             as time_ms,
       sum(sev.TOTAL_TIMEOUTS)                                                as TIMEOUTS,
       round((sum(sev.TIME_WAITED_micro)) / 1000 / (sum(sev.TOTAL_WAITS)), 1) as avg_wait_ms
  from v$session_event sev
 where sev.sid in (select sid from v$px_session where qcsid = SYS_CONTEXT('USERENV', 'SID') and sid <> qcsid
                   union all
                   select to_number(SYS_CONTEXT('USERENV','SID')) from dual)
 group by sev.EVENT
having sum(sev.TOTAL_WAITS) > 0
 order by (sum(sev.TIME_WAITED_micro)) desc
/
prompt
prompt
set VERIFY ON timi on