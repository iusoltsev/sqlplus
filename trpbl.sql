--Table Rows over datablock distribution
set echo off
with q as (SELECT--+ materialize
           dbms_rowid.rowid_relative_fno(rowid) fno,
           dbms_rowid.rowid_block_number(rowid) bno
           from &1)
/*select fno, bno, count(*) as ROWS_PER_BLOCK
,'' as MIN_ROWS_PER_BLOCK
,'' as MAX_ROWS_PER_BLOCK
FROM q group by fno, bno order by count(*)
union all*/
select
--'' as fno,
--'' as bno,
--'' as ROWS_PER_BLOCK,
min(ROWS_PER_BLOCK) as MIN_ROWS_PER_BLOCK,
max(ROWS_PER_BLOCK) as MAX_ROWS_PER_BLOCK
from (select fno, bno, count(*) as ROWS_PER_BLOCK FROM q group by fno, bno)
/
set echo on
