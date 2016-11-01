SET VERIFY OFF
set linesize 500
set pagesize 200
column name format a56
column value format a44
column dsc format a100
column is_def format a8
column is_mod format a10
column is_adj format a8

select
  x.ksppinm  name,
  y.kspftctxvl  value,
  y.kspftctxdf  is_def,
  decode(bitand(y.kspftctxvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE')  is_mod,
  decode(bitand(y.kspftctxvf,2),2,'TRUE','FALSE')  is_adj,
  x.Ksppdesc dsc
from
  sys.x$ksppi  x,
  sys.x$ksppcv2  y
where
  x.inst_id = userenv('Instance') and
  y.inst_id = userenv('Instance') and
  x.indx+1 = y.kspftctxpn
and (ksppinm like lower('%'||'&&1'||'%') escape '\'
     OR lower(Ksppdesc) like lower('%'||'&&1'||'%') escape '\'
     OR lower(to_char(kspftctxvl)) like lower('%'||'&&1'||'%') escape '\')
order by translate(x.ksppinm, ' _', ' ')
/

SET VERIFY ON