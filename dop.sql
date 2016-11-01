set verify off

select inst_id,
       to_char(sql_exec_start, 'dd.mm hh24:mi:ss') sql_exec_start,
       PX_MAXDOP,
       PX_SERVERS_REQUESTED,
       PX_SERVERS_ALLOCATED,
       to_char(first_refresh_time, 'dd.mm hh24:mi:ss') first_refresh_time,
       to_char(last_refresh_time, 'dd.mm hh24:mi:ss') last_refresh_time
  from gv$sql_monitor
 where sql_id = '&&1'
and PX_MAXDOP > 0 
order by sql_exec_start desc
/
set verify on