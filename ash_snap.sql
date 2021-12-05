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
    vers number;
begin
  select to_number(REGEXP_SUBSTR(version, '[[:digit:]]+')) into vers from v$instance;
  if vers >= 12 then
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

  execute immediate '
  create table SYSTEM.SQLMON_' || sdate ||' tablespace '|| def_ts ||' as
  select * from gv$sql_plan_monitor';

  dbms_output.put_line(' --- ');
  dbms_output.put_line(' --- The Snap Table SYSTEM.ASH_' || sdate ||' was successfully created in tablespace '|| def_ts);
  dbms_output.put_line(' --- The Snap Table SYSTEM.SQLMON_' || sdate ||' was successfully created in tablespace '|| def_ts);
  dbms_output.put_line(' --- ');
end;
/
set feedback on echo off VERIFY ON serveroutput off

/*2do
create database link BALANCE_RO_balancecdbh
connect to system identified by "ujh,fnsq"
using
'(DESCRIPTION_LIST=
   (FAILOVER=on)
  (DESCRIPTION=
      (ENABLE=BROKEN) (LOAD_BALANCE=on) (FAILOVER=on)
      (ADDRESS=(PROTOCOL=tcp)(HOST=key-db1h.paysys.yandex.net)(PORT=1521))
      (CONNECT_DATA = ( SERVICE_NAME = balancecdbh) (server=dedicated))))'

create table system.ash_20211116_balancecdbh tablespace users
as select * from gv$active_session_history@BALANCE_RO_balancecdbh
*/