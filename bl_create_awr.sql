-----------------------------------------------------------------------------------------
--
-- Purpose: Creates SQL Plan Baseline for a SQL statement with a plan_hash_value from AWR
-- Based on cr_baseline_awr.sql from Prasanth Kothuri
-- https://www.dropbox.com/sh/zp07y7qv0v06xg8/AABe8z82ZnFjAfoQyFDQxl9ja?dl=0
-- Usage: The script prompts for sql_id, plan_hash_value, fixed and enabled
--
-----------------------------------------------------------------------------------------
 
accept v_sql_id          char   prompt 'Enter sql_id: '
accept v_plan_hash_value number prompt 'Enter plan_hash_value: '
accept v_begin_snap      number prompt 'Enter begin snap id: '
accept v_end_snap        number prompt 'Enter end snap id: '
accept v_fixed           char   prompt 'Enter fixed (NO): ' default 'NO'
accept v_enabled         char   prompt 'Enter enabled (YES): ' default 'YES'
accept v_desc            char   prompt 'Enter SQL Baseline description : '
 
set serveroutput on
 
declare
    rc integer;
    baseline_ref_cur  DBMS_SQLTUNE.SQLSET_CURSOR;
    v_sql_handle      varchar2(30);
    v_plan_name       varchar2(30);

begin
 
-- Step 1 : Create SQL Tuning SET
dbms_sqltune.create_sqlset(
  sqlset_name => '&v_sql_id'||'_spm',
  description => 'SQL Tuning Set to create SQL baseline for '||'&v_sql_id');
 
-- Step 2 : Select sql_id and plan_hash_value from AWR

open baseline_ref_cur for
select VALUE(p) from table(
DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(
  begin_snap => '&v_begin_snap',
  end_snap => '&v_end_snap',
  basic_filter => 'sql_id='||CHR(39)||'&v_sql_id'||CHR(39)||' and plan_hash_value=&v_plan_hash_value',
  attribute_list => 'ALL')) p;
 
-- Step 3 : Load the AWR cursor into SQLSET

DBMS_SQLTUNE.LOAD_SQLSET(
  sqlset_name=>'&v_sql_id'||'_spm',
  populate_cursor=> baseline_ref_cur);

--+ Step 3+: Close cursor and check

close baseline_ref_cur;

select count(*)
  into rc
  from dba_sqlset_statements
 where sqlset_name     = '&v_sql_id' || '_spm'
   and sql_id          = '&v_sql_id'
   and plan_hash_value = &v_plan_hash_value;

 if rc = 0
   then DBMS_SQLTUNE.drop_sqlset('fxgzfhx4fr9rv'||'_spm');
        raise NO_DATA_FOUND;
 end if;

-- Step 4 : Create baseline; that is loading plans from sqlset into SPM

rc := dbms_spm.load_plans_from_sqlset(
 sqlset_name  => '&v_sql_id'||'_spm',
 basic_filter => 'sql_id='||CHR(39)||'&v_sql_id'||CHR(39)||' and plan_hash_value=&v_plan_hash_value',
 fixed        => '&v_fixed',
 enabled      => '&v_enabled');

--+ Step 5: Drop SQL Tuning SET

DBMS_SQLTUNE.drop_sqlset('&v_sql_id'||'_spm');

--+ Step 6: Get baseline names

   select sql_handle, plan_name
     into v_sql_handle, v_plan_name
     from dba_sql_plan_baselines bl, dba_hist_sqltext sa
    where DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(bl.sql_text) = DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sa.sql_text)
      and sa.sql_id = '&v_sql_id'
      and origin    = 'MANUAL-LOAD'
      and created   > sysdate - 15/24/60/60;

--+ Step 7: Modify baseline

rc := DBMS_SPM.alter_sql_plan_baseline(v_sql_handle, v_plan_name,'autopurge','no');
rc := DBMS_SPM.alter_sql_plan_baseline(v_sql_handle, v_plan_name,'description','&v_desc');

   dbms_output.put_line('');
   dbms_output.put_line('Baseline '||v_sql_handle||' '||v_plan_name||' was created from AWR');
   dbms_output.put_line('for SQL_ID='||'&v_sql_id'||', SQL_PLAN_HASH='||'&v_plan_hash_value');

end;
/
undef v_sql_id
undef v_plan_hash_value
undef v_fixed
undef v_enabled
undef v_begin_snap
undef v_end_snap
undef v_desc
 
set serveroutput off
