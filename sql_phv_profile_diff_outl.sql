----
-- SQL Plan vs SQL Profile Outline sections diff, by Query block[s] too
-- Usage: SQL> sql_phv_profile_diff_outl.sql b8984mx8m8qjq 3318083602        A_b8984mx8m8qjq_2293795685 ["SEL$A7C6D689"]
--                                           ^sql_id1      ^plan_hash_value1 ^SQL_Profile                ^query_block_name or search phase
-- by Igor Usoltsev
--

set feedback on heading on timi off pages 1024 lines 512 echo off  VERIFY OFF
set pages 100

col phv_&&2 for a512
col phv_&&3 for a512

pro --------------------------------

pro SQL Plan "Outline" sections diff between SQL_ID "&&1" PHV "&&2" and SQL Profile "&&3"

pro --------------------------------

set pages 500

with
plh1 as (select substr(extractvalue(value(d), '/hint'), 1, 512) as phv_&&2
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from dba_hist_sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&2',0)
                    and other_xml is not null
and rownum <= 1 -- different DBID!
                    and not exists (select 1 from gv$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2',0) and other_xml is not null))) d
         union all
         select substr(extractvalue(value(d), '/hint'), 1, 512)
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from gv$sql_plan
                  where sql_id = '&&1'
--                    and plan_hash_value = nvl('&&2',0)
                    and (plan_hash_value = nvl('&&2',0) or child_number = &&2)
                    and other_xml is not null
                    and rownum <= 1
--                    and child_number = (select min(child_number) from v$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2',0)))) d),
--                    and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2', 0) and rownum <= 1)
        )) d),
plh2 as (
select substr(extractvalue(value(d), '/hint'), 1, 4000) as phv_&&3
  from xmltable('/outline_data/hint' passing
                (select xmltype(comp_data) as xmlval
                   from sys.sqlobj$data od join sys.sqlobj$ o using (signature, category,obj_type,plan_id)
                  where obj_type = 1 -- type "SQL Profile"
                    and o.name = '&3'
                    and comp_data is not null)) d)
(select plh1.phv_&&2 from plh1 where plh1.phv_&&2 like '%' || '&&4' || '%'
 minus
 select plh1.phv_&&2 from plh1 join plh2 on plh1.phv_&&2 = plh2.phv_&&3)
union all
select '----------------------------------------------------------------------------------------------------' from dual
union all
select 'PHV_&&3' from dual
union all
select '----------------------------------------------------------------------------------------------------' from dual
union all
(select plh2.phv_&&3 from plh2
  where plh2.phv_&&3 like '%' || '&&4' || '%'
 minus
 select plh2.phv_&&3 from plh1 join plh2 on plh1.phv_&&2 = plh2.phv_&&3)
/

set feedback on VERIFY ON timi on
