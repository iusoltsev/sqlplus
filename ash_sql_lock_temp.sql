--
-- ASH lock tree for condition
-- Usage: SQL> @ash_sql_lock_temp "event = 'enq: TX - row lock contention' and sql_id = '8matphjwpgg7k'" 100
--                                                                                                       ^min wait count
-- http://iusoltsev.wordpress.com
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col WAIT_LEVEL for 999
col BLOCKING_TREE for a30
col EVENT for a40
col SQL_TEXT for a100
col MODULE for a40
col CLIENT_ID for a40
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col DATA_OBJECT for a52

with ash_locks as
 (select --snap_id,
         inst_id                          as BLOCKED_INST_ID,
         session_id                       as BLOCKED_SID,
         session_serial#                  as BLOCKED_SERIAL#,
         nvl(REGEXP_SUBSTR(client_id, '.+\#'),
                                      case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then program
                                        when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
                                        when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
                                        when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
                                        else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
                                      end) as BLOCKED_CLIENT_ID,
         sql_id                           as BLOCKED_SQL_ID,
         CURRENT_OBJ#                     as BLOCKED_OBJ#,
         BLOCKING_INST_ID,
         BLOCKING_SESSION,
         BLOCKING_SESSION_SERIAL#,
         event,
         sample_time
    from SYSTEM.ASH_201711020939
   where &1 -- event = 'enq: TX - row lock contention' and snap_id = 325800
     and BLOCKING_SESSION > 0
 )
, ash_lockers as 
   (select * from
    (select ash_locks.sample_time,
            ash_locks.BLOCKED_INST_ID,
            ash_locks.BLOCKED_SID,
            ash_locks.BLOCKED_SERIAL#,
--            ash_locker.snap_id,
            ash_locker.client_id                          as BLOCKING_CLIENT_ID,
            ash_locker.sql_id                             as BLOCKING_SQL_ID,
            ash_locker.session_id                         as BLOCKING_SID,
            ash_locker.session_serial#                    as BLOCKING_SERIAL#,
            ash_locker.inst_id as BLOCKING_INST_ID,
            ash_locker.sample_time - ash_locks.sample_time as BLOCK_TIME_LAG,
            ash_locker.sample_time                         as BLOCKING_TIME,
            ash_locker.CURRENT_OBJ#                        as BLOCKING_OBJ#,
            nvl2(ash_locker.XID,'*','')                    as XID,
            decode(ash_locker.Session_State , 'WAITING', ash_locker.event, ash_locker.Session_State) as BLOCKING_WAIT,
            ash_locker.program,
            ash_locker.module,
            ash_locker.action,
      rank() over ( partition by ash_locks.sample_time,
                                 ash_locks.BLOCKED_INST_ID,
                                 ash_locks.BLOCKED_SID,
                                 ash_locks.BLOCKED_SERIAL#
                     order by abs(cast(ash_locks.sample_time as date) - cast(ash_locker.sample_time as date)) asc ) as rnk
      from SYSTEM.ASH_201711020939
                                                             ash_locker
      join ash_locks
        on --ash_locker.snap_id         = ash_locks.snap_id and
           ash_locker.session_id      = ash_locks.BLOCKING_SESSION
       and ash_locker.session_serial# = ash_locks.BLOCKING_SESSION_SERIAL#
       and ash_locker.inst_id = ash_locks.BLOCKING_INST_ID
--       and ash_locker.sample_time    <= ash_locks.sample_time
         )
     where rnk = 1)
select BLOCKED_INST_ID                                            as INST#1,
       BLOCKED_CLIENT_ID,
       BLOCKED_SQL_ID,
       do1.owner || '.' || do1.object_name                        as CURRENT_OBJ#1,
       EVENT                                                      as WAITED_FOR,
       count(distinct BLOCKED_INST_ID||' '||
                      BLOCKED_SID    ||' '||
                      BLOCKED_SERIAL#)                            as BLOCKED_SIDS,
       count(*)                                                   as WAIT_COUNT,
       to_char(min(sample_time),'DD.MM HH24:MI:SS')               as MIN_WAITS_TIME,
       to_char(max(sample_time),'DD.MM HH24:MI:SS')               as MAX_WAITS_TIME,
       ash_lockers.BLOCKING_INST_ID                               as INST#2,
--       REGEXP_SUBSTR(BLOCKING_CLIENT_ID, '.+\#')                  as BLOCKING_CLIENT_ID,
--       program,
       nvl(REGEXP_SUBSTR(BLOCKING_CLIENT_ID, '.+\#'),
                  case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then program
                       when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
                       when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
                       when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
                       else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
                  end) as BLOCKING_CLIENT_ID,
       module,
       action,
       BLOCKING_SQL_ID,
       BLOCKING_WAIT,
       do2.owner || '.' || do2.object_name                        as CURRENT_OBJ#2,
       XID,
       cast((min(BLOCK_TIME_LAG))AS INTERVAL DAY(1) TO SECOND(0)) as LOCK_TIME_LAG
--, min(BLOCKING_TIME)
--, max(BLOCKING_TIME)
from ash_locks
left join ash_lockers using (BLOCKED_INST_ID, BLOCKED_SID, BLOCKED_SERIAL#, SAMPLE_TIME--, SNAP_ID
                                                                                       )
left join dba_objects do1 on do1.object_id = BLOCKED_OBJ#
left join dba_objects do2 on do2.object_id = BLOCKING_OBJ#
group by BLOCKED_INST_ID,
         BLOCKED_CLIENT_ID,
         BLOCKED_SQL_ID,
         do1.owner || '.' || do1.object_name,
         EVENT,
         ash_lockers.BLOCKING_INST_ID,
--         REGEXP_SUBSTR(BLOCKING_CLIENT_ID, '.+\#'),
--         program,
         nvl(REGEXP_SUBSTR(BLOCKING_CLIENT_ID, '.+\#'),
                    case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then program
                         when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
                         when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
                         when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
                         else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
                    end),
         module,
         action,
         BLOCKING_SQL_ID,
         BLOCKING_WAIT,
         do2.owner || '.' || do2.object_name,
         XID
having count(*) >= nvl('&2',0)
order by count(*) desc
/
set feedback on echo off VERIFY ON
