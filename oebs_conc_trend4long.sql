--
-- EBS concurrent evg.time trend analysis from DBA_HIST_ASH by Month or Days (w/o PARENT)
-- Usage: SQL> @oebs_conc_trend4long "522703,556712"               [10]                                 [mm|dd]                     "801, 2484%"                  7200
--                                     ^Concurrent_Program_id List  ^Deep in days (default 365, 1 year)  ^group by by Month or Days ^ARGUMENT_TEXT in LIKE format ^min request duration in seconds
--

set echo off feedback off heading on timi off pages 1000 lines 2000 VERIFY OFF

col CONCURRENT_PROGRAM_NAME for a200
col REQ_LIST for a200


with r as (select * from apps.fnd_concurrent_requests where concurrent_program_id in (&1)
           and nvl(actual_completion_date,sysdate) > trunc(sysdate-nvl(to_number('&2'),365),nvl('&3','mm'))
           and nvl(ARGUMENT_TEXT,'0') like decode('&4','0','%','&4')
and (nvl(actual_completion_date,sysdate) - actual_start_date) * 86400 > &5 )
--select * from r
, q as (select concurrent_program_id, -- ROOT requests list!
                   --CONNECT_BY_ROOT
                    request_id as ROOT_request_id,
                   request_id,
                   actual_start_date,
                   actual_completion_date
, status_code
, round((nvl(actual_completion_date,sysdate) - actual_start_date) * 86400) as Duration_s
              from r
                    --where connect_by_isleaf = 0 or connect_by_isleaf = 1 and parent_request_id = -1
                    --connect by nocycle parent_request_id = prior request_id  and RESUBMIT_INTERVAL is null
            )--select * from q ---where ROOT_request_id = 100059475
select trunc(actual_completion_date, nvl('&3','mm')) as month,
       concurrent_program_id,
       (select distinct CONCURRENT_PROGRAM_NAME||'|'||USER_CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl
         where concurrent_program_id = q.concurrent_program_id and rownum <= 1) as CONCURRENT_PROGRAM_NAME,
       count(distinct ROOT_request_id) as REQ_COUNT,
       round(avg(actual_completion_date - actual_start_date) * 86400) as avg_duration_secs,
       round(sum(actual_completion_date - actual_start_date) * 86400) as sum_duration_secs
, substr(LISTAGG (distinct ROOT_request_id|| ':' || status_code || '('||round((actual_completion_date - actual_start_date) * 86400)||' s)', '; ' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (ORDER BY round((actual_completion_date - actual_start_date) * 86400) desc),1,200) as REQ_LIST
  from q
 where ROOT_request_id in
       (select request_id
          from APPLSYS.fnd_concurrent_requests
         where status_code in ('C', 'G'
, 'X','E'))
 group by trunc(actual_completion_date, nvl('&3','mm')), concurrent_program_id
order by 2, 1
/
set feedback on echo off VERIFY ON
