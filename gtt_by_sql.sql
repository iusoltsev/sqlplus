--
-- Global Temporary Table by SQL_ID
-- Usage: SQL> @gtt_by_sql &SQL_ID
-- based on Laurent Leturgez script https://laurent-leturgez.com/2016/12/21/view-gtt-size/
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

select s.sid,
       s.serial#,
       s.program,
       o.obj#,
       o.name,
       temp_obj.ktssosqlid SQL_ID,
       decode(bitand(o.flags, 2), 0, 'N', 2, 'Y', 'N') temporary,
       temp_obj.ktssoexts extents,
       temp_obj.ktssoblks blocks,
       temp_obj.ktssoblks * blk_sz.bs bytes
  from obj$ o,
       (select * from x$ktsso) temp_obj, -- local !
       (select value bs from v$parameter where name = 'db_block_size') blk_sz,
       v$session s,
       tab$ t
 where o.obj# = temp_obj.KTSSOOBJN
   and t.obj# = o.obj#
   and bitand(o.flags, 2) = 2
   and s.saddr = temp_obj.ktssoses
   and ktssosqlid like '&1'
 order by 6
/
set feedback on echo off VERIFY ON