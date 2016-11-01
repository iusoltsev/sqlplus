#SET DEFINE ON
set feedback off
#def sid_ = "&&1"
#def inst_ = "&&2"
col EVENT for a40
col WAIT_CLASS for a20

with q as
	(select TO_NUMBER(nvl('&1',sys_context('userenv','sid'))) as sid, TO_NUMBER(nvl('&2',sys_context('userenv','instance'))) as inst_id from dual) 
select
	event,
	wait_class,
	sum(total_waits) as TOTAL_WAITS,
	sum(total_timeouts) as TOTAL_TIMEOUTS,
	round(sum(time_waited)*10,2) as TIME_WAITED_MS,
	round(avg(average_wait)*10,2) as AVG_WAIT_MS
from GV$SESSION_EVENT
	where (INST_ID, sid) in
		(select inst_id, sid from q
		 union all
		select inst_id, sid from gv$px_session where (qcinst_id, qcsid) in (select inst_id, sid from q))
group by event, wait_class
order by TIME_WAITED_MS desc
/
set feedback on