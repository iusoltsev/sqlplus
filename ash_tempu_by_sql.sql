col MIN_SAMPLE_TIME for a16
col MAX_SAMPLE_TIME for a16
col sql_text for a200

select * from (
select inst_id,
       to_char(min(sample_time),'dd.mm.yyyy hh24:mi')          as min_sample_time,
       to_char(max(sample_time),'dd.mm.yyyy hh24:mi')          as max_sample_time,
       module,
       sql_id,
       sql_plan_hash_value                                     as plan_hash_value,
       count(distinct sql_exec_id)                             as execs,
       to_char(max(temp_space_allocated),'999,999,999,999,999')as max_temp_space,
       round(max(temp_space_allocated)
            /
            (select sum(user_bytes) from dba_temp_files where tablespace_name = 'TEMP')*100) as "TEMP%",
       to_char(max(pga_allocated),'999,999,999,999')           as max_pga,
       max(px) - 1                                             as px,
--(select substr(sql_text,1,200) as sql_text from gv$sqlarea a where a.sql_id = sql_id union select dbms_lob.substr(sql_text,200) from dba_hist_sqltext a where a.sql_id = sql_id) as sql_text
(select NVL(substr(a.sql_text,1,200), dbms_lob.substr(h.sql_text,200)) as sql_text from gv$sqlarea a, dba_hist_sqltext h where a.sql_id = s.sql_id and  a.sql_id = h.sql_id) as sql_text
  from (select inst_id                             as inst_id,
               sample_time,
               sql_id,
               sql_plan_hash_value,
               sql_exec_id,
               module,
               sum(temp_space_allocated)           as temp_space_allocated,
               sum(pga_allocated)                  as pga_allocated,
               count(distinct session_serial#) - 1 as px
          from gv$active_session_history
         where sql_exec_id > 0
           and &2
         group by inst_id,
                  sample_time,
                  sql_id,
                  sql_plan_hash_value,
                  sql_exec_id,
                  module
        ) s
 group by inst_id, sql_id, sql_plan_hash_value, module
 order by max(temp_space_allocated) desc nulls last)
where rownum <= nvl('&1', 10)
/