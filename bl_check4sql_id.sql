--
-- Check SPM baseline existence for exact SQL_ID
-- Usage: SQL> @bl_check4sql_id 4y4bvy7bhkqbn
--

set echo off feedback on heading on VERIFY OFF serveroutput on lines 1000

col sql_handle for a30
col plan_name  for a30
col VERSION    for a10
col PHV_full   for a10
col PHV        for a10
col PHV2       for 9999999999
col created       for a19
col last_modified for a19
col last_executed for a19
col last_verified for a19


select
    sql_handle,
    plan_name,
    origin,
    version,
    to_char(created,       'yyyy\mm\dd hh24:mi:ss') as created,
    to_char(last_modified, 'yyyy\mm\dd hh24:mi:ss') as last_modified,
    to_char(last_executed, 'yyyy\mm\dd hh24:mi:ss') as last_executed,
    to_char(last_verified, 'yyyy\mm\dd hh24:mi:ss') as last_verified,
    enabled,
    accepted,
    fixed,
    reproduced,
    autopurge,
    extractvalue(xmlval, '/*/info[@type = "plan_hash_full"]') as PHV_full, 
    extractvalue(xmlval, '/*/info[@type = "plan_hash"]')      as PHV,
    plan_id                                                   as PHV2
from
 (select xmltype(other_xml) as xmlval,
         bl.sql_handle,
         bl.plan_name,
         bl.origin,
         bl.version,
         bl.created,
         bl.last_modified,
         bl.last_executed,
         bl.last_verified,
         bl.enabled,
         bl.accepted,
         bl.fixed,
         bl.reproduced,
         bl.autopurge,
         op.plan_id
                   from dba_sql_plan_baselines bl
                   left join sys.sqlobj$ o      on o.name = bl.plan_name and o.signature = bl.signature and o.obj_type = 2
                   left join sys.sqlobj$plan op on op.obj_type = 2 and o.signature = op.signature and o.plan_id   = op.plan_id and op.other_xml is not null
  where bl.SIGNATURE = (select DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(SQL_TEXT) as SIGNATURE from dba_hist_sqltext where sql_id = '&&1'
                        union
                        select distinct EXACT_MATCHING_SIGNATURE as SIGNATURE from gv$sqlarea where sql_id = '&&1'))
 order by 10, 5 -- cast(last_modified as date)
/
set feedback on echo off VERIFY ON serveroutput off