-- Baseline hints list for Oracle 12c
-- Usage: SQL> @bl12_hints SQL_PLAN_acg49cdw0088v4085ecd2
-- use SPB12.SQL for 11g and 12c Baselines
--
set verify off feedback off timi off lines 500
col OUTLINE_HINTS for a300

select substr(extractvalue(value(d), '/hint'), 1, 512) as outline_hints
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from sys.sqlobj$plan op, sys.sqlobj$ o
                  where o.obj_type = 2
                    and op.obj_type = 2
                    and o.name = '&&1'
                    and o.signature = op.signature
                    and o.plan_id   = op.plan_id
                    and op.other_xml is not null)) d
/
SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
'   sql_profile:     ' || extractvalue(xmlval, '/*/info[@type = "sql_profile"]')||'
   sql_patch:       ' || extractvalue(xmlval, '/*/info[@type = "sql_patch"]')||'
   baseline:        ' ||   extractvalue(xmlval, '/*/info[@type = "baseline"]')||'
   outline:         ' ||   extractvalue(xmlval, '/*/info[@type = "outline"]')||'
   dyn_sampling:    ' ||   extractvalue(xmlval, '/*/info[@type = "dynamic_sampling"]')||'
   dop:             ' ||   extractvalue(xmlval, '/*/info[@type = "dop"]')||'
   dop_reason:      ' ||   extractvalue(xmlval, '/*/info[@type = "dop_reason"]')--||'
--   pdml_reason:     ' ||   extractvalue(xmlval, '/*/info[@type = "pdml_reason"]')||'
--   idl_reason:      ' ||   extractvalue(xmlval, '/*/info[@type = "idl_reason"]')||'
--   queuing_reason:  ' ||   extractvalue(xmlval, '/*/info[@type = "queuing_reason"]')||'
--   px_in_memory:    ' ||   extractvalue(xmlval, '/*/info[@type = "px_in_memory"]')||'
--   px_in_memory_imc:' ||   extractvalue(xmlval, '/*/info[@type = "px_in_memory_imc"]')||'
--   row_shipping:    ' ||   extractvalue(xmlval, '/*/info[@type = "row_shipping"]')||'
--   index_size:      ' ||   extractvalue(xmlval, '/*/info[@type = "index_size"]')||'
--   result_checksum: ' ||   extractvalue(xmlval, '/*/info[@type = "result_checksum"]')
||'
   card_feedback:   ' ||   extractvalue(xmlval, '/*/info[@type = "cardinality_feedback"]')||'
   perf_feedback:   ' ||   extractvalue(xmlval, '/*/info[@type = "performance_feedback"]')--||'
--   xml_suboptimal:  ' ||   extractvalue(xmlval, '/*/info[@type = "xml_suboptimal"]')
||'
   adaptive_plan:   ' || extractvalue(xmlval, '/*/info[@type = "adaptive_plan"]')||'
   spd_used:        ' || extractvalue(xmlval, '/*/spd/cu')||'
   spd_valid:       ' || extractvalue(xmlval, '/*/spd/cv')||'
   gtt_sess_stat:   ' || extractvalue(xmlval, '/*/info[@type = "gtt_session_st"]')||'
   db_version:      ' || extractvalue(xmlval, '/*/info[@type = "db_version"]')||'
   plan_hash_full:  ' || extractvalue(xmlval, '/*/info[@type = "plan_hash_full"]')||' 
   plan_hash:       ' || extractvalue(xmlval, '/*/info[@type = "plan_hash"]')||'
   plan_hash_2:     ' || extractvalue(xmlval, '/*/info[@type = "plan_hash_2"]')		 as "Notes"
from
 (select xmltype(other_xml) as xmlval
                   from sys.sqlobj$plan op, sys.sqlobj$ o
                  where o.obj_type = 2
                    and op.obj_type = 2
                    and o.name = '&&1'
                    and o.signature = op.signature
                    and o.plan_id   = op.plan_id
                    and op.other_xml is not null)
/

set verify on feedback on timi on