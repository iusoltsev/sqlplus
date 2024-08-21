--What the OEbs concurrent program use this SQL_ID in system?
--@oebs_sql2conc_prg 5x1yhfjgxfdj8 1377610627 89000          100000        "MOD|SERV|CMAN" 0
--                   ^sql_id       ^phv       ^start snap_id ^stop snap_id  ^add.info      ^min ash rows
set lines 300
col request_list for a200

with q as
 (select distinct instance_number,
                  session_id,
                  session_serial#,
                  module,
                  decode(nvl(s.name,service_hash),'3427055676','SYS$USERS',nvl(s.name,service_hash)) as service,
                  count(*) over(partition by instance_number, session_id, session_serial#,
                                             module,
                                             decode(nvl(s.name,service_hash),'3427055676','SYS$USERS',nvl(s.name,service_hash))) as ash_rows
                 ,min(sample_time) over() as min_sample_time
    from dba_hist_active_sess_history
    left join dba_services s on s.name_hash = service_hash
   where  snap_id between &3 and &4 and sql_id in ('&1')
    and (SQL_PLAN_HASH_VALUE = NVL('&2',SQL_PLAN_HASH_VALUE) or '&2' = '0'))
select--+ parallel(8)
       CONCURRENT_PROGRAM_NAME
     , case when upper('&5') like '%MOD%' then q.module else '' end as module
     , case when upper('&5') like '%SERV%' then q.service else '' end as service
     , case when upper('&5') like '%CMAN%' then cm_name else '' end as cm_name
     , sum(ash_rows)
, listagg(distinct request_id||status_code, ',' ON OVERFLOW TRUNCATE WITH COUNT) within group (order by ACTUAL_COMPLETION_DATE-ACTUAL_START_DATE desc) as request_list
  from q
  left join (select distinct inst_id,
                             sid,
                             serial#,
                             request_id,
                             max(v_timestamp) over() as max_timestamp
               from system.fnd_concurrent_sessions)
    on inst_id = instance_number
   and sid = session_id
   and serial# = session_serial#
   and max_timestamp > min_sample_time - 1
  left join apps.fnd_concurrent_requests using (request_id)
  left join (select distinct concurrent_program_id,
                             concurrent_program_id || ', ' || USER_CONCURRENT_PROGRAM_NAME as CONCURRENT_PROGRAM_NAME
               from apps.fnd_concurrent_programs_vl)
    using (concurrent_program_id)
  left join (select distinct c.request_id, b.user_concurrent_queue_name as cm_name
              from apps.fnd_concurrent_processes a,
                   apps.fnd_concurrent_queues_vl b,
                   apps.fnd_concurrent_requests  c
             where a.concurrent_queue_id = b.concurrent_queue_id
               and a.concurrent_process_id = c.controlling_manager)
    using (request_id)
 group by CONCURRENT_PROGRAM_NAME
        , case when upper('&5') like '%MOD%' then q.module else '' end
        , case when upper('&5') like '%SERV%' then q.service else '' end
        , case when upper('&5') like '%CMAN%' then cm_name else '' end
 having sum(ash_rows) > &6
 order by sum(ash_rows) desc
/
