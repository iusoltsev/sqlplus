set feedback off lines 1000

col INST_ID for a7
col INSTANCE_NAME for a20
col SERVICE for a30
col HOST_NAME for a30
col VERSION for a10
col STARTUP_TIME for a20
col STATUS for a8
col PARALLEL for a8
col THREAD for a7
col ARCHIVER for a8
col DATABASE_STATUS  for a15
col INSTANCE_ROLE for a20
col ACTIVE_STATE for a12
col PLATFORM_NAME for a20
col OPEN_MODE for a10

select to_char(INST_ID)||decode(inst_id,sys_context('userenv', 'instance'),'*') as INST_ID,
       INSTANCE_NAME,
       sys_context('USERENV', 'SERVICE_NAME') as SERVICE,
       HOST_NAME,
       VERSION,
       d.PLATFORM_NAME as PLATFORM_NAME,
       DATABASE_STATUS,
       DATABASE_ROLE,
       STATUS,
       d.OPEN_MODE,
       to_char(STARTUP_TIME, 'dd.mm.yyyy hh24:mi:ss') as STARTUP_TIME,
       to_char(RESETLOGS_TIME, 'dd.mm.yyyy hh24:mi:ss') as RESETLOGS_TIME,
       INSTANCE_ROLE,
       ARCHIVER,
       ACTIVE_STATE,
       PARALLEL,
       to_char(THREAD#) as THREAD
from gv$instance, v$database d
order by INST_ID;

set feedback on