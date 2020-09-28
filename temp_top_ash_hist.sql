--
-- The TEMP usage SQL_EXEC top from ASH history
-- SQL> @temp_top_ash_hist [30]                   [10]
--                          ^period (last NN days) ^top sql_exec count
--
select--+ parallel(5)
 * from (
                select instance_number as inst_id,
                       ash.sql_id,
                       sql_opname,
                       to_char(sql_exec_start,'dd.mm.yyyy hh24:mi:ss')           as SQL_EXEC_START,
                       max(sample_time) - SQL_EXEC_START                         as duration,
                       sql_exec_id,
                       sql_plan_hash_value,
                       module,
                       action,
                       machine,
                       round(max(temp_space_allocated) / 1024 / 1024 / 1024, 3) as max_temp_gb,
                       round(max(pga_allocated)        / 1024 / 1024 / 1024, 3) as max_pga_gb,
                       max(px_used)                                             as max_px_used
, replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ') as SQL_TEXT
                  from (select instance_number, sql_id, sql_exec_start, sql_exec_id, sql_plan_hash_value, sql_opname, module, action, sample_id, machine,
                               sum(temp_space_allocated)           as temp_space_allocated,
                               sum(pga_allocated)                  as pga_allocated,
                               count(distinct session_serial#) - 1 as px_used,
                               sample_time
                          from dba_hist_active_sess_history ash
                         where snap_id > (select/*+ NO_UNNEST*/ min(snap_id) from dba_hist_snapshot where begin_interval_time > sysdate - nvl('&1',30))
                           and sql_exec_id > 0
                         group by instance_number, sql_exec_start, sql_id, sql_exec_id, sql_plan_hash_value, sql_opname, module, action, sample_id, sample_time, machine
                          having sum(temp_space_allocated) is not null) ash
left join dba_hist_sqltext t  on t.sql_id  = ash.sql_id
                group by instance_number, ash.sql_id, SQL_EXEC_START, sql_exec_id, sql_plan_hash_value, sql_opname, module, action, machine
, replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ')
                having max(temp_space_allocated) / 1024 / 1024 / 1024 > 100 -- GB
                order by 11 desc
) where rownum <= nvl('&2',10)
/
