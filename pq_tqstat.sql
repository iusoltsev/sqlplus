select tq_id, server_type, instance, process, num_rows
  from v$pq_tqstat
-- where tq_id = 1
 order by dfo_number, tq_id, server_type desc, instance, process
/
