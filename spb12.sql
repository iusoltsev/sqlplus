--
-- Baseline hints list for Oracle 12c
-- Usage: SQL> @spb12 SQL_PLAN_acg49cdw0088v4085ecd2
-- https://iusoltsev.wordpress.com/2016/04/04/12c-spm-baseline-sys-sqlobjplan-upd/
--
set verify off feedback off timi off long 512
col OUTLINE_HINTS for a512
col OPERATION for a60
col QBLOCK_NAME for a30
col OBJECT_ALIAS for a30
col OBJECT_OWNER for a30
col OBJECT_NAME for a30
col OPTIMIZER for a30
col BIND for a512 hea "Bind Vars"
col SKIP for a4
col DISP for 9999

WITH display_map AS
 (SELECT X.*
  FROM (select *
          from sys.sqlobj$plan op
          join sys.sqlobj$ o
          using (obj_type, signature, plan_id)
         where o.name = '&&1') pt,
       XMLTABLE ( '/other_xml/display_map/row' passing XMLTYPE(other_xml ) COLUMNS 
                        op  NUMBER PATH '@op',    -- operation
                        dis NUMBER PATH '@dis',   -- display
                        par NUMBER PATH '@par',   -- parent
                        prt NUMBER PATH '@prt',   -- ?
                        dep NUMBER PATH '@dep',   -- depth
                        skp NUMBER PATH '@skp' )  -- skip
                    AS X
  WHERE other_xml   IS NOT NULL)
SELECT decode(nvl(m.skp,0),1,'-',' ') as SKIP,
       NVL(m.dis, pt.ID) as DISP,
       lpad(' ', 2 * level) || pt.operation || ' ' || pt.options as operation,
       pt.qblock_name,
       pt.object_alias,
       pt.object_owner,
       pt.object_name,
       pt.optimizer,
       pt.cost,
--  pt.cpu_cost, pt.io_cost,
       pt.cardinality,
-- pt.bytes,
-- pt.access_predicates, pt.filter_predicates,
--       pt.projection,
       pt.temp_space,
       pt.time
--, pt.other_xml
  FROM (select *
          from sys.sqlobj$plan op
          join sys.sqlobj$ o
          using (obj_type, signature, plan_id)
         where o.name = '&&1') pt
  left join display_map m on pt.id = m.op
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0
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
select column_value as BIND
  from xmltable('/*/peeked_binds/bind' passing
                (select xmltype(other_xml) as xmlval
                   from sys.sqlobj$plan op, sys.sqlobj$ o
                  where o.obj_type = 2
                    and op.obj_type = 2
                    and o.name = '&&1'
                    and o.signature = op.signature
                    and o.plan_id = op.plan_id
                    and op.other_xml is not null)) d
/
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
union all
select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
  from xmltable('/outline_data/hint' passing
                (select xmltype(comp_data) as xmlval
                   from sys.sqlobj$data od, sys.sqlobj$ o
                  where o.obj_type = 2
                    and od.obj_type = 2
                    and o.name = '&&1'
                    and o.signature = od.signature
                    and o.plan_id = od.plan_id
                    and comp_data is not null)) d
/

set verify on feedback on timi on