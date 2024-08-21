--
-- To create ASH snap in 12c
-- SQL> @ash_snap USERS
-- The Snap Table ASH_201507071743 was successfully created in tablespace USERS
--
/*2do
create database link RO_db
...
create table system.ash_20211116_RO_db tablespace users
as select * from gv$active_session_history@RO_db
*/
set echo off feedback off heading on VERIFY OFF serveroutput on
select to_char(inst_id) as inst_id , min(sample_time) from gv$active_session_history group by to_char(inst_id)
/
declare
    sdate char(12) := to_char(sysdate,'YYYYMMDDHH24MI');
    def_ts varchar2(30) := nvl('&1','USERS');
    vers number;
begin
  select to_number(REGEXP_SUBSTR(version, '[[:digit:]]+')) into vers from v$instance;
  if vers >= 12 then
  execute immediate '
  create table SYSTEM.ASH_' || sdate ||' tablespace '|| def_ts ||' COMPRESS as
  select s.plan_hash_value      as SQL_PHV,
         s.full_plan_hash_value as SQL_FPHV,
         s.last_load_time as SQL_last_load_time,
         s.last_active_time as SQL_last_active_time,
         s.hash_value      as SQL_HASH,
         s.old_hash_value as SQL_OLD_HASH,
         s.sql_text      as sql_text,
         s.program_id,
         s.program_line#,
         s.child_number,
         s.child_address,
         ash.*
    from gv$active_session_history ash
    left join gv$sql s on ash.sql_id = s.sql_id and ash.sql_child_number = s.child_number and ash.inst_id = s.inst_id';
  else execute immediate '
  create table SYSTEM.ASH_' || sdate ||' tablespace '|| def_ts ||' as
  select ash.* from gv$active_session_history ash';
  end if;
/*
  execute immediate '
  create table SYSTEM.SQLMON_' || sdate ||' tablespace '|| def_ts ||' as
  select * from gv$sql_plan_monitor';
*/
  dbms_output.put_line(' --- ');
  dbms_output.put_line(' --- The Snap Table SYSTEM.ASH_' || sdate ||' was successfully created in tablespace '|| def_ts);
--  dbms_output.put_line(' --- The Snap Table SYSTEM.SQLMON_' || sdate ||' was successfully created in tablespace '|| def_ts);
  dbms_output.put_line(' --- ');
end;
/
set feedback on echo off VERIFY ON serveroutput off
