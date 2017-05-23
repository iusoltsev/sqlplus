--
-- High version count reason for 11.2.0.2+
-- Usage: 
-- SQL> @shared_cu &sql_id
--

set feedback off heading on pages 200 lines 600 echo off  VERIFY OFF
col INST for 9999
col EXECS for 99999999
col CHILD for 99999
col BIND_SENSE for a10
col BIND_AWARE for a10
col SHAREABLE for a10
col USE_FEEDBACK_STATS for a18
col OPTIMIZER_STATS for a16
col BIND_EQ_FAILURE for a16
col Reason for a60
col SQL_PLAN_BASELINE for a30
col SQL_PATCH for a30
col SQL_PROFILE for a64
col CF for a3

select s.inst_id as INST,
       s.EXECUTIONS as EXECS,
       to_char(to_date(s.last_load_time, 'yyyy-mm-dd/hh24:mi:ss'), 'dd.mm hh24:mi') as last_load_time,
       s.users_opening,
       to_char(s.last_active_time, 'dd.mm hh24:mi') as last_active_time,
       round(s.elapsed_time/decode(s.EXECUTIONS,0,1,s.EXECUTIONS)) as ELA_PER_EXEC,
       s.PLAN_HASH_VALUE,
       s.optimizer_cost,
       s.child_number as CHILD,
       s.IS_BIND_SENSITIVE as "BIND_SENSE",
       s.IS_BIND_AWARE as "BIND_AWARE",
       s.IS_SHAREABLE as "SHAREABLE",
       use_feedback_stats as USE_FEEDBACK_STATS,
       REGEXP_SUBSTR ( dbms_lob.substr(p.other_xml,4000), '<(info) type="cardinality_feedback">([^<]+)</\1>', 1, 1, NULL, 2) as CF,
       load_optimizer_stats as OPTIMIZER_STATS,
       bind_equiv_failure as BIND_EQ_FAILURE,
       ROLL_INVALID_MISMATCH,
       bind_uacs_diff,
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
/*
       (select reasons || '  |  ' || details
          from xmltable('/ChildNode' passing
                        (select case when dbms_lob.instr(reason, '<ChildNode>', 1, 2) = 0 then
                                   xmltype(reason)
                                  else
                                    xmltype(dbms_lob.substr(reason, dbms_lob.instr(reason, '<ChildNode>', 1, 2) - 1))
                                  end as xmlval
                           from gv$sql_shared_cursor
                          where dbms_lob.substr(reason, 256) <> ' '
                            and sql_id = sc.sql_id
                            and inst_id = sc.inst_id
                            and child_address = sc.child_address)
                        columns Reasons varchar2(60) path '/ChildNode/reason',
                        Details varchar2(60) path '/ChildNode/details')) as Reason1,
       (select reasons || '  |  ' || details
          from xmltable('/ChildNode' passing
                        (select xmltype(dbms_lob.substr(reason, dbms_lob.instr(reason, '</ChildNode>', 1, 2) - dbms_lob.instr(reason, '</ChildNode>', 1, 1), dbms_lob.instr(reason, '<ChildNode>', 1, 2)))
                           from gv$sql_shared_cursor
                          where dbms_lob.substr(reason, 256) <> ' '
                            and sql_id = sc.sql_id
                            and inst_id = sc.inst_id
                            and child_address = sc.child_address)
                        columns Reasons varchar2(60) path '/ChildNode/reason',
                        Details varchar2(60) path '/ChildNode/details')) as Reason2,
*/
       SQL_PLAN_BASELINE,
       SQL_PATCH,
       OUTLINE_CATEGORY,
       SQL_PROFILE,
       IS_OBSOLETE
  from gv$sql_shared_cursor sc, gv$sql s
 where sc.sql_id = '&1'
   and sc.inst_id = s.inst_id
   and sc.child_address = s.child_address
   and sc.sql_id = s.sql_id
   and sc.inst_id > 0
and (s.EXECUTIONS>0 or s.users_opening>0)
order by s.inst_id, --s.child_number
	s.last_active_time desc
/
set feedback on VERIFY ON timi on