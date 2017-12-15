--
-- Current Lock Waits chains based on GV$LOCK
-- Usage: SQL> @lock_tree_local
-- Igor Usoltsev
--

set echo off feedback off heading on timi off pages 1000 lines 1000 VERIFY OFF

col BLOCKING_TREE for a20
col SQL_TEXT for a100
col EVENT for a40 head "Event name"
col USERNAME for a40
col USERNAME for a60
col P1TEXT for a40
col P2TEXT for a40
col P3TEXT for a40
col BLOCK_SESSTAT for a13
col LAST_CALL_ET for 999999999999
col SECS_IN_WAIT for 999999999999
col CLNT_HOST   for a40
col CLNT_PID    for a10
col OSUSER      for a10
col SPID        for a10

select to_char(sysdate,'dd.mm.yyyy hh24:mi:ss') CHAR_DATE from dual;

alter session set "_with_subquery"=optimizer
/

with
 LOCKS as (select /*+ MATERIALIZE*/   * from gv$lock)
,S     as (select /*+ MATERIALIZE*/ s.* from gv$session s)
,BLOCKERS as
 (select distinct L1.inst_id, L1.sid
    from LOCKS L1, LOCKS L2
   where L1.block > 0
     and L1.ID1 = L2.ID1
     and L1.ID2 = L2.ID2
     and L2.REQUEST > 0)
--,WAITERS as (select inst_id, sid from S where blocking_session is not null or blocking_instance is not null)
,WAITERS as (select inst_id, sid from S where blocking_session is not null or blocking_instance is not null
             union
             select distinct L2.inst_id, L2.sid
              from LOCKS L1, LOCKS L2
             where L1.block > 0
               and L1.ID1 = L2.ID1
               and L1.ID2 = L2.ID2
               and L2.REQUEST > 0)
select--+ opt_param('_connect_by_use_union_all' 'false')
 LPAD(' ', (LEVEL - 1) * 2) || 'INST#' || s.inst_id || ' SID#' || sid as BLOCKING_TREE,
-- LPAD(' ', (LEVEL - 1) * 2) || REGEXP_SUBSTR(p.program,'[^@.]+',1,2) || '# Alter system kill session '''||sid||','||S.SERIAL#||''';' as BLOCKING_TREE,
 s.program,
 substr(s.USERNAME || ' ' || s.CLIENT_IDENTIFIER,1,60) as USERNAME,
 EVENT,
 object_type || ' ' || owner ||'.'|| object_name req_object,
 last_call_et,
 seconds_in_wait as SECS_IN_WAIT,
 blocking_session_status as BLOCK_SESSTAT,
 pdml_enabled,
-- s.sql_id,
 NVL(s.sql_id,sa2.sql_id) as SQL_ID,
 s.osuser,
 p.spid,
 s.machine as CLNT_HOST,
 s.process as CLNT_PID,
 s.port    as CLNT_PORT,
 substr(trim(NVL(sa1.sql_text,sa2.sql_text)), 1, 100) SQL_TEXT,
 decode(sign(nvl(s.ROW_WAIT_OBJ#, -1)), -1, 'NONE', DBMS_ROWID.ROWID_CREATE(1, s.ROW_WAIT_OBJ#, s.ROW_WAIT_FILE#, s.ROW_WAIT_BLOCK#, s.ROW_WAIT_ROW#)) as req_rowid,
 p1text || ' ' || decode(p1text, 'name|mode', chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535)||' '||bitand(p1, 65535), p1text)     as p1text,
 p1,
 p1raw,
 p2text || ' ' || decode(p2text, 'object #', o.object_name || ' ' || o.owner || '.' || o.object_name, p2text) as
 p2text,
 p2
/*,
 p2raw,
 p3text,
 p3,
 p3raw
*/
, 'Alter system kill session '''||s.SID||','||s.SERIAL#||','||'@'||s.INST_ID||''';' as KILL_SESSION
  from s
  left join gv$sqlarea sa1 on s.sql_id = sa1.sql_id and s.inst_id =  sa1.inst_id
  left join gv$sqlarea sa2 on s.prev_sql_id = sa2.sql_id and s.inst_id =  sa2.inst_id
  left join dba_objects o  on s.p2 = o.object_id -- here be dragonz
--  left join dba_objects o  on (s.p2 = o.object_id or s.row_wait_obj# = o.object_id)
  left join gv$process p on s.paddr = p.addr and s.inst_id = p.inst_id
connect by NOCYCLE prior sid = blocking_session and prior s.inst_id = blocking_instance
 start with (s.inst_id, s.sid)
            in (select inst_id, sid from BLOCKERS minus select inst_id, sid from WAITERS)
/
set feedback on echo off VERIFY ON

