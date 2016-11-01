col MIN_SAMPLE_TIME for a16
col MAX_SAMPLE_TIME for a16

select * from (
select inst_id,
       to_char(min(sample_time),'dd.mm.yyyy hh24:mi')          as min_sample_time,
       to_char(max(sample_time),'dd.mm.yyyy hh24:mi')          as max_sample_time,
       sql_id,
       sql_plan_hash_value                                     as plan_hash_value,
       count(distinct sql_exec_id)                             as execs,
       to_char(max(temp_space_allocated),'999,999,999,999,999')as max_temp_space,
       round(max(temp_space_allocated)
            /
            (select sum(user_bytes) from dba_temp_files where tablespace_name = 'TEMP')*100) as "TEMP%",
       to_char(max(pga_allocated),'999,999,999,999')           as max_pga,
       max(px) - 1                                             as px
  from (select instance_number                     as inst_id,
               sample_time,
               sql_id,
               sql_plan_hash_value,
               sql_exec_id,
               sum(temp_space_allocated)           as temp_space_allocated,
               sum(pga_allocated)                  as pga_allocated,
               count(distinct session_serial#) - 1 as px
          from dba_hist_active_sess_history
         where sql_exec_id > 0
           and snap_id >= (select min(snap_id) from dba_hist_snapshot where BEGIN_INTERVAL_TIME > trunc(sysdate) - 1)
         group by instance_number,
                  sample_time,
                  sql_id,
                  sql_plan_hash_value,
                  sql_exec_id
--        having sum(temp_space_allocated) > (select sum(user_bytes) from dba_temp_files) / 2
        )
 group by inst_id, sql_id, sql_plan_hash_value
 order by max(temp_space_allocated) desc nulls last)
where rownum <= 5
/