--
-- EBS concurrent analysis from DBA_HIST_ASH
-- Usage: SQL> @oebs_conc_hist19 91607965    999
--                               ^request_id ^min_ash_rows4display
--

set echo off feedback off heading on timi off pages 1000 lines 1000 VERIFY OFF

col INST_ID for 9999999
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


col DBID        new_value v_DBID noprint
col min_snap_id new_value v_min_snap_id noprint
col max_snap_id new_value v_max_snap_id noprint

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
       start with request_id in  ('&1')
        connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null
        and module not like 'oratop@%')
select DBID--, con_id
       , min(snap_id) as min_snap_id, max(snap_id) as max_snap_id
        from dba_hist_snapshot, sids
       where (min_timestamp between begin_interval_time and end_interval_time
              OR max_timestamp between begin_interval_time and end_interval_time
              OR max_timestamp > end_interval_time and end_interval_time = (select max(end_interval_time) from dba_hist_snapshot))
group by DBID--, con_id
/
--select &v_DBID, &v_min_snap_id, &v_max_snap_id from dual;
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
       start with request_id in  ('&1')
        connect by nocycle parent_request_id = prior request_id and b.RESUBMIT_INTERVAL is null
        and module not like 'oratop@%')
/*
, snaps as (select --+ materialize
                   DBID, con_id, min(snap_id) as min_snap_id, max(snap_id) as max_snap_id from dba_hist_snapshot, sids
                   where (min_timestamp between begin_interval_time and end_interval_time
                          OR max_timestamp between begin_interval_time and end_interval_time
                          OR max_timestamp > end_interval_time and end_interval_time = (select max(end_interval_time) from dba_hist_snapshot) )
            group by DBID, con_id)
*/
select /*+ monitor */ * from (
select--+ cardinality(a 1e6) OPTIMIZER_FEATURES_ENABLE('12.1.0.2') use_concat
  ROOT_request_id
--, parent_request_id, request_id
--, instance_number, sid, serial#
--,decode(instr(upper('&&4'), 'SQL'), 0, 'Not Req.', sql_ID)           as sql_ID
, top_level_sql_id, a.sql_id, sql_plan_hash_value
--, sql_exec_id----, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
, dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME as PLSQL
, a.module, action, client_id
--, xid
--, event
       , count(distinct sql_exec_id) as executions
       , count(distinct session_id) as sessions
       , count(distinct request_id) as requests
       , count(distinct a.instance_number||a.sample_id) as ash_rows
       , round(count(distinct a.instance_number||a.sample_id)/decode(count(distinct sql_exec_id),0,1,count(distinct sql_exec_id))) as per_execs
       , max(sample_time)-min(sample_time) as rough_duration
       , min(sample_time)
       , max(sample_time)
       , to_char(RATIO_TO_REPORT(count(distinct a.instance_number||a.sample_id)) OVER() * 100, '990.99') AS "DBTime%"
       , replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ') as SQL_TEXT
       , replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ') as TOP_SQL_TEXT
, min(snap_id), max(snap_id)
  from AWR_CDB_ACTIVE_SESS_HISTORY a
  join sids s on ((a.instance_number, a.session_id, a.session_serial#) in ((s.inst_id, s.sid, s.serial#)) or (qc_instance_id, qc_session_id, qc_session_serial#) in ((s.inst_id, s.sid, s.serial#)))
and a.SAMPLE_TIME between min_timestamp and max_timestamp
  left join dba_procedures   dp on OBJECT_ID = PLSQL_ENTRY_OBJECT_ID and SUBPROGRAM_ID = PLSQL_ENTRY_SUBPROGRAM_ID
  left join dba_hist_sqltext t  on t.sql_id  = a.sql_id
  left join dba_hist_sqltext t2 on t2.sql_id = a.top_level_sql_id
where snap_id between &v_min_snap_id and &v_max_snap_id and a.dbid = &v_DBID
group by
  ROOT_request_id
--, request_id, parent_request_id
--, instance_number, sid, serial#
, top_level_sql_id, a.sql_id, sql_plan_hash_value
--, sql_exec_id----, PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID--, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
, dp.owner||'.'||dp.object_name||'.'||dp.PROCEDURE_NAME
, a.module, action, client_id
--, xid
--, event
         , replace(replace(dbms_lob.substr(t.SQL_TEXT,200),chr(10),' '),chr(13),' ') 
         , replace(replace(dbms_lob.substr(t2.SQL_TEXT,200),chr(10),' '),chr(13),' ')
order by count(distinct a.instance_number||a.sample_id) desc--max(sample_time) desc--
) where ash_rows >= nvl(&2, 10)
/
set feedback on echo off VERIFY ON
