--
-- Oracle OS processes w/o active SID
-- Usage: SQL> @ps2kill
-- by Igor Usoltsev
--

SET VERIFY OFF

col AREA                 for a12
col STATUS               for a30
col command              for a40
col BLOCK_COUNT          for a12

SELECT p.username,
       p.terminal,
       s.sid,
       s.program as os_program,
       p.program as ora_program,
       s.status  as sesstatus,
       'kill -9 ' || p.spid as command
  FROM gv$process p
  left join gv$session s
    on p.inst_id = s.inst_id
   and s.paddr = p.addr
 WHERE (s.sid is null or s.status = 'KILLED')
   and UPPER(p.program) not like '%PSEUDO%'
   and UPPER(p.program) not like '%D0%'
   and UPPER(p.program) not like '%S0%'
   and UPPER(p.program) not like '%(P%'
/

SET VERIFY ON