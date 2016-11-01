--
-- Wait tree for "TX - row lock contention" event
-- Usage: SQL> @tx_tree
-- Igor Usoltsev
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col BLOCKING_TREE for a60
col SQL_TEXT for a60
col EVENT for a34

with L as
 (select--+ materialize
         L1.inst_id, L1.sid
    from gv$lock L1, gv$lock L2
   where L1.block > 0
     and L1.ID1 = L2.ID1
     and L1.ID2 = L2.ID2
     and L2.type = 'TX'
     and L2.REQUEST > 0)
select--+ opt_param('_connect_by_use_union_all' 'false')
 LPAD(' ', (LEVEL - 1) * 2) || 'INST#' || s.inst_id || ' SID#' || sid || ' ' ||
 program as BLOCKING_TREE,
 EVENT,
 last_call_et,
 blocking_session_status,
 s.sql_id,
 substr(trim(NVL(sa1.sql_text,sa2.sql_text)), 1, 60) SQL_TEXT,
 decode(sign(nvl(s.ROW_WAIT_OBJ#, -1)), -1, 'NONE', DBMS_ROWID.ROWID_CREATE(1, s.ROW_WAIT_OBJ#, s.ROW_WAIT_FILE#, s.ROW_WAIT_BLOCK#, s.ROW_WAIT_ROW#)) req_rowid
--       prior status
  from gv$session s, gv$sqlarea sa1, gv$sqlarea sa2
 where s.sql_id = sa1.sql_id(+)
   and s.inst_id = sa1.inst_id(+)
   and s.prev_sql_id = sa2.sql_id(+)
   and s.inst_id = sa2.inst_id(+)
connect by prior sid = blocking_session
 start with (s.inst_id, s.sid)
            in (select inst_id, sid from L)
/
/*
select 
       LPAD(' ',(LEVEL-1)*2)|| 'SID#' || sid || ' ' || program as BLOCKING_TREE,
       EVENT,
       last_call_et,
       blocking_session_status,
       s.sql_id,
       substr(trim(sa.sql_text),1,60) SQL_TEXT,
       decode(sign(nvl(s.ROW_WAIT_OBJ#,-1)),-1,'NONE',DBMS_ROWID.ROWID_CREATE( 1, s.ROW_WAIT_OBJ#, s.ROW_WAIT_FILE#, s.ROW_WAIT_BLOCK#, s.ROW_WAIT_ROW# )) req_rowid
--       prior status
from v$session s, v$sqlarea sa
where s.sql_id = sa.sql_id
connect by prior sid = blocking_session 
start with sid in (select sid from v$lock where type = 'TX' and block > 0)
*/
set feedback on echo off VERIFY ON

