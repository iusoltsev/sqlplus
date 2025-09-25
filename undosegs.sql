--
-- Undo space estimation and reqiurements from V$UNDOSTAT
--

set verify off

col INST_ID for 999
col UNDO_RETENTION_PARAM for a20
col Undo_TS_Size_MB for 999,999,999
col Max_Rec_Undo_MB for 999,999,999
col Avg_Rec_Undo_MB for 999,999,999

@@sysdate
select tablespace_name, count(distinct segment_name) as segs, round(sum(bytes/1024/1024/1024)) as gb, sum(blocks), count(*) from DBA_UNDO_EXTENTS group by tablespace_name;
set verify on