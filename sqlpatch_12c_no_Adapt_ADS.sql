--
-- Creates the "special" 12.1 SQL Patch which turns off the 12c Adaptive Features, and sets the Adaptive Dynamic Sampling level for given sql_id
-- Usage: SQL> @sqlpatch_12c_no_Adapt_ADS arazapyc4cj4g 9
--                                        ^sql_id       ^ADS level
-- http://iusoltsev.wordpress.com
--

set echo off feedback on heading on VERIFY OFF serveroutput on

begin
  dbms_sqldiag.drop_sql_patch('NO_ADAPT_&&1', ignore => TRUE);
  for reco in (select nvl(sql_fulltext, sql_text) as SQL_FULLTEXT
  		from (select sql_id, sql_text from dba_hist_sqltext where sql_id = '&&1')
               full outer join
       		(select sql_id, sql_fulltext from v$sqlarea where sql_id = '&&1') using (sql_id))
  loop
    sys.dbms_sqldiag_internal.i_create_patch(sql_text  => reco.sql_fulltext,
                                             hint_text => 'opt_param(''optimizer_adaptive_features'' ''false'') no_bind_aware OPT_PARAM(''optimizer_dynamic_sampling'' &&2)',
                                             name      => 'NO_ADAPT_&&1');
  end loop;
end;
/
@@spm_check4sql_id &&1
@@SQLPATCH_HINTS "NO_ADAPT_&&1"

set VERIFY ON serveroutput off