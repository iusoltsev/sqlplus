--
-- The TEMP usage SQL_EXEC top from ASH history by snap_ids
-- SQL> @temp_top_ash_hist2 141742         141742         [10]
--                         ^start_snap_id ^stop_snap_id ^top sql_exec count
--
col SQL_EXEC_START for a20
col SQL_TEXT       for a100

select * from (
                select inst_id,
                       sid,
                       serial#,
                       sql_id,
                       to_char(sql_exec_start,'dd.mm.yyyy hh24:mi:ss')           as SQL_EXEC_START,
                       max(sample_time) - SQL_EXEC_START                         as duration,
                       sql_exec_id,
                       sql_plan_hash_value,
                       module,
                       action,
                       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
                       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb,
                       max(px_used)                                             as max_px_used
,(select trim(replace(replace(replace(dbms_lob.substr(sql_text,100),chr(10)),chr(13)),chr(9))) from dba_hist_sqltext where sql_id = a.sql_id and dbid = sys_context ('userenv','DBID'))  as sql_text
                  from (select nvl(qc_instance_id, instance_number) as inst_id,
                               nvl(qc_session_id, session_id) as sid,
                               nvl(qc_session_serial#, session_serial#) as serial#,
                               sql_id, sql_exec_start, sql_exec_id, sql_plan_hash_value, module, action, sample_id,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated,
                               count(distinct session_serial#) - 1 as px_used,
                               sample_time
                          from dba_hist_active_sess_history
                         where snap_id between &1 and &2
                           and sql_exec_id > 0
                         group by nvl(qc_instance_id, instance_number),
                                  nvl(qc_session_id, session_id),
                                  nvl(qc_session_serial#, session_serial#),
                                  sql_exec_start, sql_id, sql_exec_id, sql_plan_hash_value, module, action, sample_id, sample_time
                          having sum(temp_space_allocated) is not null) a
                group by inst_id, sid, serial#, sql_id, SQL_EXEC_START, sql_exec_id, sql_plan_hash_value, module, action
                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 11 desc
) where rownum <= nvl('&3',10)
/
select * from (
                select instance_number as inst_id,
                       sample_id,
                       sample_time,
                       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
                       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb
                  from (select instance_number, sample_time, sample_id,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated
                          from dba_hist_active_sess_history
                         where snap_id between &1 and &2
                         group by instance_number, sample_id, sample_time
                          having sum(temp_space_allocated) is not null)
                group by instance_number, sample_time, sample_id
                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 2 -- GB
                order by 4 desc
) where rownum <= nvl('&3',10)
/
