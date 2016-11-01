--
-- Current mutex-related events info
-- Usage: SQL> @mutex_waits
-- MOS Doc ID 1298015.1
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col LVL for 999
col BLOCKING_TREE for a30
col EVENT for a64
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col SQL_ID for a13

with hs as
 (select level lvl,
         h.sid WAITING_SID,
         h.program,
         h.sql_id,
         h.event,
         h.seconds_in_wait,
         h.blocking_session,
         h.p1,
         decode(trunc(h.p2 / 4294967296),
                0,
                trunc(h.p2 / 65536),
                trunc(h.p2 / 4294967296)) SID_HOLDING_MUTEX,
         decode(trunc(h.p3 / 4294967296),
                0,
                trunc(h.p3 / 65536),
                trunc(h.p3 / 4294967296)) mutex_loc
    from v$session h
   start with h.p1text = 'idn'
          and h.p3text = 'where' -- mutex related events
  connect by nocycle h.SID = prior h.BLOCKING_SESSION)
select hs.lvl,
       hs.WAITING_SID,
       hs.program,
       hs.sql_id,
       hs.event,
       hs.seconds_in_wait,
       hs.blocking_session        as BLOCKING_SID,
       s.sql_id                   as LC_SQL_ID,
       hs.SID_HOLDING_MUTEX,
       m.MUTEX_TYPE,
       m.LOCATION                 as MUTEX_LOCATION,
       substr(s.sql_text, 1, 100) as LC_SQL_TEXT
  from hs, v$sqlarea s, x$mutex_sleep m
 where hs.p1 = s.HASH_VALUE
   and hs.mutex_loc = m.location_id(+)
--   and nvl(m.mutex_type, 'Cursor Pin') like 'Cursor Pin%'
 order by lvl, WAITING_SID
/

/*
with h as
 (select /+ materialize/ * from v$session),
hs as
 (select /+ materialize/
   level lvl,
   h.sid WAITING_SID,
   h.program,
   h.event,
   h.seconds_in_wait,
   h.blocking_session,
   h.p1,
   decode(trunc(h.p2 / 4294967296),
          0,
          trunc(h.p2 / 65536),
          trunc(h.p2 / 4294967296)) SID_HOLDING_MUTEX,
   decode(trunc(h.p3 / 4294967296),
          0,
          trunc(h.p3 / 65536),
          trunc(h.p3 / 4294967296)) mutex_loc
    from h
   start with h.event in (select name
                            from v$event_name
                           where parameter1 = 'idn'
                             and parameter3 = 'where') -- mutex related events
  connect by nocycle h.SID = prior h.BLOCKING_SESSION)
select hs.lvl,
       hs.WAITING_SID,
       hs.program,
       hs.event,
       hs.seconds_in_wait,
       hs.blocking_session,
       s.sql_id,
       hs.SID_HOLDING_MUTEX,
       m.MUTEX_TYPE,
       m.LOCATION MUTEX_LOCATION,
       substr(s.sql_text,1,100) as sql_text
  from hs, v$sqlarea s, x$mutex_sleep m
 where hs.p1 = s.HASH_VALUE
   and hs.mutex_loc = m.location_id(+)
--   and nvl(m.mutex_type, 'Cursor Pin') like 'Cursor Pin%'
 order by lvl, WAITING_SID
*/
set feedback on echo off VERIFY ON