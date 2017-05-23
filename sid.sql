col sid format a10
col inst_id format a7
col INSTANCE_NAME format a13
col SESSION_USER format a30
col CURRENT_SCHEMA format a30
col DEF_TS format a30
col DEF_TEMP format a30
col TRACEFILE for a200
col TX_START_TIME for a20
col PDML for a4

select sys_context('userenv', 'instance') as inst_id,
       sys_context('userenv', 'sid') as sid,
       s.SERIAL#,
       s.saddr,
       t.xid,
       t.START_TIME as TX_START_TIME,
       sys_context('userenv', 'SESSION_USER') as SESSION_USER,
       sys_context('userenv', 'CURRENT_SCHEMA') as CURRENT_SCHEMA,
       s.SERVER,
       s.PDML_ENABLED as PDML,
       p.PID,
       p.SPID,
       u.DEFAULT_TABLESPACE as DEF_TS,
       u.TEMPORARY_TABLESPACE as DEF_TEMP,
       i.host_name || ':' || p.tracefile as tracefile
  from v$session     s,
       user_users    u,
       v$process     p,
       v$instance    i,
       v$transaction t
 where s.SID = sys_context('userenv', 'sid')
   and sys_context('userenv', 'SESSION_USER') = u.USERNAME
   and s.PADDR = p.ADDR
   and s.SADDR = t.SES_ADDR(+)
/