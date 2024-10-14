with q as
 (select /*+ materialize*/
  distinct sql_id, plan_hash_value
    from dba_hist_sql_plan
   where object_name = '&I_THIRDPARTY_TRANS_UNI1')
select sql_id,
       plan_hash_value,
       sum(EXECUTIONS_DELTA),
       sum(ROWS_PROCESSED_DELTA),
       sum(ELAPSED_TIME_DELTA),
       dbms_lob.substr(sql_text, 1000) as sql_text
  from dba_hist_sqlstat
  left join dba_hist_sqltext
 using (dbid, sql_id)
 where (sql_id, plan_hash_value) in (select sql_id, plan_hash_value from q)
   and snap_id between &283399 and &287943
 group by sql_id, plan_hash_value, dbms_lob.substr(sql_text, 1000)
/