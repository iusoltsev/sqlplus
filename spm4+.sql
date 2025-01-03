--
-- Check SPM element (SQL Profile, or SQL Plan Baseline, or SQL Patch) existence for exact SQL_ID
-- Usage: SQL> @spm4 7vq327rya3615
--

set echo off feedback on heading on VERIFY OFF serveroutput on lines 1000

col sql_handle for a30
col patch_name  for a30
col SPM_TYPE for a17
col VERSION for a10
col CREATED       for a19
col LAST_MODIFIED for a19
col LAST_EXECUTED for a19
col LAST_VERIFIED for a19
col ENABLED       for a7
col ACCEPTED      for a8 
col FIXED         for a5   
col REPROD        for a6
col PURGE         for a5
col ADAPT         for a5
col category      for a30
col category_aux  for a30

with
 signs as 
(select distinct DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_text) as E_signature
               , DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_text,force_match => 1) as F_signature
  from dba_hist_sqltext
 where sql_id = '&1'
union
select distinct DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_fulltext) as E_signature
              , DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_fulltext,force_match => 1) as F_signature
  from gv$sqlarea
 where sql_id = '&1')
, spm as (SELECT /*+ dynamic_sampling(3) */
                DECODE(so.obj_type, 1, 'SQL Profile',
                                    2, 'SQL Plan Baseline',
                                    3, 'SQL Patch') as SPM_TYPE,
                so.signature,
                st.sql_handle,
                st.sql_text,
                so.name 			as patch_name,
                ad.creator,
                DECODE(ad.origin, 1, 'MANUAL-LOAD',
                                  2, 'AUTO-CAPTURE',
                                  3, 'MANUAL-SQLTUNE',
                                  4, 'AUTO-SQLTUNE',
                                  5, 'STORED-OUTLINE',
                                     'UNKNOWN') as ORIGIN,
                ad.parsing_schema_name,
                ad.description,
                ad.version,
                ad.created,
                ad.last_modified,
                so.last_executed,
                ad.last_verified,
                DECODE(BITAND(so.flags, 1), 1, 'YES', 'NO')   as ENABLED,
                DECODE(BITAND(so.flags, 2), 2, 'YES', 'NO')   as ACCEPTED,
                DECODE(BITAND(so.flags, 4), 4, 'YES', 'NO')   as FIXED,
                DECODE(BITAND(so.flags, 64), 64, 'NO', 'YES') as REPRODUCED,
                DECODE(BITAND(so.flags, 8), 8, 'YES', 'NO')   as AUTOPURGE,
		DECODE(BITAND(so.flags, 256), 0, 'NO', 'YES') as ADAPTIVE,
    DECODE(BITAND(sq.flags, 1), 1, 'YES', 'NO') as FORCE,
                ad.optimizer_cost,
                substrb(ad.module,1,(select ksumodlen from x$modact_length)) module,
                substrb(ad.action,1,(select ksuactlen from x$modact_length)) action,
                ad.executions,
                ad.elapsed_time,
                ad.cpu_time,
                ad.buffer_gets,
                ad.disk_reads,
                ad.direct_writes,
                ad.rows_processed,
                ad.fetches,
                ad.end_of_fetch_count
, so.category, ad.category as category_aux
            FROM
                sys.sqlobj$        so,
                sys.sqlobj$auxdata ad,
                sys.sql$text       st,
                sys.sql$           sq
               ,signs
            WHERE
                so.signature = st.signature AND
                ad.signature = st.signature AND
                so.signature = ad.signature AND
                so.signature = sq.signature AND
                so.plan_id = ad.plan_id AND
                so.obj_type = ad.obj_type
            AND (so.signature = signs.E_signature or so.signature = signs.F_signature))
--select * from spm
select sa.sql_id,
       SPM_TYPE,
       sql_handle,
       patch_name,
       origin,
       version,
       to_char(created, 'dd.mm.yyyy hh24:mi:ss') as created,
       to_char(last_modified, 'dd.mm.yyyy hh24:mi:ss') as last_modified,
       to_char(last_executed, 'dd.mm.yyyy hh24:mi:ss') as last_executed,
       to_char(last_verified, 'dd.mm.yyyy hh24:mi:ss') as last_verified,
       enabled,
       accepted,
       fixed,
       reproduced,
       autopurge,
       force,
to_char(signature,'99999999999999999999') as spm_signature,
to_char(exact_matching_signature,'99999999999999999999') as sql_exact_signature,
to_char(force_matching_signature,'99999999999999999999') as sql_force_signature
, category, category_aux
  from spm left join gv$sqlarea sa
-- where dbms_lob.compare(bl.sql_text, sa.sql_fulltext) = 0
on (spm.signature = sa.exact_matching_signature or spm.signature = sa.force_matching_signature)
----on (spm.signature = DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sa.sql_fulltext) or spm.signature = DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_text => sa.sql_fulltext,force_match => 1))
--where sa.sql_id = '&&1' or to_char(bl.signature) = '&&1' or bl.sql_handle = '&&1' or bl.patch_name like '&&1'||'%'
--   and decode(SPM_TYPE, 'SQL Plan Baseline', 'YES', accepted) = accepted
where sa.sql_id is not null
union
select h.sql_id,
       SPM_TYPE,
       sql_handle,
       patch_name,
       origin,
       version,
       to_char(created, 'dd.mm.yyyy hh24:mi:ss') as created,
       to_char(last_modified, 'dd.mm.yyyy hh24:mi:ss') as last_modified,
       to_char(last_executed, 'dd.mm.yyyy hh24:mi:ss') as last_executed,
       to_char(last_verified, 'dd.mm.yyyy hh24:mi:ss') as last_verified,
       enabled,
       accepted,
       fixed,
       reproduced,
       autopurge,
       force,
to_char(signature,'99999999999999999999') as spm_signature,
to_char(h.exact_signature,'99999999999999999999'),--to_char(DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(h.sql_text),'99999999999999999999') as sql_exact_signature,
to_char(h.force_signature,'99999999999999999999')--to_char(DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(h.sql_text),'99999999999999999999') as sql_force_signature
, category, category_aux
  from spm left join (select sql_id
                           , DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_text) as exact_signature
                           , DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_text,force_match => 1) as force_signature
                      from dba_hist_sqltext) h
on (spm.signature = h.exact_signature or spm.signature = h.force_signature)
/
set feedback on echo off VERIFY ON serveroutput off
