--
-- The TEMP usage SQL_EXEC top from ASH
-- SQL> @pga_top_ash gv$active_session_history [10]
--                          ^top sql_exec count
--
col MAX_SAMPLE_TIME for a26
col duration for a24
col SQL_EXEC_START for a20
col sql_text for a100
/*select s.*, trim(replace(replace(replace(dbms_lob.substr(h.sql_text,100),chr(10)),chr(13)),chr(9))) as sql_text from 
(
                select inst_id,
                       session_id,
                       session_serial#,
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
                  from (select nvl(qc_instance_id ,instance_number) as inst_id, nvl(qc_session_id, session_id) as session_id, nvl(qc_session_serial#, session_serial#) as session_serial#, sql_id, sql_exec_start, sql_exec_id, sql_plan_hash_value, module, action, sample_id,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated,
                               count(distinct session_serial#) - 1 as px_used,
                               sample_time
                          from dba_hist_active_sess_history
                         where --sql_exec_id = 74340417-- > 0 and sql_id = '5uwpjfcck556f' and
                         snap_id between 132297 and 132307
                         group by nvl(qc_instance_id ,instance_number), nvl(qc_session_id, session_id), nvl(qc_session_serial#, session_serial#), sql_exec_start, sql_id, sql_exec_id, sql_plan_hash_value, module, action, sample_id, sample_time
                          having sum(pga_allocated) is not null
                          )
                group by inst_id, session_id, session_serial#, sql_id, SQL_EXEC_START, sql_exec_id, sql_plan_hash_value, module, action
                order by 13 desc
) s
left join dba_hist_sqltext h on h.sql_id = s.sql_id and h.dbid = sys_context('userenv', 'dbid')
order by 13 desc
fetch first 100 rows only
*/
select s.*, trim(replace(replace(replace(dbms_lob.substr(h.sql_text,100),chr(10)),chr(13)),chr(9))) as sql_text from (
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
                          from &1--gv$active_session_history
                         where sql_exec_id > 0
                         group by inst_id, sql_exec_start, sql_id, sql_exec_id, sql_plan_hash_value, module, action, sample_id, sample_time
                          having sum(pga_allocated) is not null)
                group by inst_id, sql_id, SQL_EXEC_START, sql_exec_id, sql_plan_hash_value, module, action
--                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 11 desc
) s
left join dba_hist_sqltext h on h.sql_id = s.sql_id and h.dbid = sys_context('userenv', 'dbid')
order by 11 desc
fetch first nvl('&2',10) rows only
-- where rownum <= nvl('&2',10)
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
                          from &1--gv$active_session_history
--                         where snap_id between &1 and &2
                         group by inst_id, sample_id, sample_time
                          having sum(temp_space_allocated) is not null)
                group by inst_id, sample_time, sample_id
--                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 5 desc
) where rownum <= nvl('&2',10)
/
