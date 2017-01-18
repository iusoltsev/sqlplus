--
-- DB Segment Caching
-- Oracle 10.2+
-- Usage: SQL> @db_seg_cache SCOTT EMP ["PART#1[','PART#2[','...]]"]
-- Igor Usoltsev
--

SET VERIFY OFF linesize 200

col AREA                 for a12
col STATUS               for a30
col DISTINCT_BLOCK_COUNT for a40
col BLOCK_COUNT          for a12
col PARTITION_NAME       for a30

with OBJLIST as
 (select DATA_OBJECT_ID,
         subobject_name as partition_name
    from dba_objects
   where owner = upper(nvl('&&1', 'user'))
     and object_name in upper(('&&2'))
     and (subobject_name in ('&&3') or exists (select column_value from TABLE(sys.OdciVarchar2List('&&3')) where column_value is null))
     and DATA_OBJECT_ID is not null)
select 'BUFFER CACHE' as AREA,
        nvl(partition_name,'ALL') as partition_name,
        nvl(status,'ALL') as STATUS,
        to_char(count(distinct(file# || '#' || block#))) as DISTINCT_BLOCK_COUNT,
        to_char(count(*)) as BLOCK_COUNT
  from V$BH join OBJLIST on objd = DATA_OBJECT_ID
 group by rollup(status, partition_name)
union all
select 'DATABASE',
	partition_name,
       'db blocks',
        to_char(blocks),
       '' as BH_COUNT
from dba_segments
 where owner = upper(nvl('&&1', 'user'))
 and segment_name in upper(('&&2'))
 and (partition_name in ('&&3') or exists (select column_value from TABLE(sys.OdciVarchar2List('&&3')) where column_value is null))
--order by partition_name
union all
select 'SGA',
       '',
       'BUFFER CACHE of MAX SGA SIZE',
       trim(to_char(s1.bytes, '999,999,999,999,999')) ||
       ' of '||
       trim(to_char(s2.bytes, '999,999,999,999,999')),
       '(' || decode(s1.resizeable, 'Yes', 'Resizeable', 'Fixed') || ')'
from v$sgainfo s1, v$sgainfo s2 where s1.name = 'Buffer Cache Size' and s2.name = 'Maximum SGA Size'
/

rem SET VERIFY ON