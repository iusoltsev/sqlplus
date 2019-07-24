--
-- EBS concurrent most expensive SQL_ID list from ASH
-- Usage: SQL> @oebs_conc 333222      25
--                        ^request_id ^topN
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

with sids as
 (select /*+ materialize*/ distinct inst_id, sid, serial#, min(v_timestamp), max(v_timestamp)  from system.fnd_concurrent_sessions start with request_id = &1
   connect by nocycle parent_request_id = prior request_id group by inst_id, sid, serial#)
select a.inst_id,
       a.session_id as SID,
       a.session_serial# as SERIAL#,
       sql_opname,
       a.sql_id,
       sql_plan_hash_value,
       count(distinct sql_exec_id) as EXEC_COUNT,
       count(distinct session_id)  as SID_COUNT,
       count(*)                    as ASH_ROWS,
       min(sample_time)            as min_sample_time,
       max(sample_time)            as max_sample_time,
       dbms_lob.substr(t.SQL_TEXT,200) as SQL_TEXT
  from gv$active_session_history a
  join sids s on ((a.inst_id, a.session_id, a.session_serial#) in ((s.inst_id, s.sid, s.serial#)) or (qc_instance_id, qc_session_id, qc_session_serial#) in ((s.inst_id, s.sid, s.serial#)))
  left join gv$sqlarea t on t.sql_id = (nvl(a.sql_id, a.top_level_sql_id)) and t.inst_id = a.inst_id
group by a.inst_id, a.session_id, a.session_serial#
       , a.sql_id, sql_plan_hash_value, sql_opname, dbms_lob.substr(t.SQL_TEXT,200)
 having count(*) > nvl('&2', 10)
order by count(*)--max(sample_time)
 desc
/
set feedback on echo off VERIFY ON