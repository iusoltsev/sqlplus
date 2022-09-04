--
-- EBS concurrent tree analysis from ROOT concurrent_id
-- Usage: SQL> @oebs_cr_tree 141779592
--                           ^Root Concurrent_id
--
col request_id for a30
col LVL for a3

with sids as
      (select /*+ materialize */
       distinct
       LEVEL as LVL,
       request_id,
       (select distinct CONCURRENT_PROGRAM_NAME||'|'||USER_CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl
         where concurrent_program_id = b.concurrent_program_id and rownum <= 1) as CONCURRENT_PROGRAM_NAME,
       parent_request_id,
       --module, action, client_identifier
       CONNECT_BY_ROOT request_id as ROOT_request_id,
       inst_id,
       sid,
       serial#,
       min(v_timestamp) over () as min_timestamp
       , case when STATUS_CODE='R' then sysdate
              when STATUS_CODE in ('C','X','E','G') then actual_completion_date
              else max(v_timestamp) over () end as max_timestamp
       from system.fnd_concurrent_sessions join apps.fnd_concurrent_requests b using (request_id,parent_request_id)
       start with request_id in  (&1)
        connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null
        and module not like 'oratop@%')
select 
       LEVEL as LVL,
--       CONNECT_BY_ISCYCLE as ISCYCLE,
       LPAD(' ',(LEVEL-1)*2)||request_id as request_id,
       CONCURRENT_PROGRAM_NAME,
       parent_request_id,
       --module, action, client_identifier
       CONNECT_BY_ROOT request_id as ROOT_request_id,
       inst_id,
       sid,
       serial#,
       min_timestamp,
       max_timestamp
 from sids
       start with request_id in  (&1)
        connect by nocycle parent_request_id = prior request_id
/