--
-- SQL Plan Outline sections diff, by Query block[s] too
-- Usage: SQL> @sql_plan_diff_outl_dbid 58hv79m04acma 172909670         1071336896 58hv79m04acma 172909670         2598577434        [SEL$A7C6D689]
--                                      ^sql_id1      ^plan_hash_value1 ^dbid1     ^sql_id2      ^plan_hash_value2 ^dbid2            ^query_block_name or Outline hint'd part
--             @sql_plan_diff_outl_v2 fppuw3hpvww2d 4285086053        fppuw3hpvww2d 1002813375        "RA_CUSTOMER_TRX_ALL""@""SEL$118"
-- by Igor Usoltsev
--

set feedback on heading on timi off pages 1024 lines 512 echo off  VERIFY OFF
set pages 100

col phv_&&2 for a512
col phv_&&4 for a512

pro --------------------------------

pro SQL Plan "Outline" sections diff

pro --------------------------------

set pages 500

with
plh1 as (select substr(extractvalue(value(d), '/hint'), 1, 512) as phv_&&3
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from dba_hist_sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&2',0)
and dbid = nvl('&&3', dbid)
                    and other_xml is not null
----and rownum <= 1 -- different DBID!
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
plh2 as (select substr(extractvalue(value(d), '/hint'), 1, 512) as phv_&&6
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from dba_hist_sql_plan
                  where sql_id = '&&4'
                    and plan_hash_value = nvl('&&5',0)
                    and other_xml is not null
and dbid = nvl('&&6', dbid)
----and rownum <= 1 -- different DBID!
                    and not exists (select 1 from gv$sql_plan where sql_id = '&&4' and plan_hash_value = nvl('&&5',0) and other_xml is not null))) d
         union all
         select substr(extractvalue(value(d), '/hint'), 1, 512)
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from gv$sql_plan
                  where sql_id = '&&4'
--                    and plan_hash_value = nvl('&&4',0)
                    and (plan_hash_value = nvl('&&5',0) or child_number = &&5)
                    and other_xml is not null
                    and rownum <= 1
--                    and child_number = (select min(child_number) from v$sql_plan where sql_id = '&&3' and plan_hash_value = nvl('&&4',0)))) d)
--                    and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&3' and plan_hash_value = nvl('&&4', 0) and rownum <= 1)
        )) d)
(select plh1.phv_&&3 from plh1 -- full join plh2 on plh1.phv_&&2 = plh2.phv_&&4
  where --not (plh1.phv_&&2 || plh2.phv_&&4 like 'INDEX%'        or       -- may be useful to exclude a lot of non-principal hints
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'NLJ_BATCHING%' or -- --//--
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'OUTLINE%')        -- --//--
              --and  
                     plh1.phv_&&3 like '%' || '&&7' || '%'
 minus
 select plh1.phv_&&3 from plh1 join plh2 on plh1.phv_&&3 = plh2.phv_&&6)
union all
select '----------------------------------------------------------------------------------------------------' from dual
union all
select 'PHV_&&6' from dual
union all
select '----------------------------------------------------------------------------------------------------' from dual
union all
(select plh2.phv_&&6 from plh2
  where --not (plh1.phv_&&2 || plh2.phv_&&4 like 'INDEX%'        or       -- may be useful to exclude a lot of non-principal hints
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'NLJ_BATCHING%' or -- --//--
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'OUTLINE%')        -- --//--
              --and  
                     plh2.phv_&&6 like '%' || '&&7' || '%'
 minus
 select plh2.phv_&&6 from plh1 join plh2 on plh1.phv_&&3 = plh2.phv_&&6)
/

set feedback on VERIFY ON timi on
