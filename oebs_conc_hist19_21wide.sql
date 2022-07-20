--
-- EBS concurrent analysis from DBA_HIST_ASH
-- Usage: SQL> @oebs_conc_hist19_21 91911537    [SQL]|TOP|REQ|SID|MOD|"PL/"|INST [10]
--                                 ^Request_id  ^FieldSelector    ^topN_sql
--

set echo off feedback off heading on timi off pages 1000 lines 2000 VERIFY OFF

col INST for 9999
col BLOCK_INST for 9999999999
col LVL for 999
col BLOCKING_TREE for a30
col EVENT for a64
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col SQL_ID for a13
col SQL_OPNAME for a20
col PLSQL for a60
col CLIENT_ID for a30
col SQL_TEXT for a200
col TOP_SQL_TEXT for a200
col WAIT_PROFILE for a200
col PARENT_REQUEST_ID for 99999999999
col PARENT_ID         for 99999999999
col SID for 999999
col SERIAL for 99999999
col actual_start_date for a20
col actual_completion_date for a20

DEFINE v_DBID = 0
DEFINE v_min_snap_id = 0
DEFINE v_max_snap_id = 0

col DBID        new_value v_DBID noprint
col min_snap_id new_value v_min_snap_id noprint
col max_snap_id new_value v_max_snap_id noprint

select parent_request_id, request_id,
       concurrent_program_id,
       actual_start_date,
       actual_completion_date
      ,(select distinct CONCURRENT_PROGRAM_NAME||'|'||USER_CONCURRENT_PROGRAM_NAME from apps.fnd_concurrent_programs_vl
         where concurrent_program_id = q.concurrent_program_id and rownum <= 1) as CONCURRENT_PROGRAM_NAME
  from apps.fnd_concurrent_requests q
 where request_id in (&1)
/
with sids as
      (select /*+ materialize */
       distinct module,
       CONNECT_BY_ROOT request_id as ROOT_request_id,
       request_id,
       parent_request_id,
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
, minmax_timestamp as (select min(min_timestamp) as min_timestamp, max(max_timestamp) as max_timestamp from sids)
--select * from minmax_timestamp
select-- monitor
        DBID--, con_id
      , min(snap_id) as min_snap_id
      , max(snap_id) as max_snap_id
        from dba_hist_snapshot, minmax_timestamp
       where (min_timestamp between begin_interval_time and end_interval_time
              OR max_timestamp between begin_interval_time and end_interval_time
              OR max_timestamp > end_interval_time and end_interval_time = (select max(end_interval_time) from dba_hist_snapshot))
and dbid = sys_context ('userenv','DBID')
group by DBID--, con_id
/
select &v_DBID, &v_min_snap_id, &v_max_snap_id from dual
/
--------------------------------------------------------------------------------------------------------------------------------
create table system.ash_pr_sids_&req tablespace users as
select /*+  */ distinct CONNECT_BY_ROOT request_id as ROOT_request_id, request_id, parent_request_id, inst_id, sid, serial#, min(v_timestamp) over () as min_timestamp, max(v_timestamp) over () as max_timestamp
 from system.fnd_concurrent_sessions join apps.fnd_concurrent_requests b using (request_id,parent_request_id)
 start with request_id =  &req--75781740--74455005--74454996 --
  connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null
/
select *--count(*)--
 from system.ash_pr_sids_&req
/
select min(min_timestamp), max(max_timestamp), count(distinct inst_id||'*'||sid||'*'||serial#) from system.ash_pr_sids_&req where sid is not null
/
MIN(MIN_TIMESTAMP)	MAX(MAX_TIMESTAMP)	COUNT(DISTINCTINST_ID||'*'||SID||'*'||SERIAL#)
24.09.20 22:29:56,157006	25.09.20 01:46:58,955793	14857

--29125
drop table system.ash_pr_snaps_&req
/
create table system.ash_pr_snaps_&req tablespace users as
with sids as (select /**/ min(min_timestamp) as min_timestamp, max(max_timestamp) as max_timestamp from system.ash_pr_sids_&req)
select -- parallel(8)
 min(snap_id) as min_snap_id, max(snap_id) as max_snap_id
  from dba_hist_snapshot, sids
 where (min_timestamp between begin_interval_time and end_interval_time OR
       max_timestamp between begin_interval_time and end_interval_time)
/
select * from system.ash_pr_snaps_&req
/
--create table system.ash_pr_75870485 tablespace users as
select * from(
select--+ parallel(16)
ROOT_request_id
--, parent_request_id, request_id
--, event
, a.instance_number
--, session_id, session_serial#
, top_level_sql_id, a.sql_id, sql_plan_hash_value
, client_id--, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
       , a.module, action
       , count(distinct sql_exec_id) as executions
       , count(distinct session_id||session_serial#) as sessions
       , count(distinct request_id) as requests
       , count(*) as seconds
       , to_char(RATIO_TO_REPORT(count(*)) OVER() * 100, '990.99') AS "Time%"
       , replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ') as SQL_TEXT
       , replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ') as TOP_SQL_TEXT
       , min(sample_time), min(sample_id), max(sample_time), max(sample_id), min(snap_id), max(snap_id)
  from dba_hist_active_sess_history a
  join system.ash_pr_sids_&req s on ((a.instance_number, a.session_id, a.session_serial#) in ((s.inst_id, s.sid, s.serial#)) or (qc_instance_id, qc_session_id, qc_session_serial#) in ((s.inst_id, s.sid, s.serial#)))
and a.SAMPLE_TIME between min_timestamp and max_timestamp  
  join system.ash_pr_snaps_&req snaps on 1=1
  left join dba_hist_sqltext t  on t.sql_id  = a.sql_id
  left join dba_hist_sqltext t2 on t2.sql_id = a.top_level_sql_id
where snap_id between 56426 and	56454--snaps.min_snap_id and snaps.max_snap_id+1
and module not like 'oratop@%'
--and client_id = 'YULIA-MAKEEVA'
--and client_id = 'AKIRSAN'
group by ROOT_request_id
--, parent_request_id, request_id
--, event
, a.instance_number
--, session_id, session_serial#
, top_level_sql_id, a.sql_id, sql_plan_hash_value
, client_id--, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
         , a.module, action
         , replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ') 
         , replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ')
order by count(*) desc--max(sample_time)--
) where rownum <= 16
/

set feedback on echo off VERIFY ON
