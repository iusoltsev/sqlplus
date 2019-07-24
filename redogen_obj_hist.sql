--
-- Redo generation top by object from AWR history
-- Usage: SQL> @redogen_obj_hist "03-Sep-13 16:00" "03-Sep-13 17:00" 10
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col WHEN for a34
col object_name for a30
col REDO_PERCENT HEADING 'Redo_%' for a6
col OBJECT_TYPE for a18
col OBJECT_NAME for a45
col TABLE_NAME for a45
col TABLE_OWNER for a30
col MIN_CTIME for a20
col MAX_CTIME for a20
col DML_ROWS for  a20
rem col DB_BLOCK_CHANGES for a16
break on WHEN

select * from (
SELECT to_char(min(begin_interval_time),'DD-Mon-YY HH24:MI') || ' - ' ||
       to_char(max(end_interval_time),'DD-Mon-YY HH24:MI') as WHEN,
       nvl(dhso.object_name, 'obj#'||obj#||' dataobj#'||dataobj#) as object_name,
       dhso.subobject_name,
       dhso.object_type,
       i.table_name,
       sum(db_block_changes_delta) as db_block_changes,
--       to_char(
round((RATIO_TO_REPORT(sum(db_block_changes_delta)) OVER ())*100,2)--,'99.00')
 as REDO_PERCENT
, dhss.con_id
  FROM dba_hist_seg_stat dhss
       join dba_hist_snapshot dhs using(snap_id, instance_number)
       left join dba_hist_seg_stat_obj dhso  using(obj#, dataobj#)
       left join dba_indexes i on dhso.owner = i.owner and dhso.object_name = i.index_name and dhso.object_type like 'INDEX%'
  WHERE begin_interval_time BETWEEN to_date('&&1', 'DD-Mon-YY HH24:MI')
                                AND to_date('&&2', 'DD-Mon-YY HH24:MI')
  GROUP BY --to_char(begin_interval_time,'YY-MM-DD HH24:MI'),
       dhso.object_type,
       nvl(dhso.object_name, 'obj#'||obj#||' dataobj#'||dataobj#),
       dhso.subobject_name,
       i.table_name
, dhss.con_id
  ORDER BY --to_char(begin_interval_time,'YY-MM-DD HH24:MI'),
           db_block_changes desc
) where rownum <= &&3
/
select
      WHEN,
      object_name,
      object_type,
      table_name,
      db_block_changes,
      REDO_PERCENT,
      sum(db_block_changes) over(partition by NVL(table_name, object_name)) as DB_BLOCKS_TOTAL,
      sum(REDO_PERCENT) over(partition by NVL(table_name, object_name)) as REDO_PERCENT_TOTAL
      from (
      SELECT to_char(min(begin_interval_time),'DD-Mon-YY HH24:MI') || ' - ' ||
             to_char(max(end_interval_time),'DD-Mon-YY HH24:MI') as WHEN,
             nvl(dhso.owner || '.' || dhso.object_name, 'obj#'||obj#||' dataobj#'||dataobj#) as object_name,
             dhso.object_type,
             i.table_owner || nvl2(i.table_name,'.','') || i.table_name as table_name,
             sum(db_block_changes_delta) as db_block_changes,
--             to_char(
round((RATIO_TO_REPORT(sum(db_block_changes_delta)) OVER ())*100,2)--,'99.00')
 as REDO_PERCENT
      , dhss.con_id
        FROM dba_hist_seg_stat dhss
             join dba_hist_snapshot dhs using(snap_id, instance_number)
             left join dba_hist_seg_stat_obj dhso  using(obj#, dataobj#)
             left join dba_indexes i on dhso.owner = i.owner and dhso.object_name = i.index_name and dhso.object_type like 'INDEX%'
        WHERE begin_interval_time BETWEEN to_date('&&1', 'DD-Mon-YY HH24:MI')
                                      AND to_date('&&2', 'DD-Mon-YY HH24:MI')
        GROUP BY dhso.object_type,
                 nvl(dhso.owner || '.' || dhso.object_name, 'obj#'||obj#||' dataobj#'||dataobj#),
                 i.table_owner || nvl2(i.table_name,'.','') || i.table_name
               , dhss.con_id
      )
order by REDO_PERCENT_TOTAL desc
fetch first &&3 rows only
/
/*
select table_owner,
       table_name,
       sum(inserts + updates + deletes) as DML_ROWS,
       min(timestamp)                   as MIN_CTIME,
       max(timestamp)                   as MAX_CTIME
  from dba_tab_modifications
 group by table_owner, table_name
 order by sum(inserts + updates + deletes) desc fetch first &&3 rows only
*/
set feedback on echo off VERIFY ON timi on