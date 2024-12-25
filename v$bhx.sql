SET VERIFY OFF
col OWNER for a30
col OBJECT_NAME for a30
col STATUS for a10
col blk_count for 999999999999

select
--indx,
o.object_name,decode(state,0,'free',1,'xcur',2,'scur',3,'cr', 4,'read',5,'mrec',6,'irec',7,'write',8,'pi') state,
decode(class,1,'data block',2,'sort block',3,'save undo block', 4,'segment header',5,'save undo header',6,'free list',7,'extent map',
8,'1st level bmb',9,'2nd level bmb',10,'3rd level bmb', 11,'bitmap block',12,'bitmap index block',13,'file header block',14,'unused',
15,'system undo header',16,'system undo block', 17,'undo header',18,'undo block') class_type
--, dbarfil
--, dbablk
--, ba
--,tch
, count(*)
from x$bh b , dba_objects o
where b.obj = o.data_object_id
and o.OWNER = nvl(upper('&1'), user)
   and o.OBJECT_NAME = upper('&2')
and state > 0
group by
o.object_name,decode(state,0,'free',1,'xcur',2,'scur',3,'cr', 4,'read',5,'mrec',6,'irec',7,'write',8,'pi'),
decode(class,1,'data block',2,'sort block',3,'save undo block', 4,'segment header',5,'save undo header',6,'free list',7,'extent map',
8,'1st level bmb',9,'2nd level bmb',10,'3rd level bmb', 11,'bitmap block',12,'bitmap index block',13,'file header block',14,'unused',
15,'system undo header',16,'system undo block', 17,'undo header',18,'undo block')
/
/*
select o.OWNER,
       o.OBJECT_NAME,
       nvl(bh.status, 'SUMMARY') as STATUS,
       count(*) as blk_count
  from v$bh bh, dba_objects o
 where bh.OBJD = o.DATA_OBJECT_ID
   and o.OWNER = nvl(upper('&1'), user)
   and o.OBJECT_NAME = upper('&2')
 group by o.OWNER, o.OBJECT_NAME, rollup(bh.status)
*/
SET VERIFY ON