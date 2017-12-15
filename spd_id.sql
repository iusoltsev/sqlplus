--
-- Shows SQL Plan Directives by dir_id
-- Usage: SQL> @spd_id "12236433879016080600,16122377648489408595,11452601050385912375"
--                      ^Directive List
--

set feedback off heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col SPD_INTERNAL_STATE for a20
col SPD_REDUNDANT for a20
col SPD_TEXT for a100
col OWNER for a30
col OBJECT_NAME for a30
col COLUMN_NAME for a30
col EQ_PRED_ONLY for a13
col SIMPLE_COL_PRED_ONLY for a21
col IND_ACCESS_BY_JOIN_PRED for a24
col FILTER_ON_JOIN_OBJ for a19
col TAB_COL_LIST for a100
col COLUMN_LIST for a50

with d as (
select --+ rule
distinct
 to_char(d.f_id, '999999999999999999999')   as finding_id,
 to_char(d.dir_id, '999999999999999999999') as directive_id,
 d.type,
 d.enabled,
 d.internal_state as int_state,
 case when d.internal_state = 'HAS_STATS' or d.redundant = 'YES' then 'SUPERSEDED'
      when d.internal_state in ('NEW', 'MISSING_STATS', 'PERMANENT') then 'USABLE'
      else 'UNKNOWN' end as STATE,
-- d.auto_drop,
-- f.type,
 f.reason,
 f.tab_cnt,
 to_char(d.created,'dd.mm.yy hh24:mi:ss')       as created,
 to_char(d.last_modified,'dd.mm.yy hh24:mi:ss') as last_modified,
 to_char(d.last_used,'dd.mm.yy hh24:mi:ss')     as last_used,
 d.redundant,
-- 'TABLE' as object_type,
 u.name  as owner,
 o.name  as table_name,
 c.name  as column_name,
 extractvalue(fo.notes, '/obj_note/equality_predicates_only')        as eq_pred_only,
 extractvalue(fo.notes, '/obj_note/simple_column_predicates_only')   as simple_col_pred_only,
 extractvalue(fo.notes, '/obj_note/index_access_by_join_predicates') as ind_access_by_join_pred,
 extractvalue(fo.notes, '/obj_note/filter_on_joining_object')        as filter_on_join_obj
, ft.intcol#
  from sys."_BASE_OPT_DIRECTIVE" d
  join sys."_BASE_OPT_FINDING" f on f.f_id = d.f_id
  join sys."_BASE_OPT_FINDING_OBJ" fo on f.f_id = fo.f_id
  join (select obj#, owner#, name from sys.obj$
        union all
        select object_id obj#, 0 owner#, name from  v$fixed_table) o on fo.f_obj# = o.obj#
  join sys.user$ u on o.owner# = u.user#
  left join sys."_BASE_OPT_FINDING_OBJ_COL" ft on f.f_id = ft.f_id and fo.f_obj# = ft.f_obj#
  left join (select obj#, intcol#, name from sys.col$
             union all
             select kqfcotob obj#, kqfcocno intcol#, kqfconam name
             from sys.x$kqfco) c on o.obj# = c.obj# and ft.intcol# = c.intcol#
 where d.dir_id in (&1)
OR d.f_id in (&1))
select finding_id,
       directive_id,
       type,
       enabled,
       int_state,
       STATE,
       -- auto_drop,
       -- type,
       reason,
       tab_cnt,
       redundant,
--       listagg(owner || '.' || table_name, ', ') within group(order by table_name, column_name) as table_list,
dbms_lob.substr( dbms_xmlgen.convert(rtrim(xmlagg(xmlelement(e, '#'|| intcol# || ' ' || owner || '.' || table_name || '.' || column_name, '; ').extract('//text()') order by intcol#, table_name).getClobVal(), '; '), 1), 500) as tab_col_list,
--       listagg(column_name, ', ') within group(order by column_name) as column_list,
       max(eq_pred_only) as eq_pred_only,
       max(simple_col_pred_only) as simple_col_pred_only,
       max(ind_access_by_join_pred) as ind_access_by_join_pred,
       max(filter_on_join_obj) as filter_on_join_obj,
       created,
       last_modified,
       last_used
  from d
 group by finding_id,
          directive_id,
          type,
          enabled,
          int_state,
          STATE,
          -- auto_drop,
          -- type,
          reason,
          tab_cnt,
          created,
          last_modified,
          last_used,
          redundant
 order by directive_id desc
/
set feedback on VERIFY ON timi on
