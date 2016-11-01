SET VERIFY OFF
col OWNER for a30
col OBJECT_NAME for a30
col STATUS for a10
col blk_count for 999999999999

select o.OWNER,
       o.OBJECT_NAME,
       nvl(bh.status, 'SUMMARY') as STATUS,
       count(*) as blk_count
  from v$bh bh, dba_objects o
 where bh.OBJD = o.DATA_OBJECT_ID
   and o.OWNER = nvl(upper('&1'), user)
   and o.OBJECT_NAME = upper('&2')
 group by o.OWNER, o.OBJECT_NAME, rollup(bh.status)
/
SET VERIFY ON