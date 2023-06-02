create or replace trigger applsys.fnd_concurrent_requests_aiu
   after INSERT or UPDATE
   ON applsys.fnd_concurrent_requests
   REFERENCING OLD AS OLD NEW AS NEW
   FOR EACH ROW
when (NEW.status_code = 'R')
declare
     Operation varchar2(1);
BEGIN

  IF INSERTING THEN
    Operation := 'I';
  ELSIF UPDATING THEN
    Operation := 'U';
  END IF;

  insert into system.fnd_CONCURRENT_sessions
  select distinct
         systimestamp,
         :OLD.status_code,
         Operation,
         :new.request_id,
         :new.PARENT_REQUEST_ID,
         :new.argument7,
         SYS_CONTEXT ('USERENV', 'INSTANCE'),--s.inst_id,
         s.CLIENT_IDENTIFIER,
         s.module,
         s.action,
         s.sid,
         s.serial#,
         :new.oracle_session_id
, substr(SYS_CONTEXT('USERENV','SERVER_HOST'),1,60) -- added
    from dual
    left outer join v$process p on p.spid = :new.oracle_process_id
    left outer join v$session s on (p.addr = s.paddr --and p.inst_id = s.inst_id
                                   )
                                 or :new.ORACLE_SESSION_ID = s.audsid
      where --:new.ORACLE_SESSION_ID is not null or :new.oracle_process_id is not null
      s.audsid is not null or p.spid is not null
    ;

exception when others then null;
END;
/