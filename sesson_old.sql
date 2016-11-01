set feedback off
begin
  execute immediate 'truncate table gtt$sess_time_model';
  execute immediate 'drop table gtt$sess_time_model';
exception
  when others then
    null;
end;
/
declare
   name_already_used EXCEPTION;
   PRAGMA EXCEPTION_INIT(name_already_used, -955);
begin
  execute immediate 'create global temporary table gtt$sess_time_model on commit preserve rows
as
select * from v$sess_time_model where sid = ' || &&1;
exception
  when name_already_used then
    insert into gtt$sess_time_model
      select * from v$sess_time_model where sid = &&1;
end;
/
begin
  execute immediate 'truncate table gtt$sesstat';
  execute immediate 'drop table gtt$sesstat';
exception
  when others then
    null;
end;
/
declare
   name_already_used EXCEPTION;
   PRAGMA EXCEPTION_INIT(name_already_used, -955);
begin
  execute immediate 'create global temporary table gtt$sesstat on commit preserve rows
as
select * from v$sesstat where sid = ' || &&1;
exception
  when name_already_used then
    insert into gtt$sesstat
      select * from v$sesstat where sid = &&1;
end;
/
begin
  execute immediate 'truncate table gtt$session_event';
  execute immediate 'drop table gtt$session_event';
exception
  when others then
    null;
end;
/
declare
   name_already_used EXCEPTION;
   PRAGMA EXCEPTION_INIT(name_already_used, -955);
begin
  execute immediate 'create global temporary table gtt$session_event on commit preserve rows
as
select * from v$session_event where sid = ' || &&1;
exception
  when name_already_used then
    insert into gtt$session_event
      select * from v$session_event where sid = &&1;
end;
/
set feedback on