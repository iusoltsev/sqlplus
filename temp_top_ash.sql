--
-- The TEMP usage SQL_EXEC top from ASH
-- SQL> @temp_top_ash  [10]
--                          ^top sql_exec count
--
col MAX_SAMPLE_TIME for a22
col duration for a24
col SQL_EXEC_START for a20

select * from (
                select inst_id,
                       sql_id,
                       to_char(sql_exec_start,'dd.mm.yyyy hh24:mi:ss')           as SQL_EXEC_START,
                       max(sample_time)                                          as max_sample_time,
                       max(sample_time) - SQL_EXEC_START                         as duration,
                       sql_exec_id,
                       sql_plan_hash_value,
                       module,
                       action,
                       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
                       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb,
                       max(px_used)                                             as max_px_used
                  from (select inst_id, sql_id, sql_exec_start, sql_exec_id, sql_plan_hash_value, module, action, sample_id,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated,
                               count(distinct session_serial#) - 1 as px_used,
                               sample_time
                          from gv$active_session_history
                         where sql_exec_id > 0
                         group by inst_id, sql_exec_start, sql_id, sql_exec_id, sql_plan_hash_value, module, action, sample_id, sample_time
                          having sum(temp_space_allocated) is not null)
                group by inst_id, sql_id, SQL_EXEC_START, sql_exec_id, sql_plan_hash_value, module, action
                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 10 desc
) where rownum <= nvl('&1',10)
/
select * from (
                select inst_id,
                       sample_id,
                       sample_time,
                       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
                       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb
                  from (select inst_id, sample_time, sample_id,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated
                          from gv$active_session_history
--                         where snap_id between &1 and &2
                         group by inst_id, sample_id, sample_time
                          having sum(temp_space_allocated) is not null)
                group by inst_id, sample_time, sample_id
                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 4 desc
) where rownum <= nvl('&1',10)
/
