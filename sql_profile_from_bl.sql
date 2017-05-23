--
-- SQL Profile SQL Plan Baseline
-- Usage: SQL> @sql_profile_from_bl &sql_id &bl_plan_name "SQL_Profile_name" "SQL_Profile_desc"
--
set verify off timi off lines 500
col HINT for a500

DECLARE
  lv_hint SYS.SQLPROF_ATTR := SYS.SQLPROF_ATTR();
  n_hint  number := 1;
  v_sql_text CLOB;
BEGIN
  begin
    select sql_text into v_sql_text from dba_hist_sqltext where sql_id = '&&1';
  exception when no_data_found then select sql_fulltext into v_sql_text from v$sqlarea where sql_id = '&&1';
  end;
    for hint_rec in (select hint
                       from (select substr(extractvalue(value(d), '/hint'), 1, 500) as hint
                               from xmltable('/*/outline_data/hint' passing
                                            (select xmltype(other_xml) as xmlval
                                               from sys.sqlobj$plan op, sys.sqlobj$ o
                                              where o.obj_type = 2
                                                and op.obj_type = 2
                                                and o.name = '&&2'
                                                and o.signature = op.signature
                                                and o.plan_id   = op.plan_id
                                                and op.other_xml is not null)) d
                             union all
                             select substr(extractvalue(value(d), '/hint'), 1, 500)
                               from xmltable('/outline_data/hint' passing
                                            (select xmltype(comp_data) as xmlval
                                               from sys.sqlobj$data od, sys.sqlobj$ o
                                              where o.obj_type = 2
                                                and od.obj_type = 2
                                                and o.name = '&&2'
                                                and o.signature = od.signature
                                                and o.plan_id = od.plan_id
                                                and comp_data is not null)) d))
    loop
      lv_hint.EXTEND;
      lv_hint(n_hint) := hint_rec.hint;
      n_hint := n_hint + 1;
    end loop;
    dbms_sqltune.drop_sql_profile  (name        => '&&3', ignore => TRUE);
    dbms_sqltune.import_sql_profile(sql_text    => v_sql_text,
                                    category    => 'DEFAULT',
                                    name        => '&&3',
                                    profile     => lv_hint,
                                    description => '&&4',
                                    force_match => TRUE);
END;
/
@@sql_profile_hints &&3 %

set verify on timi on