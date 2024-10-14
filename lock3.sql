--
-- Lock Waits chains based on GV$LOCK
-- Usage: SQL> @lock3
-- Igor Usoltsev
--

set echo off feedback off heading on timi on pages 1000 lines 1000 VERIFY OFF

col CBPATH for a120
col BLOCKING_TREE for a45
col LVLS          for a6
col prior_ISID    for a12
col TYPE          for a4
col SQL_TEXT      for a200
col EVENT         for a60 head "Event name"
col USER_CLIENT   for a60
col P1TEXT        for a40
col P2TEXT        for a40
col P3TEXT        for a40
col LMODE         for a5
col BLKN_STATUS   for a12
col BLKN_SESSION  for a12
col LAST_CALL_ET  for 999999999999
col SECS_IN_WAIT  for 999999999999
col MACHINE       for a60
col CLNT_PID      for a16
col OSUSER        for a10
col SPID          for a10
col REQ_OBJECT    for a65
col KILL_SESSION  for a50
col USERNAME      for a30
col CLIENT_ID     for a80
col lock_name     for a64
col service_name  for a30

@@sysdate

with
 GVS      as (select /* MATERIALIZE*/ s.* from gv$session s),
 LOCKS    as (select /*+ MATERIALIZE*/   * from gv$lock where (REQUEST > 0 or block > 0))-- and type not in ('MR', 'AE', 'TO'))
--,GVS      as (select /* MATERIALIZE*/ s.* from gv$session s)
--select * from LOCKS
,BLOCKERS as
         (select /*+ MATERIALIZE*/ distinct L1.inst_id, L1.sid, L1.con_id, L1.type, L1.ID1, L1.ID2, L1.block, case when L1.REQUEST > 0 then 1 else 0 end as REQUEST, L1.KADDR, L1.lmode--, UTL_RAW.CAST_TO_VARCHAR2(L1.KADDR)
            from LOCKS L1, LOCKS L2
           where L1.block > 0
             and L1.ID1 = L2.ID1
             and L1.ID2 = L2.ID2
             and L2.REQUEST > 0
and L1.type not in ('MR', 'AE', 'TO') and L2.type not in ('MR', 'AE', 'TO'))
--select * from BLOCKERS
,WAITERS  as (select /*+ MATERIALIZE*/ distinct L2.inst_id, L2.sid, L2.con_id, L2.type, L2.ID1, L2.ID2, L2.block, case when L2.REQUEST > 0 then 1 else 0 end as REQUEST, L2.KADDR, L2.lmode--, UTL_RAW.CAST_TO_VARCHAR2(L2.KADDR)
               from LOCKS L1, LOCKS L2
              where L1.block > 0
                and L1.ID1 = L2.ID1
                and L1.ID2 = L2.ID2
                and L2.REQUEST > 0
and L1.type not in ('MR', 'AE', 'TO') and L2.type not in ('MR', 'AE', 'TO'))
--select * from WAITERS
--select inst_id, sid, type, con_id, ID1, ID2 from BLOCKERS union select inst_id, sid, type, con_id, ID1, ID2 from WAITERS
,b3 as (select /*+ MATERIALIZE*/
               LEVEL as LVL,
               LPAD(' ', (LEVEL - 1) * 2) || 'INST#' || inst_id || ' SID#' || sid ||' CON#' || con_id as BLOCKING_TREE,
               type, inst_id, sid, con_id, KADDR, block, REQUEST, ID1, ID2, lmode
, CONNECT_BY_ROOT sid as ROOT_sid
, connect_by_isleaf   as isleaf
, prior SID           as prior_SID
, prior INST_ID       as prior_INST_ID
          from (select inst_id, sid, type, con_id, ID1, ID2, block, REQUEST, KADDR, lmode from BLOCKERS
                union
                select inst_id, sid, type, con_id, ID1, ID2, block, REQUEST, KADDR, lmode from WAITERS) ll
        connect by NOCYCLE prior ID1 = ID1
               and prior ID2 = ID2
               and prior type = type
               and prior sid != sid
               and prior block > block
         start with (inst_id, sid, type, con_id, ID1, ID2) in
                    (select inst_id, sid, type, con_id, ID1, ID2 from BLOCKERS where block > 0 and REQUEST = 0))
--select inst_id, sid from B3 where block > 0 and (inst_id, sid) not in (select inst_id, sid from B3 where REQUEST > 0)
/*,s3 as (select --+ MATERIALIZE
                inst_id, sid from B3 join gvs using(inst_id,sid)
         where block > 0
           and not (B3.TYPE = 'TM' and LMODE = 3 and event = 'SQL*Net message from client' and seconds_in_wait < 3)
           and (inst_id, sid) not in (select inst_id, sid from B3 where REQUEST > 0))
*/
select * from (
select /*+ MONITOR
           ordered
           opt_param('_optimizer_generate_transitive_pred','FALSE')
           OPT_PARAM('_fast_full_scan_enabled' 'true')
           OPT_PARAM('_optimizer_aggr_groupby_elim' 'true')
           OPT_PARAM('_optimizer_reduce_groupby_key' 'true')
       */
  LEVEL || '/' || LVL   as LVLS
--, SYS_CONNECT_BY_PATH(level||b3.type||event||seconds_in_wait, '/') as cbpath
, LPAD(' ', (LEVEL - 1) * 2) || '(' || b3.inst_id || ',' || b3.sid || ',' || s.serial# ||') CON#' || b3.con_id as BLOCKING_TREE
--, s.serial#
--, ROOT_sid
--, isleaf   
--, prior_ISID
, b3.prior_INST_ID||','||b3.prior_SID as prior_isid
, s.service_name
, b3.TYPE
, t.name as lock_name
, lmode, ID1, ID2, KADDR
, block
, REQUEST
     , s.program
     , s.USERNAME
     , s.CLIENT_IDENTIFIER as CLIENT_ID
     , s.EVENT
     , s.last_call_et
     , s.seconds_in_wait as SECS_IN_WAIT
     , s.blocking_session_status as BLKN_STATUS
     , '(' || s.blocking_instance || ',' || s.blocking_session || ')' as BLKN_SESSION
     , s.pdml_enabled as PDML
     , s.osuser
--   , p.spid
     , s.machine
     , s.module
     , s.action
     , s.process as CLNT_PID
     , s.port    as CLNT_PORT
, (select o.object_type || ' ' || o.owner ||'.'|| o.object_name || ' (' || object_id || ')' from cdb_objects o where decode(b3.type,'TM',b3.id1, s.row_wait_obj#) = o.object_id and s.con_id =  o.con_id) AS req_object
---, o.object_type || ' ' || o.owner ||'.'|| o.object_name AS req_object
----, NVL(o.object_type, o2.object_type) || ' ' || NVL(o.owner, o2.owner) ||'.'|| NVL(o.object_name, o2.object_name) req_object
     , s.ROW_WAIT_OBJ#, s.ROW_WAIT_FILE#, s.ROW_WAIT_BLOCK#, s.ROW_WAIT_ROW#
     , decode(p1text, 'name|mode', chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535)||' '||bitand(p1, 65535), p1text)                      as p1text
     , p1
     , p1raw
     , p2text
     , p2
     , 'Alter system kill session '''||s.SID||','||s.SERIAL#||','||'@'||s.INST_ID||''';' as KILL_SESSION
     , NVL(s.sql_id, s.prev_sql_id) as SQL_ID
--     , decode(SQL_ADDRESS,'00','0','1')||decode(SQL_HASH_VALUE,0,'0','1')||nvl2(SQL_ID,'1','0')||nvl2(SQL_CHILD_NUMBER,'1','0')||nvl2(SQL_EXEC_START,'1','0')||nvl2(SQL_EXEC_ID,'1','0') as AHICSE
     , NVL(s.sql_child_number, s.prev_child_number) as child
     , sql_exec_id
     , to_char(sql_exec_start,'dd.mm hh24:mi:ss') as sql_exec_start
     , substr(replace(replace(sa1.SQL_TEXT,chr(10),' '),chr(13),' '),1,200) as SQL_TEXT
 from b3
 join gvs s on s.inst_id =  b3.inst_id and s.sid = b3.sid
-- and s.seconds_in_wait > 0 -- 2exclude 0 duration TM waits
---^^ left join cdb_objects o  on decode(b3.type,'TM',b3.id1, s.row_wait_obj#) = o.object_id and s.con_id =  o.con_id
----^ left join cdb_objects o  on decode(b3.type,'TM',b3.id1,'') = o.object_id and s.con_id =  o.con_id
----^ left join cdb_objects o2 on s.row_wait_obj#                  = o2.object_id and s.con_id =  o2.con_id
 left join gv$sqlarea sa1 on NVL(s.sql_id,s.prev_sql_id) = sa1.sql_id and s.inst_id =  sa1.inst_id and s.con_id =  sa1.con_id
 left join v$lock_type t on t.type = b3.TYPE
        connect by NOCYCLE prior b3.SID     = b3.prior_SID
                       and prior b3.INST_ID = b3.prior_INST_ID
-----V                       and not (s.seconds_in_wait = 0 and b3.TYPE = 'TM' and prior b3.TYPE = 'TM' and prior b3.LMODE = 3 and prior s.seconds_in_wait = 0)
         start with (b3.inst_id, b3.sid) in
                    (select inst_id, sid from B3 join gvs using(inst_id,sid)
                      where block > 0
                        and not (B3.TYPE = 'TM' and LMODE <= 3 and event = 'SQL*Net message from client' and SQL_EXEC_ID is null)-- and seconds_in_wait <= 3
                        and (inst_id, sid) not in (select inst_id, sid from B3 where REQUEST > 0))
) --where cbpath like '%'
/
@@sysdate
set feedback on echo off VERIFY ON timi on

