--
-- Undo space estimation and reqiurements from V$UNDOSTAT
--

set verify off

col INST_ID for 999
col UNDO_RETENTION_PARAM for a20
col Undo_TS_Size_MB for 999,999,999
col Max_Rec_Undo_MB for 999,999,999
col Avg_Rec_Undo_MB for 999,999,999

with undo_retention as
 (select inst_id, value from gv$parameter where name = 'undo_retention'),
undo_ts as
 (select p.inst_id,
       t.blocksize,
       sum(f.bytes) BYTES
  FROM sys.ts$ t, gv$parameter p, v$datafile f
 WHERE p.name = 'undo_tablespace'
   and t.name = UPPER(p.value)
   and t.ts# = f.ts#
 group by p.inst_id, t.blocksize),
UndoBlockGeneration as
 (SELECT inst_id,
       max( undoblks / ((end_time - begin_time) * 86400)) max_bytes_per_sec,
       avg( undoblks / ((end_time - begin_time) * 86400)) avg_bytes_per_sec
    FROM gv$undostat group by inst_id),
UndoStat as
  (select inst_id,
         min(TUNED_UNDORETENTION) min_tuned_undoretention,
         avg(TUNED_UNDORETENTION) avg_tuned_undoretention,
         max(TUNED_UNDORETENTION) max_tuned_undoretention
    from gv$undostat
   group by inst_id)
select inst_id,
       round(undo_ts.bytes / 1024 / 1024) Undo_TS_Size_MB,
       round((undo_retention.value * undo_ts.blocksize * UndoBlockGeneration.avg_bytes_per_sec) / 1024 / 1024) Avg_Rec_Undo_MB,
       round((undo_retention.value * undo_ts.blocksize * UndoBlockGeneration.max_bytes_per_sec) / 1024 / 1024) Max_Rec_Undo_MB,
       undo_retention.value UNDO_RETENTION_PARAM,
       UndoStat.MIN_TUNED_UNDORETENTION,
       round(UndoStat.AVG_TUNED_UNDORETENTION) as AVG_TUNED_UNDORETENTION,
       UndoStat.MAX_TUNED_UNDORETENTION
  from undo_retention
    natural join undo_ts
    natural join UndoBlockGeneration
    natural join UndoStat
/

set verify on