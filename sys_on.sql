set feedback off
declare
 gtt_not_exists EXCEPTION;
 PRAGMA EXCEPTION_INIT(gtt_not_exists, -942);
begin
--V$SYS_TIME_MODEL
  begin
     execute immediate 'truncate table gtt$sys_time_model';
     execute immediate 'insert into gtt$sys_time_model select * from v$sys_time_model';
  exception
      when gtt_not_exists then
             execute immediate 'create global temporary table gtt$sys_time_model on commit preserve rows
             as
             select * from v$sys_time_model';
  end;
--V$SYSSTAT
  begin
     execute immediate 'truncate table gtt$sysstat';
     execute immediate 'insert into gtt$sysstat select * from v$sysstat';
  exception
      when gtt_not_exists then
             execute immediate 'create global temporary table gtt$sysstat on commit preserve rows
             as
             select * from v$sysstat';
  end;
--V$SYSTEM_EVENT
  begin
     execute immediate 'truncate table gtt$system_event';
     execute immediate 'insert into gtt$system_event select * from v$system_event';
  exception
      when gtt_not_exists then
             execute immediate 'create global temporary table gtt$system_event on commit preserve rows
             as
             select * from v$system_event';
  end;
end;
/
set feedback on