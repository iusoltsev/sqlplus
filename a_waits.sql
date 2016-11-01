--
-- Session waits in progress (trends)
-- Usage: SQL> @A_waits
-- Steve Adams script http://www.ixora.com.au/scripts/sql/waiters.sql
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col EVENT for a58
col PROGRAMS for a60 HEADING 'PROGRAMS BY TYPES                                           '
col t0 for 999
col t1 for 999
col t2 for 999
col t3 for 999
col t4 for 999
col t5 for 999
col t6 for 999
col t7 for 999
col t8 for 999
col t9 for 999

select /*+ ordered */
  substr(n.name, 1, 29)  event,
  t0,
  t1,
  t2,
  t3,
  t4,
  t5,
  t6,
  t7,
  t8,
  t9
from
  v$event_name  n,
  (select event e0, count(*)  t0 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e1, count(*)  t1 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e2, count(*)  t2 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e3, count(*)  t3 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e4, count(*)  t4 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e5, count(*)  t5 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e6, count(*)  t6 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e7, count(*)  t7 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e8, count(*)  t8 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6')),
  (select event e9, count(*)  t9 from v$session_wait group by event, TO_CHAR(SYSTIMESTAMP, 'FF6'))
where
  n.name not in ('null event','rdbms ipc message','pipe get','virtual circuit status','reliable message','PING','LNS ASYNC end of log','REPL Capture/Apply: RAC AQ qm') and
  n.name not like '%timer%' and
  n.name not like 'SQL*Net message from %' and
  n.name not like 'Streams AQ%' and
  n.name not like '%slave wait%' and
  lower(n.name) not like '%idle%' and  
  lower(n.name) not like '%sleep%' and  
  n.name not like '%VKTM%' and
  e0 (+) = n.name and
  e1 (+) = n.name and
  e2 (+) = n.name and
  e3 (+) = n.name and
  e4 (+) = n.name and
  e5 (+) = n.name and
  e6 (+) = n.name and
  e7 (+) = n.name and
  e8 (+) = n.name and
  e9 (+) = n.name and
  nvl(t0, 0) + nvl(t1, 0) + nvl(t2, 0) + nvl(t3, 0) + nvl(t4, 0) + nvl(t5, 0) + nvl(t6, 0) + nvl(t7, 0) + nvl(t8, 0) + nvl(t9, 0) > 0
order by nvl(t0, 0) + nvl(t1, 0) + nvl(t2, 0) + nvl(t3, 0) + nvl(t4, 0) + nvl(t5, 0) + nvl(t6, 0) + nvl(t7, 0) + nvl(t8, 0) + nvl(t9, 0)
/*
with t as
 (select --+ INLINE
   event,
--   decode(type,'BACKGROUND','(BACK)',decode(REGEXP_INSTR(program, '\([A-Z]...\)'),0,'(FRGR)',decode(REGEXP_INSTR(program, '\([P|J]...\)'),0,REGEXP_SUBSTR(program, '\([^\)]+\)'),REGEXP_SUBSTR(program, '(\([P|J])([[:digit:]]{3}\))',1,1,'c',1) || '***)'))) as program,
   decode(REGEXP_INSTR(program, '\([A-Z]...\)'),0,'(USER)',REGEXP_SUBSTR(program, '(\([A-Z].)(..\))',1,1,'c',1) || '**)') as program,
--   decode(type,'BACKGROUND','(BACK)','(USER)') as program,
   count(*) c
    from v$session
   where event not in ('Null event',
                       'rdbms ipc message',
                       'pipe get',
                       'virtual circuit status',
                       'wait for unread message on broadcast channel',
                       'PING')
     and event not like '%timer%'
     and event not like 'SQL*Net message from %'
     and event not like 'Streams AQ%'
     and event not like '%slave wait%'
     and upper(event) not like '%IDLE%'
     and upper(event) not like '%SLEEP%'
--     and type='BACKGROUND'
   group by
--            decode(type,'BACKGROUND','(BACK)',decode(REGEXP_INSTR(program, '\([A-Z]...\)'),0,'(FRGR)',decode(REGEXP_INSTR(program, '\([P|J]...\)'),0,REGEXP_SUBSTR(program, '\([^\)]+\)'),REGEXP_SUBSTR(program, '(\([P|J])([[:digit:]]{3}\))',1,1,'c',1) || '***)'))),
            decode(REGEXP_INSTR(program, '\([A-Z]...\)'),0,'(USER)',REGEXP_SUBSTR(program, '(\([A-Z].)(..\))',1,1,'c',1) || '**)'),
--            decode(type,'BACKGROUND','(BACK)','(USER)'),
            event)
select --+ ORDERED
  n.name AS  event,
   nvl(p0, '      ')
|| nvl(p1, '      ')
|| nvl(p2, '      ')
|| nvl(p3, '      ')
|| nvl(p4, '      ')
|| nvl(p5, '      ')
|| nvl(p6, '      ')
|| nvl(p7, '      ')
|| nvl(p8, '      ')
|| nvl(p9, '      ') AS 
programs,
  c0,
  c1,
  c2,
  c3,
  c4,
  c5,
  c6,
  c7,
  c8,
  c9
from
  v$event_name  n,
  (select event e0, program p0, c c0 from t),
  (select event e1, program p1, c c1 from t),
  (select event e2, program p2, c c2 from t),
  (select event e3, program p3, c c3 from t),
  (select event e4, program p4, c c4 from t),
  (select event e5, program p5, c c5 from t),
  (select event e6, program p6, c c6 from t),
  (select event e7, program p7, c c7 from t),
  (select event e8, program p8, c c8 from t),
  (select event e9, program p9, c c9 from t)
where
  e0 (+) = n.name and
  e1 (+) = n.name and
  e2 (+) = n.name and
  e3 (+) = n.name and
  e4 (+) = n.name and
  e5 (+) = n.name and
  e6 (+) = n.name and
  e7 (+) = n.name and
  e8 (+) = n.name and
  e9 (+) = n.name and
  nvl(c0, 0) + nvl(c1, 0) + nvl(c2, 0) + nvl(c3, 0) + nvl(c4, 0) + nvl(c5, 0) + nvl(c6, 0) + nvl(c7, 0) + nvl(c8, 0) + nvl(c9, 0) > 0
order by nvl(c0, 0) + nvl(c1, 0) + nvl(c2, 0) + nvl(c3, 0) + nvl(c4, 0) + nvl(c5, 0) + nvl(c6, 0) + nvl(c7, 0) + nvl(c8, 0) + nvl(c9, 0) desc
*/
/
set feedback on echo off VERIFY ON