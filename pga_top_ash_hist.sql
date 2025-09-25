--
-- The TEMP usage SQL_EXEC top from ASH
-- SQL> @pga_top_ash_hist 158794 158811 [10]
--                          ^top sql_exec count
--
col MAX_SAMPLE_TIME for a26
col duration for a24
col SQL_EXEC_START for a20
col sql_text for a100
select s.*, trim(replace(replace(replace(dbms_lob.substr(h.sql_text,100),chr(10)),chr(13)),chr(9))) as sql_text from (
                select inst_id, sid, serial#,
                       sql_id, top_level_sql_id,
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
                  from (select instance_number inst_id, session_id sid, session_serial# serial#, sql_id, top_level_sql_id, sql_exec_start, sql_exec_id, sql_plan_hash_value, module, action, sample_id,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated,
                               count(distinct session_serial#) - 1 as px_used,
                               sample_time
                          from dba_hist_active_sess_history
                         where sql_exec_id > 0
                           and snap_id between &1 and &2
                           and dbid = sys_context('userenv','dbid')
                         group by instance_number, session_id, session_serial#, sql_exec_start, sql_id, top_level_sql_id, sql_exec_id, sql_plan_hash_value, module, action, sample_id, sample_time
                          having sum(pga_allocated) is not null)
                group by inst_id, sid, serial#, sql_id, top_level_sql_id, SQL_EXEC_START, sql_exec_id, sql_plan_hash_value, module, action
--                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 14 desc
) s
left join dba_hist_sqltext h on h.sql_id = s.sql_id and h.dbid = sys_context('userenv', 'dbid')
order by 14 desc
fetch first nvl('&3',10) rows only
-- where rownum <= nvl('&2',10)
/
select * from (
                select inst_id,
                       sample_id,
                       sample_time,
                       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
                       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb
                  from (select instance_number inst_id, sample_time, sample_id,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated
                          from dba_hist_active_sess_history
                         where snap_id between &1 and &2
                           and dbid = sys_context('userenv','dbid')
                         group by instance_number, sample_id, sample_time
                          having sum(temp_space_allocated) is not null)
                group by inst_id, sample_time, sample_id
--                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 5 desc
) where rownum <= nvl('&3',10)
/
