--
-- SQL Plan OTHER_XML Notes Section
-- Usage: SQL> @sql_plan_notes 38dyq2ab12nju 2108937779
--                             ^SQL_ID1      ^PLAN_HASH_VALUE
-- by Igor Usoltsev
--

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

col Full_Notes for a100

SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
'   sql_profile:     ' || extractvalue(xmlval, '/*/info[@type = "sql_profile"]')||'
   sql_patch:       ' || extractvalue(xmlval, '/*/info[@type = "sql_patch"]')||'
   baseline:        ' ||   extractvalue(xmlval, '/*/info[@type = "baseline"]')||'
   outline:         ' ||   extractvalue(xmlval, '/*/info[@type = "outline"]')||'
   dyn_sampling:    ' ||   extractvalue(xmlval, '/*/info[@type = "dynamic_sampling"]')||'
   dop:             ' ||   extractvalue(xmlval, '/*/info[@type = "dop"]')||'
   dop_reason:      ' ||   extractvalue(xmlval, '/*/info[@type = "dop_reason"]')||'
   pdml_reason:     ' ||   extractvalue(xmlval, '/*/info[@type = "pdml_reason"]')||'
   idl_reason:      ' ||   extractvalue(xmlval, '/*/info[@type = "idl_reason"]')||'
   queuing_reason:  ' ||   extractvalue(xmlval, '/*/info[@type = "queuing_reason"]')||'
   px_in_memory:    ' ||   extractvalue(xmlval, '/*/info[@type = "px_in_memory"]')||'
   px_in_memory_imc:' ||   extractvalue(xmlval, '/*/info[@type = "px_in_memory_imc"]')||'
   row_shipping:    ' ||   extractvalue(xmlval, '/*/info[@type = "row_shipping"]')||'
   index_size:      ' ||   extractvalue(xmlval, '/*/info[@type = "index_size"]')||'
   result_checksum: ' ||   extractvalue(xmlval, '/*/info[@type = "result_checksum"]')||'
   card_feedback:   ' ||   extractvalue(xmlval, '/*/info[@type = "cardinality_feedback"]')||'
   perf_feedback:   ' ||   extractvalue(xmlval, '/*/info[@type = "performance_feedback"]')||'
   xml_suboptimal:  ' ||   extractvalue(xmlval, '/*/info[@type = "xml_suboptimal"]')||'
   adaptive_plan:   ' || extractvalue(xmlval, '/*/info[@type = "adaptive_plan"]')||'
   spd_used:        ' || extractvalue(xmlval, '/*/spd/cu')||'
   spd_valid:       ' || extractvalue(xmlval, '/*/spd/cv')||'
   gtt_sess_stat:   ' || extractvalue(xmlval, '/*/info[@type = "gtt_session_st"]')||'
   db_version:      ' || extractvalue(xmlval, '/*/info[@type = "db_version"]')||'
   plan_hash_full:  ' || extractvalue(xmlval, '/*/info[@type = "plan_hash_full"]')||' 
   plan_hash:       ' || extractvalue(xmlval, '/*/info[@type = "plan_hash"]')||'
   plan_hash_2:     ' || extractvalue(xmlval, '/*/info[@type = "plan_hash_2"]') as Full_Notes
from
(select xmltype(other_xml) xmlval from
   (select other_xml
                   from dba_hist_sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&2',0)
                    and other_xml is not null
                    and not exists (select 1 from gv$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2',0) and other_xml is not null)
    union all
    select other_xml
                   from gv$sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&2',0)
                    and other_xml is not null
                    and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2', 0) and rownum <= 1)
   )
)
/
set feedback on VERIFY ON timi on
