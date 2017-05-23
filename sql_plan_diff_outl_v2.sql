--
-- SQL Plan Outline sections diff, by Query block[s] too
-- Usage: SQL> @sql_plan_diff_outl 6r6sanrs05550 3541904711        6r6sanrs05550 2970372553        [SEL$A7C6D689]
--                           ^sql_id1      ^plan_hash_value1 ^sql_id2      ^plan_hash_value2  ^query_block_name
-- by Igor Usoltsev
--

set feedback on heading on timi off pages 100 lines 500 echo off  VERIFY OFF
set pages 100

col phv_&&2 for a200
col phv_&&4 for a200

pro --------------------------------

pro SQL Plan "Outline" sections diff

pro --------------------------------

with
plh1 as (select substr(extractvalue(value(d), '/hint'), 1, 512) as phv_&&2
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from dba_hist_sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&2',0)
                    and other_xml is not null
                    and not exists (select 1 from gv$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2',0) and other_xml is not null))) d
         union all
         select substr(extractvalue(value(d), '/hint'), 1, 512)
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from gv$sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&2',0)
                    and other_xml is not null
                    and rownum <= 1
--                    and child_number = (select min(child_number) from v$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2',0)))) d),
--                    and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&1' and plan_hash_value = nvl('&&2', 0) and rownum <= 1)
        )) d),
plh2 as (select substr(extractvalue(value(d), '/hint'), 1, 512) as phv_&&4
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from dba_hist_sql_plan
                  where sql_id = '&&3'
                    and plan_hash_value = nvl('&&4',0)
                    and other_xml is not null
                    and not exists (select 1 from gv$sql_plan where sql_id = '&&3' and plan_hash_value = nvl('&&4',0) and other_xml is not null))) d
         union all
         select substr(extractvalue(value(d), '/hint'), 1, 512)
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from gv$sql_plan
                  where sql_id = '&&3'
                    and plan_hash_value = nvl('&&4',0)
                    and other_xml is not null
                    and rownum <= 1
--                    and child_number = (select min(child_number) from v$sql_plan where sql_id = '&&3' and plan_hash_value = nvl('&&4',0)))) d)
--                    and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&3' and plan_hash_value = nvl('&&4', 0) and rownum <= 1)
        )) d)
(select plh1.phv_&&2 from plh1 -- full join plh2 on plh1.phv_&&2 = plh2.phv_&&4
  where --not (plh1.phv_&&2 || plh2.phv_&&4 like 'INDEX%'        or       -- may be useful to exclude a lot of non-principal hints
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'NLJ_BATCHING%' or -- --//--
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'OUTLINE%')        -- --//--
              --and  
                     plh1.phv_&&2 like '%' || '&&5' || '%'
 minus
 select plh1.phv_&&2 from plh1 join plh2 on plh1.phv_&&2 = plh2.phv_&&4)
union all
select '----------------------------------------------------------------------------------------------------' from dual
union all
select 'PHV_&&4' from dual
union all
select '----------------------------------------------------------------------------------------------------' from dual
union all
(select plh2.phv_&&4 from plh2
  where --not (plh1.phv_&&2 || plh2.phv_&&4 like 'INDEX%'        or       -- may be useful to exclude a lot of non-principal hints
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'NLJ_BATCHING%' or -- --//--
              --     plh1.phv_&&2 || plh2.phv_&&4 like 'OUTLINE%')        -- --//--
              --and  
                     plh2.phv_&&4 like '%' || '&&5' || '%'
 minus
 select plh2.phv_&&4 from plh1 join plh2 on plh1.phv_&&2 = plh2.phv_&&4)
/

set feedback on VERIFY ON timi on
