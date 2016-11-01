--
-- Drop SPM baseline by Plan_Name
-- Usage: SQL> @drop_bsline SQL_PLAN_0z8v9y3ah0426c2507a8e
-- http://iusoltsev.wordpress.com
--

set echo off feedback off heading on VERIFY OFF serveroutput on

declare
    res number;
begin
   for reco in (select sql_handle, plan_name
                  from dba_sql_plan_baselines bl
                 where bl.plan_name = '&1')
   loop
     res := DBMS_SPM.drop_sql_plan_baseline(reco.sql_handle, reco.plan_name);
     dbms_output.put_line('Baseline '||reco.sql_handle||' '||reco.plan_name||' was dropped');
   end loop;
end;
/
set feedback on echo off VERIFY ON serveroutput off