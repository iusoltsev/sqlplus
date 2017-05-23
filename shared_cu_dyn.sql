--
-- SQL child cursor generation properties for 11.2.0.2+
-- Usage: 
-- SQL> @shared_cu_dyn &sql_id
--

set feedback off heading on timi off pages 200 lines 500 echo off  VERIFY OFF

select sql_id, count(*) from gv$sql group by sql_id order by count(*) desc
select * from gv$SQL_SHARED_CURSOR where sql_id='gqb4cqtnnp23s'

var c refcursor
declare
q_text varchar2(32000);
begin
SELECT 'select child_number, data, col from (select * from gv$SQL_SHARED_CURSOR where sql_id=''5duffr40wbxk7'') UNPIVOT (col FOR data IN ( ' ||
rtrim(listagg( column_name || ',' ) WITHIN GROUP (order by column_id), ',') ||
')) where col = ''Y'''
into q_text
  FROM dba_tab_columns
 WHERE table_name = 'V_$SQL_SHARED_CURSOR'
   AND data_type = 'VARCHAR2'
   AND data_length = 1;
open :c for q_text;
end;
/
print c;

var c refcursor
declare
q_text varchar2(32000);
begin
SELECT 'select inst_id, child_number, listagg(data, '' '') from (select * from gv$SQL_SHARED_CURSOR where sql_id=''5duffr40wbxk7'') UNPIVOT (col FOR data IN ( ' ||
rtrim(listagg( column_name || ',' ) WITHIN GROUP (order by column_id), ',') ||
')) where col = ''N'' and child_number = 0'
into q_text
  FROM dba_tab_columns
 WHERE table_name = 'V_$SQL_SHARED_CURSOR'
   AND data_type = 'VARCHAR2'
   AND data_length = 1;
open :c for q_text;
end;
/
print c;

select inst_id, child_number, data
  from (select * from gv$SQL_SHARED_CURSOR where sql_id = '5duffr40wbxk7') UNPIVOT(col FOR data IN('OPTIMIZER_MISMATCH',
                                                                                                   'OUTLINE_MISMATCH'))

/*

col INST for 9999
col EXECS for 99999999
col CHILD for 99999
col BIND_SENSE for a10
col BIND_AWARE for a10
col SHAREABLE for a10
col USE_FEEDBACK_STATS for a18
col OPTIMIZER_STATS for a16
col BIND_EQ_FAILURE for a16
col Reason1 for a60
col SQL_PLAN_BASELINE for a30
col SQL_PATCH for a30
col SQL_PROFILE for a64
col ROLL for a4
col REOPT for a5
col ADAPT for a5
col FIRST_LOAD_TIME for a20
col LAST_LOAD_TIME for a20
col PARSE_USER for a30

select s.inst_id as INST,
       s.EXECUTIONS as EXECS,
       s.users_opening,
       s.first_load_time,
       s.last_load_time,
      (select username from dba_users where user_id = s.parsing_user_id) as PARSE_USER,
       to_char(s.last_active_time, 'dd.mm.yyyy hh24:mi:ss') as last_active_time,
       round(s.elapsed_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)) as ELA_PER_EXEC,
       s.object_status,
       s.PLAN_HASH_VALUE,
       s.FULL_PLAN_HASH_VALUE,
       s.optimizer_cost,
       s.child_number as CHILD,
       s.IS_BIND_SENSITIVE as "BIND_SENSE",
       s.IS_BIND_AWARE as "BIND_AWARE",
       s.IS_SHAREABLE as "SHAREABLE",
       use_feedback_stats as USE_FEEDBACK_STATS,
       s.IS_REOPTIMIZABLE as "REOPT",
       (select count(*) from gv$sql_reoptimization_hints rh where rh.sql_id = s.sql_id and rh.child_number = s.child_number) as REOPT_HINTS,
--       s.IS_RESOLVED_ADAPTIVE_PLAN as "ADAPT",
       case when s.IS_RESOLVED_ADAPTIVE_PLAN is null then 'N' when s.IS_RESOLVED_ADAPTIVE_PLAN = 'N' then '' else 'Y' end as "ADAPT",
      (SELECT 'valid:' || extractvalue(xmlval, '/#/spd/cv') || '; used:' ||-----*
             extractvalue(xmlval, '/#/spd/cu')-----*
        from (select xmltype(other_xml) xmlval
                from gv$sql_plan p
               where p.inst_id(+) = s.inst_id
                 and p.child_address = s.child_address
                 and p.sql_id = s.sql_id
                 and p.other_xml is not null)) as SQL_PLAN_DIRECTIVES,
       load_optimizer_stats as OPTIMIZER_STATS,
       bind_equiv_failure as BIND_EQ_FAILURE,
       ROLL_INVALID_MISMATCH as "ROLL",
       (select reasons || '  |  ' || details
          from xmltable('/ChildNode' passing
                        (select case when dbms_lob.instr(reason, '<ChildNode>', 1, 2) = 0
                                       then xmltype(reason)
                                     when dbms_lob.instr(reason, '<ChildNode>', 1, 2) > 4000
                                       then xmltype(dbms_lob.substr(reason, dbms_lob.instr(reason, '</reason>', 1, 1) + 8) || '</ChildNode>')
                                  else xmltype(dbms_lob.substr(reason, dbms_lob.instr(reason, '<ChildNode>', 1, 2) - 1))
                                  end as xmlval
                           from gv$sql_shared_cursor
                          where dbms_lob.substr(reason, 256) <> ' '
                            and sql_id = sc.sql_id
                            and inst_id = sc.inst_id
                            and child_address = sc.child_address)
                        columns Reasons varchar2(4000) path '/ChildNode/reason',
                                Details varchar2(4000) path '/ChildNode/details')) as Reason1,
       SQL_PLAN_BASELINE,
       SQL_PATCH,
       OUTLINE_CATEGORY,
       SQL_PROFILE,
       IS_OBSOLETE
  from gv$sql_shared_cursor sc,
       gv$sql s
 where sc.sql_id = '&1'
   and sc.inst_id = s.inst_id
   and sc.child_address = s.child_address
   and sc.sql_id = s.sql_id
order by s.inst_id, s.last_active_time
/
*/
set feedback on VERIFY ON
