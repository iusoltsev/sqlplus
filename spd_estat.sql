--
-- Shows SQL Plan Directives linked to Extended Db Object Statistics
-- Usage: SQL> @spd_estat ""               JPS_ATTRS
--                         ^[object_owner] ^object_name
-- based on http://blog.dbi-services.com/matching-sql-plan-directives-and-extended-stats/
--

set feedback 1 heading on timi on pages 200 lines 500 echo off  VERIFY OFF

col INTERNAL_STATE for a14
col REDUNDANT for a9
col OWNER for a10
col table_name  for a20
col histograms for a30
col directive_id for a25
--col directive_id for 9999999999999999999999
col spd_text for a46
col enabled for a7
col state for a10
col extension_name for a40
col type           for a16
col EQUAL_PRED_ONLY      for a15
col SINGLE_COL_PRED_ONLY for a20
col IDX_ACC_BY_JOIN_PRED for a20
col FILTER_ON_JOIN_OBJ   for a18




select
 owner,
 table_name,
-- ccolumns as columns,
 histograms,
 directive_id,
 internal_state,
 spd_text,
--EQ_PRED,       
--SNGL_COL_PRED, 
--I_BY_JOIN_PRED,
--(select extract(o2.notes,'/obj_note/filter_on_joining_object/text()').getStringVal() from dba_sql_plan_dir_objects o2 where o2.object_type='TABLE' and o2.directive_id=directive_id) FILTER_ON_JOIN,
type,
 state,
 redundant,
 enabled,
 extension_name
 from
   (select o.owner
          ,object_name table_name
          ,listagg(subobject_name,',')within group(order by subobject_name) columns
          ,listagg(subobject_name,chr(13)||chr(10))within group(order by subobject_name) ccolumns
          ,listagg(column_name||'['||histogram||']',chr(13)||chr(10))within group(order by column_name) histograms
          ,to_char(directive_id, '9999999999999999999999') as directive_id
--          ,directive_id
          ,max(RPAD(extract(d.notes,'/spd_note/internal_state/text()').getStringVal(),14,'_')) internal_state
--          ,max(extract(d.notes,'/spd_note/spd_text/text()').getStringVal())       spd_text
          ,max(replace(extract(d.notes,'/spd_note/spd_text/text()').getStringVal(),', ',','||chr(13)||chr(10)))       spd_text
          ,max(extract(d.notes,'/spd_note/redundant/text()').getStringVal())      redundant
--          ,max(extract(o.notes,'/obj_note/equality_predicates_only/text()').getStringVal())        EQ_PRED
--          ,max(extract(o.notes,'/obj_note/simple_column_predicates_only/text()').getStringVal())   SNGL_COL_PRED
--          ,max(extract(o.notes,'/obj_note/index_access_by_join_predicates/text()').getStringVal()) I_BY_JOIN_PRED
--          ,max(extract(o.notes,'/obj_note/filter_on_joining_object/text()').getStringVal())        FILTER_ON_JOIN
          ,type
          ,enabled
          ,state
--          ,o
    from dba_sql_plan_dir_objects o
    join dba_sql_plan_directives  d using(directive_id)
    join dba_tab_columns          c on c.owner = o.owner and o.object_name = c.table_name and o.subobject_name = c.column_name
    where object_type='COLUMN'
      and directive_id in ( select directive_id
                            from dba_sql_plan_dir_objects
                            where extract(notes,'/obj_note/equality_predicates_only/text()').getStringVal()='YES'
                               OR extract(notes,'/obj_note/simple_column_predicates_only/text()').getStringVal()='YES'
                              and object_type='TABLE')
      and o.owner = nvl(upper('&&1'),o.owner)
      and object_name = nvl(upper('&&2'),object_name)
      and object_name not like 'BIN$%'
    group by o.owner,object_name,directive_id,enabled,state,type
   ) d
   left join
   (select owner
          ,table_name
          ,listagg(column_name,',')within group(order by column_name) columns
          ,extension_name
    from dba_tab_columns join dba_stat_extensions using(owner,table_name)
    where extension like '%"'||column_name||'"%'
    group by owner,table_name,extension_name
    order by owner,table_name,columns)
 using (owner,table_name,columns)
--where owner = nvl(upper('&1'),owner)
--  and table_name = nvl(upper('&2'),table_name)
--  and table_name not like 'BIN$%'
 order by owner,table_name,columns
/
select to_char(directive_id, '9999999999999999999999') as directive_id,
       owner,
       object_name table_name,
       object_type type,
       extract(notes, '/obj_note/equality_predicates_only/text()').getStringVal()        EQUAL_PRED_ONLY,
       extract(notes, '/obj_note/simple_column_predicates_only/text()').getStringVal()   SINGLE_COL_PRED_ONLY,
       extract(notes, '/obj_note/index_access_by_join_predicates/text()').getStringVal() IDX_ACC_BY_JOIN_PRED,
       extract(notes, '/obj_note/filter_on_joining_object/text()').getStringVal()        FILTER_ON_JOIN_OBJ
  from dba_sql_plan_dir_objects
 where owner = nvl(upper('&&1'), owner)
   and object_name not like 'BIN$%'
   and object_type = 'TABLE'
   and object_name = nvl(upper('&&2'), object_name)
/
set feedback on VERIFY ON timi off
