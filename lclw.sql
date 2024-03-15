--select * from monitor.monitor_query 
col SQL_TEXT for a200

select a.inst_id as i,
       session_id as sid,
       session_serial# as serial,
       listagg(distinct a.event, '; ' ON OVERFLOW TRUNCATE) as events,
       a.p1,
       a.p2,
       to_char(s.LOGON_TIME,'YYYY.MM.DD HH24:MI:SS') as LOGON_TIME,
       s.LAST_CALL_ET,
       t.START_TIME as TX_STIME,
       count(*),
       min(sample_time),
       max(sample_time),
       q.sql_id,
       sql_text
  from gv$active_session_history a
  join gv$session s
    on a.inst_id = s.inst_id
   and a.session_id = s.sid
  left join gv$sqlarea q
    on s.inst_id = q.inst_id
   and s.sql_id = q.sql_id
  left join gv$transaction t
    on s.SADDR = t.SES_ADDR
   and s.INST_ID = t.INST_ID
 where a.event in ('gc current request', 'gc current retry')
   and s.event in ('gc current request', 'gc current retry')
   and sample_time > sysdate - 15 / 24 / 60
 group by a.inst_id,
          session_id,
          session_serial#,
          a.p1,
          a.p2,
          sql_text,
          q.sql_id,
          to_char(s.LOGON_TIME,'YYYY.MM.DD HH24:MI:SS'),
          s.LAST_CALL_ET,
          t.START_TIME
having count(*) >= 100 --5*60-1
/