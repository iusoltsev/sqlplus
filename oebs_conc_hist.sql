--
-- EBS concurrent most expensive SQL_ID list from DBA_HIST_ASH
-- Usage: SQL> @oebs_conc_hist 79781823 5
--                        ^request_id ^min_ash_rows
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID for 9999999
col BLOCK_INST for 9999999999
col LVL for 999
col BLOCKING_TREE for a30
col EVENT for a64
col WAITS for 999999
col AVG_WAIT_TIME_MS for 999999
col SQL_ID for a13
col SQL_OPNAME for a20
col SQL_TEXT for a200
/*
with sids as 
(select /*+ materialize  distinct request_id, parent_request_id, inst_id, sid, serial#, min(v_timestamp) over () as min_timestamp, max(v_timestamp) over () as max_timestamp from system.fnd_concurrent_sessions join apps.fnd_concurrent_requests b using (request_id,parent_request_id)
 start with request_id = &1
  connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null)
, snaps as (select --+ materialize
                   min(snap_id) as min_snap_id, max(snap_id) as max_snap_id from dba_hist_snapshot, sids
                   where (min_timestamp between begin_interval_time and end_interval_time OR max_timestamp between begin_interval_time and end_interval_time))
select parent_request_id, request_id, a.instance_number, top_level_sql_id, a.sql_id, sql_plan_hash_value, client_id, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
       , module, action
       , count(distinct sql_exec_id)     as EXEC_COUNT
       , count(distinct session_id)      as SID_COUNT
       , count(*)                        as ASH_ROWS
       , min(sample_id)                  as MIN_SAMPLE_ID
       , min(sample_time)                as MIN_SAMPLE_TIME
       , max(sample_id)                  as MAX_SAMPLE_ID
       , max(sample_time)                as MAX_SAMPLE_TIME
       , min(snap_id)                    as MIN_SNAP_ID
       , max(snap_id)                    as MAX_SNAP_ID
       , dbms_lob.substr(t.SQL_TEXT,200) as SQL_TEXT
  from dba_hist_active_sess_history a
  join sids s on ((a.instance_number, a.session_id, a.session_serial#) in ((s.inst_id, s.sid, s.serial#)) or (qc_instance_id, qc_session_id, qc_session_serial#) in ((s.inst_id, s.sid, s.serial#)))
  join snaps on 1=1
  left join dba_hist_sqltext t on t.sql_id = (nvl(a.sql_id, a.top_level_sql_id))
where snap_id between snaps.min_snap_id and snaps.max_snap_id+100
group by parent_request_id, request_id, a.instance_number, top_level_sql_id, a.sql_id, sql_plan_hash_value, client_id, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
         , module, action
         , dbms_lob.substr(t.SQL_TEXT,200)
 having count(*) > nvl('&2', 5)
order by max(sample_time)--count(*)
 desc--
*/
with sids as 
--(select * from 
(select /*+ materialize */ --request_id, parent_request_id, inst_id, sid, serial#, --module, action, client_identifier, v_timestamp
distinct module,
 request_id, parent_request_id, inst_id, sid, serial#, min(v_timestamp) over () as min_timestamp
 , case when STATUS_CODE='R' then sysdate
        when STATUS_CODE='C' then actual_completion_date
        else max(v_timestamp) over () end as max_timestamp
 from system.fnd_concurrent_sessions join apps.fnd_concurrent_requests b using (request_id,parent_request_id)
 start with request_id --=  77631561 --77441338--77432091--76842486--
 in (&1)--(79781822)--(79597051)--
  connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null
  and module not like 'oratop@%'
--  and module = 'e:PER:cp:xxya/XXHR_PAYSLIP'
)
--select * from sids --where module = 'e:PER:cp:xxya/XXHR_PAYSLIP'
, snaps as (select --+ materialize
                   DBID, min(snap_id) as min_snap_id, max(snap_id) as max_snap_id from dba_hist_snapshot, sids
                   where (min_timestamp between begin_interval_time and end_interval_time
                          OR max_timestamp between begin_interval_time and end_interval_time
                          OR max_timestamp > end_interval_time and end_interval_time = (select max(end_interval_time) from dba_hist_snapshot) )
and module not like 'oratop@%' group by DBID)
, a as (select /*+ index(ash WRH$_ACTIVE_SESSION_HISTORY_PK) materialize*/ ash.* from dba_hist_active_sess_history ash, snaps where snap_id between snaps.min_snap_id and snaps.max_snap_id+10 and snaps.DBID = ash.DBID)
--select * from snaps
select-- parallel
-- parent_request_id, request_id,
request_id, parent_request_id, inst_id, sid, serial#,
 top_level_sql_id, a.sql_id, sql_plan_hash_value, client_id--, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
--       , dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME as PLSQL
--       , a.module, action
, event
       , count(distinct sql_exec_id) as executions
       , count(distinct session_id) as sessions
       , count(*) as ash_rows
       , round(count(*)/decode(count(distinct sql_exec_id),0,1,count(distinct sql_exec_id))) as per_execs
       , max(sample_time)-min(sample_time) as duration
       , min(sample_time)
       , max(sample_time)
       , to_char(RATIO_TO_REPORT(count(*)) OVER() * 100, '990.99') AS "DBTime%"
       , to_char(RATIO_TO_REPORT(count(distinct a.instance_number||a.sample_id)) OVER() * 100, '990.99') AS "Time%"
       , replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ') as SQL_TEXT
       , replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ') as TOP_SQL_TEXT
, min(snap_id), max(snap_id)
  from  a
  join sids s on ((a.instance_number, a.session_id, a.session_serial#) in ((s.inst_id, s.sid, s.serial#)) or (qc_instance_id, qc_session_id, qc_session_serial#) in ((s.inst_id, s.sid, s.serial#)))
and a.SAMPLE_TIME between min_timestamp and max_timestamp  
--  join snaps on 1=1
  left join dba_procedures dp on OBJECT_ID = PLSQL_ENTRY_OBJECT_ID and SUBPROGRAM_ID = PLSQL_ENTRY_SUBPROGRAM_ID
  left join dba_hist_sqltext t  on t.sql_id  = a.sql_id
  left join dba_hist_sqltext t2 on t2.sql_id = a.top_level_sql_id
--where snap_id between snaps.min_snap_id and snaps.max_snap_id+10
----and sample_time between to_date('27.03 00:49','dd.mm hh24:mi') and to_date('27.03 08:28','dd.mm hh24:mi')
--and module not like 'oratop@%'
group by --parent_request_id, request_id,
request_id, parent_request_id, inst_id, sid, serial#,
 top_level_sql_id, a.sql_id, sql_plan_hash_value, client_id--, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
, event
--         , dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME
--         , a.module, action
         , replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ') 
         , replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ')
 having count(*) > nvl('&2', 5)
order by count(distinct a.instance_number||a.sample_id) desc--min(sample_time)--
/
set feedback on echo off VERIFY ON