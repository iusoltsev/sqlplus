--
-- SQL Profile hints list, including Profiles created by DBMS_SQLTUNE.IMPORT_SQL_PROFILE
-- Usage: SQL> @sql_profile_from_sql &sql_id &plan_hash_value "SQL_Profile_name" "SQL_Profile_desc"
--
set verify off timi off lines 500
col HINT for a400

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
                       from (select plan_hash_value, b.hint
                               from gv$sql_plan m,
                                    xmltable('/other_xml/outline_data/hint'
                                             passing xmltype(m.OTHER_XML)
                                             columns hint varchar2(4000) path
                                             '/hint') b
                              where sql_id = '&&1'
                                and plan_hash_value = nvl('&&2', plan_hash_value)
                                and trim(OTHER_XML) is not null
                             union --all
                             select plan_hash_value, b.hint
                               from dba_hist_sql_plan m,
                                    xmltable('/other_xml/outline_data/hint'
                                             passing xmltype(m.OTHER_XML)
                                             columns hint varchar2(4000) path
                                             '/hint') b
                              where sql_id = '&&1'
                                and plan_hash_value = nvl('&&2', plan_hash_value)
                                and trim(OTHER_XML) is not null))
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