select--+ RULE
        sql_id,
--        sql_text,
        sum(executions),
        sum(fetches),
        sum(rows_processed),
        round( avg((rows_processed) / decode(executions, 0, 1, executions))) as avg_rows_per_exec,
        round( sum(rows_processed) / decode(sum(fetches), 0, 1, sum(fetches))) as rows_per_fetch
    from gv$sql
   where (inst_id, sql_id) in (select inst_id, sql_id
                                 from (select inst_id, sql_id, count(*) ccount
                                         from gv$active_session_history
                                        where EVENT = nvl('&&1','virtual circuit wait')
                                        group by inst_id, sql_id
                                        order by 3 desc)
                                where rownum < = 50) 
and COMMAND_TYPE = 3
group by
        sql_id
--	,sql_text
order by avg_rows_per_exec desc;