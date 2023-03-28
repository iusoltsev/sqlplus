@@sysdate
select inst_id,
       xid,
       usn,
       state,
       undoblockstotal "Total",
       undoblocksdone "Done",
       undoblockstotal - undoblocksdone "ToDo",
       decode(cputime,
              0,
              'unknown',
              to_char(sysdate + (((undoblockstotal - undoblocksdone) /
              (undoblocksdone / cputime)) / 86400),'dd.mm.yyyy hh24:mi:ss')) "Estimated time to complete"
  from gv$fast_start_transactions
 where state <> 'RECOVERED'
/
select f.inst_id, f.state, event, count(*) px_count
  from gv$fast_start_servers f
  join gv$process p on p.pid = f.pid and p.inst_id = f.inst_id
  join gv$session s on s.PADDR = p.ADDR and p.inst_id = s.inst_id
 group by f.inst_id, f.state, event
 order by count(*) desc
/