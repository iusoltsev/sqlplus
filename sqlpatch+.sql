--
-- Create SQL Patch for given sql_id
-- Usage: SQL> @sqlpatch+ arazapyc4cj4g "opt_param(''optimizer_adaptive_features'' ''false'') NO_BIND_AWARE" "TASK-90522-12c"
-- http://iusoltsev.wordpress.com
--

set echo off feedback on heading on VERIFY OFF serveroutput on
col sql_id for a13
col name for a30
col category for a30
col sql_text for a60
col created for a21
col last_modified for a21
col description for a40
col status for a8
col force_matching for a5

ACCEPT SQL_ID 	      PROMPT 'Enter SQL_ID (required):'
ACCEPT SQL_PATCH_TEXT for a512 PROMPT 'Enter SQL_PATCH_TEXT (required):'
ACCEPT SQL_PATCH_NAME PROMPT 'Enter SQL_PATCH_NAME (required):'

begin
  dbms_sqldiag.drop_sql_patch('&SQL_PATCH_NAME', ignore => TRUE);
  for reco in (--select sql_fulltext from v$sqlarea where sql_id = '&SQL_ID'
	select nvl(sql_fulltext, sql_text) as SQL_FULLTEXT
  		from (select sql_id, sql_text from dba_hist_sqltext where sql_id = '&SQL_ID')
  	full outer join
       		(select sql_id, sql_fulltext from v$sqlarea where sql_id = '&SQL_ID')
 	using (sql_id)) loop
    sys.dbms_sqldiag_internal.i_create_patch(sql_text  => reco.sql_fulltext,
                                             hint_text => '&SQL_PATCH_TEXT',
                                             name      => '&SQL_PATCH_NAME');
  end loop;
end;
/
select sa.sql_id,
       sp.name,
       sp.category,
       --     sp.sql_text,
       to_char(sp.created, 'dd.mm.yyyy hh24:mi:ss') as created,
       --     to_char(sp.last_modified,'dd.mm.yyyy hh24:mi:ss') as last_modified,
       --     sp.description,
       sp.status,
       sp.force_matching as fmatch
  from dba_sql_patches sp, v$sqlarea sa
 where dbms_lob.compare(sp.sql_text, sa.sql_fulltext) = 0
   and sa.sql_id = '&SQL_ID'
/

@SQLPATCH_HINTS "&SQL_PATCH_NAME"

set feedback on echo off VERIFY ON serveroutput off