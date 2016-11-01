--
-- PL/SQL trace with recursive SQL Plan Statistics from ASH history (including recursive queries and PL/SQL)
-- Usage: SQL> @ash_plsqlmon_hist 5t39uchjqpyfm 73250       [73252]
--                                ^sql_id       ^start_snap ^stop_snap
-- 

set feedback on heading on timi off pages 500 lines 500 echo off  VERIFY OFF

col PLAN_OPERATION for a180
col WAIT_PROFILE for a200
col SQL_TEXT for a80
col MIN_TIME for a8
col MAX_TIME for a8

PROMPT
PROMPT ***** Summary by SQL execs *****

with hash as (select /*+ INLINE*/ * from dba_hist_active_sess_history
              where (sql_id = '&&1' or top_level_sql_id = '&&1') and ('&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2')))
, ash as (
  select count(distinct sh.session_id||sh.session_serial#) as SID_COUNT,
         PLSQL_ENTRY_OBJECT_ID,
         PLSQL_ENTRY_SUBPROGRAM_ID,
         sh.SQL_ID,
         nvl(sql_plan_hash_value, 0)                         as SQL_PLAN_HASH_VALUE,
         decode(session_state,'WAITING',event,session_state) as EVENT,
         count(*)                                            as WAIT_COUNT,
         count( distinct SQL_EXEC_ID)                        as EXECS,
         MIN(SAMPLE_TIME)                                    as MIN_SAMPLE_TIME,
         max(SAMPLE_TIME)                                    as MAX_SAMPLE_TIME
    from hash sh
   group by sh.sql_id, nvl(sql_plan_hash_value, 0), decode(session_state,'WAITING',event,session_state),PLSQL_ENTRY_OBJECT_ID,PLSQL_ENTRY_SUBPROGRAM_ID)
select  sql_id,
        sql_plan_hash_value,
        sum(WAIT_COUNT)                                         as ASH_ROWS,
        max(EXECS)                                              as EXECS,
        to_char(min(min_sample_time),'hh24:mi:ss')              as MIN_TIME,
        to_char(max(max_sample_time),'hh24:mi:ss')              as MAX_TIME,
        trim(replace(replace(replace(dbms_lob.substr(sql_text,80),chr(10)),chr(13)),chr(9))) as sql_text,
        substr(rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT, '); ').extract('//text()') order by WAIT_COUNT desc),'; '),1,200) as WAIT_PROFILE
from ash left join dba_hist_sqltext using (sql_id)
group by sql_id,
         sql_plan_hash_value,
         trim(replace(replace(replace(dbms_lob.substr(sql_text,80),chr(10)),chr(13)),chr(9)))
order by sum(WAIT_COUNT) desc
/

PROMPT
PROMPT
PROMPT ***** SQL Plan/PLSQL execs details *****

with 
hash as (select /*+ INLINE*/ * from dba_hist_active_sess_history
              where (sql_id = '&&1' or top_level_sql_id = '&&1') and ('&&2' is null OR snap_id between '&&2' and nvl('&&3', '&&2'))),
ash as
 (select count(distinct sh.session_id || sh.session_serial#) as SID_COUNT,
         PLSQL_ENTRY_OBJECT_ID,
         PLSQL_ENTRY_SUBPROGRAM_ID,
         sh.SQL_ID,
         nvl(sql_plan_hash_value, 0) as SQL_PLAN_HASH_VALUE,
         nvl(sql_plan_line_id, 0) as SQL_PLAN_LINE_ID,
         decode(session_state, 'WAITING', event, session_state) as EVENT,
         count(*) as WAIT_COUNT,
         count(distinct SQL_EXEC_ID) as EXECS,
         min(sample_time) as MIN_SAMPLE_TIME,
         max(sample_time) as MAX_SAMPLE_TIME
    from hash sh
   group by sh.sql_id,
            nvl(sql_plan_hash_value, 0),
            nvl(sql_plan_line_id, 0),
            decode(session_state, 'WAITING', event, session_state),
            PLSQL_ENTRY_OBJECT_ID,
            PLSQL_ENTRY_SUBPROGRAM_ID),
ash_stat as
 (                                     -- all SQL exec stats
  select sql_id,
         sql_plan_hash_value,
         sql_plan_line_id,
         PLSQL_ENTRY_OBJECT_ID,
         PLSQL_ENTRY_SUBPROGRAM_ID,
         sum(WAIT_COUNT) as ASH_ROWS,
         substr(rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT, '); ').extract('//text()') order by WAIT_COUNT desc),'; '),1,200) as WAIT_PROFILE,
         max(EXECS) as EXECS,
         max(MAX_SAMPLE_TIME) as MAX_SAMPLE_TIME
    from ash
   group by sql_id,
             sql_plan_hash_value,
             sql_plan_line_id,
             PLSQL_ENTRY_OBJECT_ID,
             PLSQL_ENTRY_SUBPROGRAM_ID),
pt as                                  -- Plan Tables for all excuted SQLs (direct+recursive)
 (select sql_id,
          plan_hash_value,
          id,
          operation,
          options,
          object_owner,
          object_name,
          qblock_name,
          nvl(parent_id, -1) as parent_id
    from dba_hist_sql_plan
   where (sql_id, plan_hash_value) in
         (select sql_id, sql_plan_hash_value from ash)
  union all                            -- for plans not in dba_hist_sql_plan yet
  select distinct sql_id,
                  plan_hash_value,
                  id,
                  operation,
                  options,
                  object_owner,
                  object_name,
                  qblock_name,
                  nvl(parent_id, -1) as parent_id
    from gv$sql_plan
   where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)
     and not exists
        (select 1 from dba_hist_sql_plan where (sql_id, plan_hash_value) in (select sql_id, sql_plan_hash_value from ash)))
SELECT                                 -- standard recursive SQLs 
       decode(pt.id, 0, 'SQL Query', null)        as SQL_PLSQL,
       decode(pt.id, 0, pt.sql_id, null)          as SQL_ID,
       decode(pt.id, 0, pt.plan_hash_value, null) as PLAN_HASH_VALUE,
       pt.id,
       lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as PLAN_OPERATION,
       pt.object_owner,
       pt.object_name,
       pt.qblock_name,
       ash_stat.EXECS,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  FROM pt
  left join ash_stat
    on pt.id = NVL(ash_stat.sql_plan_line_id, 0)
   and pt.sql_id = ash_stat.sql_id
   and pt.plan_hash_value = ash_stat.sql_plan_hash_value
 where pt.sql_id in (select sql_id from ash_stat)
CONNECT BY PRIOR pt.id = pt.parent_id
       and PRIOR pt.sql_id = pt.sql_id
       and PRIOR pt.plan_hash_value = pt.plan_hash_value
 START WITH pt.id = 0
UNION ALL
select 'PL/SQL' as SQL_PLSQL,          -- non-identified by SQL or PLSQL exec stats
       sql_id,
       ash_stat.sql_plan_hash_value as plan_hash_value,
       ash_stat.sql_plan_line_id,
       nvl2(p.object_name, p.owner||'.'||p.object_name||'.'||p.procedure_name||'"', trim(replace(replace(replace(dbms_lob.substr(sql_text,80),chr(10)),chr(13)),chr(9)))) as PLAN_OPERATION,
       null,
       null,
       null,
       ash_stat.EXECS,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  from ash_stat left join dba_hist_sqltext using (sql_id)
                left join dba_procedures p on ash_stat.PLSQL_ENTRY_OBJECT_ID = p.object_id and ash_stat.PLSQL_ENTRY_SUBPROGRAM_ID = p.subprogram_id
 where sql_id is null
    or (sql_plan_hash_value = 0 and sql_id not in (select sql_id from pt))
UNION ALL
select 'SQL w/o plan' as SQL_PLSQL,    -- SQL with non-identified plan stats
       sql_id,
       ash_stat.sql_plan_hash_value as plan_hash_value,
       ash_stat.sql_plan_line_id,
       trim(replace(replace(replace(dbms_lob.substr(sql_text,80),chr(10)),chr(13)),chr(9))) as PLAN_OPERATION,
       null,
       null,
       null,
       ash_stat.EXECS,
       ash_stat.ASH_ROWS,
       ash_stat.WAIT_PROFILE
  from ash_stat left join dba_hist_sqltext using (sql_id)
 where sql_id not in (select sql_id from pt)
   and sql_id is not null
   and sql_plan_hash_value != 0
/
set VERIFY ON timi on