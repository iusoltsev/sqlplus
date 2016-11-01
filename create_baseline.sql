----------------------------------------------------------------------------------------
--
-- File name:   create_baseline.sql
--
-- Purpose:     Creates a SQL Baseline on a SQL statement in the shared pool.
-
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for four values.
--
--              sql_id: the sql_id of the statement (must be in the shared pool)
--
--              plan_hash_value: the hash value of the plan
--
--              fixed: a toggle to turn on or off the fixed feature (NO)
--
--              enabled: a toggle to turn on or off the enabled flag (YES)
--
--              plan_name: the name of the plan (SQLID_sqlid_planhashvalue)
--
-- Description: This script uses the DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE procedure to 
--              create a Baseline on a statement that is currently in the shared pool.
--              By default, the Baseline is renamed to include the sql_id and plan_hash_value.
--              
--              Note that this script will not work with 11gR1 as there is a bug 
--
--              See kerryosborne.oracle-guy.com for additional information.
----------------------------------------------------------------------------------------- 

accept sql_id -
       prompt 'Enter value for sql_id: ' -
       default 'X0X0X0X0'
accept plan_hash_value -
       prompt 'Enter value for plan_hash_value: ' -
       default 'X0X0X0X0'
accept fixed -
       prompt 'Enter value for fixed (NO): ' -
       default 'NO'
accept enabled -
       prompt 'Enter value for enabled (YES): ' -
       default 'YES'
accept plan_name -
       prompt 'Enter value for plan_name (ID_sqlid_planhashvalue): ' -
       default 'X0X0X0X0'


set feedback off
set sqlblanklines on
set serveroutput on

declare
l_plan_name varchar2(40);
l_old_plan_name varchar2(40);
l_sql_handle varchar2(40);
ret binary_integer;
l_sql_id varchar2(13);
l_plan_hash_value number;
l_fixed varchar2(3);
l_enabled varchar2(3);
major_release varchar2(3);
minor_release varchar2(3);
begin
 select regexp_replace(version,'\..*'), regexp_substr(version,'[0-9]+',1,2) into major_release, minor_release from v$instance;
minor_release := 2;

l_sql_id := '&&sql_id';
l_plan_hash_value := to_number('&&plan_hash_value');
l_fixed := '&&fixed';
l_enabled := '&&enabled';

ret := dbms_spm.load_plans_from_cursor_cache(
    sql_id=>l_sql_id, 
    plan_hash_value=>l_plan_hash_value,
    fixed=>l_fixed,
    enabled=>l_enabled);

if minor_release = '1' then

-- 11gR1 has a bug that prevents renaming Baselines

    dbms_output.put_line(' ');
    dbms_output.put_line('Baseline created.');
    dbms_output.put_line(' ');

else

-- This statements looks for Baselines create in the last 4 seconds

    select sql_handle, plan_name,
    decode('&&plan_name','X0X0X0X0','SQLID_'||'&&sql_id'||'_'||'&&plan_hash_value','&&plan_name')
    into l_sql_handle, l_old_plan_name, l_plan_name
    from dba_sql_plan_baselines spb
    where created > sysdate-(1/24/60/15);


    ret := dbms_spm.alter_sql_plan_baseline(
    sql_handle=>l_sql_handle,
    plan_name=>l_old_plan_name,
    attribute_name=>'PLAN_NAME',
    attribute_value=>l_plan_name);

    dbms_output.put_line(' ');
    dbms_output.put_line('Baseline '||upper(l_plan_name)||' created.');
    dbms_output.put_line(' ');

end if;


end;
/

undef sql_id
undef plan_hash_value
undef plan_name
undef fixed
set feedback on
set serveroutput off
