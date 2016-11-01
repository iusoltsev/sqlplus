--
--Dead Transaction info, based on 
--Master Note: Troubleshooting Database Transaction Recovery (Doc ID 1494886.1)
--

set feedback off
column "ORIGIN/GTX_INIT_PROC" format a20
column "FROM_DB.GTXID" format a64
column LSESSION format a10
column STATE format a8
column waiting format a60

select ktuxeusn USN,
       ktuxeslt Slot,
       ktuxesqn Seq,
       ktuxesta State,
       ktuxesiz Undo
  from x$ktuxe
 where ktuxesta <> 'INACTIVE'
   and ktuxecfl like '%DEAD%'
 order by ktuxesiz asc
/
set headin on
set feedback on