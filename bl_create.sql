--
-- [Re]create SPM baseline from cursor in Shared Pool
-- Usage: SQL> @bl_create g1jratsw6ujcz 2375777697 "Halty''s task"
-- http://iusoltsev.wordpress.com
--

set echo off feedback off heading on VERIFY OFF serveroutput on

declare
    res number;
    v_sql_handle      varchar2(30);
    v_plan_name       varchar2(30);
    v_sql_id          varchar2(13) := '&1';
    v_plan_hash_value number       :=  &2;
    v_desc            varchar2(30) := '&3';
begin
   for reco in (select sql_handle, plan_name
                  from dba_sql_plan_baselines bl, v$sqlarea sa
                 where dbms_lob.compare(bl.sql_text, sa.sql_fulltext) = 0
                   and sa.sql_id = v_sql_id)
   loop res := DBMS_SPM.drop_sql_plan_baseline(reco.sql_handle, reco.plan_name); end loop;
   res := dbms_spm.load_plans_from_cursor_cache(sql_id => v_sql_id, plan_hash_value => v_plan_hash_value );
   dbms_output.put_line(res);
   select sql_handle, plan_name
    into v_sql_handle, v_plan_name
    from dba_sql_plan_baselines bl, v$sqlarea sa
--   where dbms_lob.compare(bl.sql_text, sa.sql_fulltext) = 0
where DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(bl.sql_text) = DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sa.sql_fulltext)
     and sa.sql_id = v_sql_id
     and origin = 'MANUAL-LOAD';
   res := DBMS_SPM.alter_sql_plan_baseline(v_sql_handle, v_plan_name,'fixed','yes');
   res := DBMS_SPM.alter_sql_plan_baseline(v_sql_handle, v_plan_name,'autopurge','no');
   res := DBMS_SPM.alter_sql_plan_baseline(v_sql_handle, v_plan_name,'description',v_desc);
   dbms_output.put_line('');
   dbms_output.put_line('Baseline '||v_sql_handle||' '||v_plan_name||' was [re]created');
   dbms_output.put_line('for SQL_ID='||v_sql_id||', SQL_PLAN_HASH='||v_plan_hash_value);
end;
/
set feedback on echo off VERIFY ON serveroutput off