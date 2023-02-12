SET VERIFY OFF echo off
set linesize 500
set pagesize 200
column name format a60
column value format a44
column dsc format a100
column is_def format a8
column IS_SESS_MOD format a11
column IS_SYS_MOD format a10
column is_adj format a8
column Sess_Value for a60
column Inst_Value for a60

SELECT a.ksppinm  name,
       b.ksppstvl Sess_Value,
       c.ksppstvl Inst_Value,
b.KSPPSTDF "Default Value",
       decode(bitand(y.kspftctxvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE')                  IS_MODIFIED,
       decode(bitand(a.ksppiflg/256,1),1,'TRUE','FALSE')                                   IS_SESS_MOD,
       decode(bitand(a.ksppiflg/65536,3),1,'IMMEDIATE',2,'DEFERRED',3,'IMMEDIATE','FALSE') IS_SYS_MOD,
       decode(bitand(a.ksppiflg/524288,1),1,'TRUE','FALSE')                                IS_PDB_MODIFIABLE,
       decode(bitand(y.kspftctxvf,2),2,'TRUE','FALSE')  is_adj,
       Ksppdesc as dsc
FROM   x$ksppi a,
       x$ksppcv b,
       x$ksppsv c
,x$ksppcv2  y
where
a.inst_id = userenv('Instance') and
y.inst_id = userenv('Instance') and
a.indx+1 = y.kspftctxpn
AND   a.indx = b.indx
AND   a.indx = c.indx
AND   (lower(a.ksppinm) like lower('%'||'&1'||'%') escape '\'
       OR lower(Ksppdesc) like lower('%'||'&&1'||'%') escape '\')
--     OR lower(to_char(kspftctxvl)) like lower('%'||'&&1'||'%') escape '\')
/
SET VERIFY ON echo on
