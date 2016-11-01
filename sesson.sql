set feedback on
declare
 gtt_not_exists  EXCEPTION;
 too_many_values EXCEPTION;
 PRAGMA EXCEPTION_INIT(gtt_not_exists, -942);
 PRAGMA EXCEPTION_INIT(too_many_values, -913);
begin
--V$SESS_TIME_MODEL
  begin
     execute immediate 'truncate table gtt$sess_time_model';
     execute immediate 'insert into gtt$sess_time_model select * from v$sess_time_model where sid = '||&&1;
  exception
      when gtt_not_exists then
             execute immediate 'create global temporary table gtt$sess_time_model on commit preserve rows
             as
             select * from v$sess_time_model where sid = ' || &&1;
      when too_many_values then
             execute immediate 'drop table gtt$sess_time_model';
             execute immediate 'create global temporary table gtt$sess_time_model on commit preserve rows
             as
             select * from v$sess_time_model where sid = ' || &&1;
  end;
--V$SESSTAT
  begin
     execute immediate 'truncate table gtt$sesstat';
     execute immediate 'insert into gtt$sesstat select * from v$sesstat where sid = '||&&1;
  exception
      when gtt_not_exists then
             execute immediate 'create global temporary table gtt$sesstat on commit preserve rows
             as
             select * from v$sesstat where sid = ' || &&1;
      when too_many_values then
             execute immediate 'drop table gtt$sesstat';
             execute immediate 'create global temporary table gtt$sesstat on commit preserve rows
             as
             select * from v$sesstat where sid = ' || &&1;
  end;
--V$SESSION_EVENT
  begin
     execute immediate 'truncate table gtt$session_event';
     execute immediate 'insert into gtt$session_event select * from v$session_event where sid = '||&&1;
  exception
      when gtt_not_exists then
             execute immediate 'create global temporary table gtt$session_event on commit preserve rows
             as
             select * from v$session_event where sid = ' || &&1;
      when too_many_values then
             execute immediate 'drop table gtt$session_event';
             execute immediate 'create global temporary table gtt$session_event on commit preserve rows
             as
             select * from v$session_event where sid = ' || &&1;
  end;
end;
/
set feedback on