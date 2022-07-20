--
-- Create SQL Patch for given sql_id [w/o ACCEPTION]
-- Usage: SQL> @sqlpatch+l arazapyc4cj4g "opt_param(''''optimizer_adaptive_features'''' ''''false'''') NO_BIND_AWARE" "TASK-90522-12c"
-- http://iusoltsev.wordpress.com
--

set echo off feedback on heading on VERIFY OFF serveroutput off
col sql_id for a13
col name for a30
col category for a30
col sql_text for a60
col created for a21
col last_modified for a21
col description for a40
col status for a8
col force_matching for a5

--ACCEPT SQL_ID 	      PROMPT 'Enter SQL_ID (required):'
--ACCEPT SQL_PATCH_TEXT for a512 PROMPT 'Enter SQL_PATCH_TEXT (required):'
--ACCEPT SQL_PATCH_NAME for a512 PROMPT 'Enter SQL_PATCH_NAME (required):'
--ACCEPT E PROMPT 'Enter'
--PROMPT Press <CR> to continue...
--PAUSE

declare
  v_version SYS.V_$INSTANCE.version%type;
  v_plsql   varchar2(4096);
  spm_already_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(spm_already_exists, -13829);
begin
  select version into v_version from SYS.V_$INSTANCE;
  dbms_sqldiag.drop_sql_patch('&&3', ignore => TRUE);
  for reco in (--select sql_fulltext from v$sqlarea where sql_id = '&SQL_ID'
	select nvl(sql_fulltext, sql_text) as SQL_FULLTEXT
  		from (select sql_id, sql_text from dba_hist_sqltext where sql_id = '&&1')
  	full outer join
       		(select sql_id, sql_fulltext from v$sqlarea where sql_id = '&&1')
 	using (sql_id)
where rownum <= 1)
  loop
    if v_version like '12.2%' OR substr(v_version,1,2) >= 18
/*
       then f := sys.dbms_sqldiag_internal.i_create_patch(sql_text  => reco.sql_fulltext,
                                                          hint_text => '&&SQL_PATCH_TEXT',
                                                          creator   => user,
                                                          name      => '&&SQL_PATCH_NAME');
       else sys.dbms_sqldiag_internal.i_create_patch(sql_text  => reco.sql_fulltext,
                                                     hint_text => '&&SQL_PATCH_TEXT',
                                                     name      => '&&SQL_PATCH_NAME');
*/
   then v_plsql := 'declare f varchar2(30); begin f := sys.dbms_sqldiag_internal.i_create_patch(sql_text  => :sql_text, hint_text => '''||'&&2'||''', creator => user,name => '''||'&&3'||'''); END;';
--dbms_output.put_line(v_plsql);
        EXECUTE IMMEDIATE v_plsql USING reco.sql_fulltext;
   else v_plsql := 'begin sys.dbms_sqldiag_internal.i_create_patch(sql_text => :sql_text, hint_text => '''||'&&2'||''',name => '''||'&&3'||'''); END;';
        EXECUTE IMMEDIATE v_plsql USING reco.sql_fulltext;
    end if;
  end loop;
EXCEPTION
   WHEN spm_already_exists THEN null; -- ORA-13829: SQL profile or patch named % exists
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
   and sa.sql_id = '&&1'
/

@SQLPATCH_HINTS "&&SQL_PATCH_NAME"

/* 12.2+
declare
  f varchar2(30);
begin
  dbms_sqldiag.drop_sql_patch('PAYSYSADMIN-4030', ignore => TRUE);
  for reco in (--select sql_fulltext from v$sqlarea where sql_id = '&SQL_ID'
	select nvl(sql_fulltext, sql_text) as SQL_FULLTEXT
  		from (select sql_id, sql_text from dba_hist_sqltext where sql_id = 'bbb2833tzk9bm')
  	full outer join
       		(select sql_id, sql_fulltext from v$sqlarea where sql_id = 'bbb2833tzk9bm')
 	using (sql_id)) loop
          f := sys.dbms_sqldiag_internal.i_create_patch(sql_text  => reco.sql_fulltext,
                                                   hint_text   => 'parallel(8)',
                                                   creator     => user,
                                                   name => 'PAYSYSADMIN-4030');
  end loop;
end;
*/

set feedback on echo off VERIFY ON serveroutput off
