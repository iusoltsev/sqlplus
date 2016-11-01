select obj as data_object_id, blsiz as blocksize, decode(state,0,'free',1,'xcur',2,'scur',3,'cr', 4,'read',5,'mrec',6,'irec',7,'write',8,'pi', 9,'memory',10,'mwrite',11,'donated', 12,'protected',  13,'securefile', 14,'siop',15,'recckpt') as status
,count(*)
from x$bh where blsiz < 32768
group by obj, blsiz, decode(state,0,'free',1,'xcur',2,'scur',3,'cr', 4,'read',5,'mrec',6,'irec',7,'write',8,'pi', 9,'memory',10,'mwrite',11,'donated', 12,'protected',  13,'securefile', 14,'siop',15,'recckpt')
order by count(*) desc
/
--TBD