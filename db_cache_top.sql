--
-- DB Cached Obj TOP
-- Oracle 10.2+
-- Usage: SQL> @db_cache_top [5]
-- Igor Usoltsev
--

SET VERIFY OFF

col owner                for a30
col object_type          for a30
col object_name          for a30
col BLOCK_COUNT          for 999,999,999,999

select--+ RULE
 *
  from (select o.owner, o.object_type, o.object_name, count(*) as BLOCK_COUNT
          from V$BH bh, dba_objects o
         where o.data_object_id = bh.objd
         group by o.owner, o.object_type, o.object_name
         order by count(*) desc)
 where rownum <= nvl('&&1',10)
/

SET VERIFY ON