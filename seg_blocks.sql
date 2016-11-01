with rowid_blocks as
 (select /*+ materialize*/
   dbms_rowid.rowid_relative_fno(rowid) relative_fno,
   dbms_rowid.rowid_block_number(rowid) block_number
    from "&&1"."&&2")
select relative_fno,
       count(distinct block_number) used_blocks,
       count(block_number) used_rows
  from rowid_blocks
 group by rollup(relative_fno)
/