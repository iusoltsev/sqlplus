--
-- SQL> @xplan "8bqf8qfgpcq9t" "0" "all allstats advanced -alias -outline +note +parallel +remote -projection +peeked_binds +predicate last"
--

set feedback off heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col DEP_TREE_BY_ID for a80
col DEP_TREE for a60
col DEPENDS_ON for a12

SELECT * FROM TABLE(dbms_xplan.display_cursor('&1','&2','&3'))
/
set feedback on VERIFY ON timi on