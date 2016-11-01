select RANK,
       WAIT_EVENT,
       lpad(TO_CHAR(PCTTOT, '990D99'), 6) || '% waits with avg.du =' ||
       TO_CHAR(AVERAGE_WAIT_MS, '9999990D99') || ' ms' as EVENT_VALUES
  from (select DENSE_RANK() OVER(order by sum(time_waited) desc) as RANK,
               event as WAIT_EVENT,
               round(RATIO_TO_REPORT(sum(time_waited)) OVER() * 100, 2) AS PCTTOT,
               round(avg(average_wait) * 10, 2) as AVERAGE_WAIT_MS
          from (select se.SID,
                       se.INST_ID,
                       se.EVENT,
                       se.TIME_WAITED,
                       se.AVERAGE_WAIT
                  from gv$session_event se
                 where se.WAIT_CLASS not in ('Idle')
                union
                select ss.SID,
                       ss.INST_ID,
                       sn.NAME    as EVENT,
                       ss.VALUE   as TIME_WAITED,
                       0          as AVERAGE_WAIT
                  from gv$sesstat ss, v$statname sn
                 where ss."STATISTIC#" = sn."STATISTIC#"
                   and sn.NAME in ('CPU used when call started'))
         where (sid, inst_id) in
               (select sid, inst_id
                  from gv$session
                 where gv$session.SERVICE_NAME not in ('SYS$BACKGROUND'))
         group by event
         order by PCTTOT desc) we
 where RANK <= 10
/