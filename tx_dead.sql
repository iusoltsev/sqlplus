--
--Dead Transaction info, based on 
--Master Note: Troubleshooting Database Transaction Recovery (Doc ID 1494886.1)
--

set feedback off
column "ORIGIN/GTX_INIT_PROC" format a20
column "FROM_DB.GTXID" format a64
column LSESSION format a10
column STATE format a10
column waiting format a60

select inst_id,
       ktuxeusn USN,
       ktuxeslt Slot,
       ktuxesqn Seq,
       ktuxesta State,
       ktuxesiz Undo,
       ktuxecfl
  from x$ktuxe
 where ktuxesta <> 'INACTIVE'
   and ktuxecfl like '%DEAD%'
 order by ktuxesiz asc
/
select inst_id,
       usn,
       state,
       undoblockstotal "Total",
       undoblocksdone "Done",
       undoblockstotal - undoblocksdone "ToDo",
       decode(cputime,
              0,
              'unknown',
              TO_CHAR(sysdate + (((undoblockstotal - undoblocksdone) /
              (undoblocksdone / cputime)) / 86400), 'dd.mm.yyyy hh24:mi:ss')) "Estimated time to complete"
  from gv$fast_start_transactions
 where state <> 'RECOVERED'
/
set headin on
set feedback on