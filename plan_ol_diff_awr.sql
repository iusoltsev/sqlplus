--
-- SQL Plan Outline Hints Differences from AWR [for pointed Query block only]
-- Usage: SQL> @plan_ol_diff_awr 6r6sanrs05550 3541904711        [2970372553]       [SEL$A7C6D689]
--                            ^sql_id       ^plan_hash_value1  ^plan_hash_value2  ^query_block_name
-- by Igor Usoltsev
--

set feedback on heading on timi off pages 500 lines 500 echo off  VERIFY OFF

col plh_&&2 for a100
col plh_&&3 for a100

with
plh1 as (select substr(extractvalue(value(d), '/hint'), 1, 200) as plh_&&2
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from dba_hist_sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&2',0)
                    and other_xml is not null)) d),
plh2 as (select substr(extractvalue(value(d), '/hint'), 1, 200) as plh_&&3
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from dba_hist_sql_plan
                  where sql_id = '&&1'
                    and plan_hash_value = nvl('&&3',0)
                    and other_xml is not null)) d)
select * from plh1 full join plh2 on plh1.plh_&&2 = plh2.plh_&&3
	where --not (plh1.plh_&&2 || plh2.plh_&&3 like 'INDEX%'        or -- may be useful to exclude a lot of non-principal hints
              --     plh1.plh_&&2 || plh2.plh_&&3 like 'NLJ_BATCHING%' or -- --//--
              --     plh1.plh_&&2 || plh2.plh_&&3 like 'OUTLINE%')        -- --//--
              --and  
                     plh1.plh_&&2 || plh2.plh_&&3 like '%' || '&&4' || '%'
minus
select * from plh1 join      plh2 on plh1. plh_&&2 = plh2.plh_&&3
/

set feedback on VERIFY ON timi on