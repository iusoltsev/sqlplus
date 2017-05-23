SET VERIFY OFF echo off
set linesize 500
set pagesize 200
column name format a36
column value format a44
column dsc format a100
column is_def format a8
column IS_SESS_MOD format a11
column IS_SYS_MOD format a10
column is_adj format a8
column Sess_Value for a10
column Inst_Value for a10

SELECT a.ksppinm  name,
       b.ksppstvl Sess_Value,
       c.ksppstvl Inst_Value,
       decode(bitand(a.ksppiflg/256,1),1,'TRUE','FALSE')                                   IS_SESS_MOD,
       decode(bitand(a.ksppiflg/65536,3),1,'IMMEDIATE',2,'DEFERRED',3,'IMMEDIATE','FALSE') IS_SYS_MOD,
       Ksppdesc as dsc
FROM   x$ksppi a,
       x$ksppcv b,
       x$ksppsv c
WHERE  a.indx = b.indx
AND    a.indx = c.indx
AND   (a.ksppinm like '%'||'&1'||'%' escape '\'
       OR lower(Ksppdesc) like lower('%'||'&&1'||'%') escape '\')
--     OR lower(to_char(kspftctxvl)) like lower('%'||'&&1'||'%') escape '\')
/
SET VERIFY ON echo on