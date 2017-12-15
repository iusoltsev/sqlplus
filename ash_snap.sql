--
-- To create ASH snap in 12c
-- SQL> @ash_snap USERS
-- The Snap Table ASH_201507071743 was successfully created in tablespace USERS
--
set echo off feedback off heading on VERIFY OFF serveroutput on
select inst_id, min(sample_time) from gv$active_session_history group by inst_id
/
declare
    sdate char(12) := to_char(sysdate,'YYYYMMDDHH24MI');
    def_ts varchar2(30) := nvl('&1','USERS');
    vers varchar2(20);
begin
  select version into vers from v$instance;
  if vers like '12%' then
  execute immediate '
  create table SYSTEM.ASH_' || sdate ||' tablespace '|| def_ts ||' as
  select s.plan_hash_value      as SQL_PHV,
         s.full_plan_hash_value as SQL_FPHV,
         s.last_load_time as SQL_last_load_time,
         s.last_active_time as SQL_last_active_time,
         ash.*
    from gv$active_session_history ash
    left join gv$sql s on ash.sql_id = s.sql_id and ash.sql_child_number = s.child_number and ash.inst_id = s.inst_id';
  else execute immediate '
  create table SYSTEM.ASH_' || sdate ||' tablespace '|| def_ts ||' as
  select ash.* from gv$active_session_history ash';
  end if;
  dbms_output.put_line(' --- ');
  dbms_output.put_line(' --- The Snap Table SYSTEM.ASH_' || sdate ||' was successfully created in tablespace '|| def_ts);
  dbms_output.put_line(' --- ');
end;
/
set feedback on echo off VERIFY ON serveroutput off