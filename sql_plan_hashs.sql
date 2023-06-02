--
-- Sql Plan Hash pairs (PLAN_HASH_VALUE and FULL_PLAN_HASH_VALUE) list
-- SQL> @sql_plan_hashs [&sql_id] || [&full_plan_hash_value] || [&plan_hash_value]
--
col TIMESTAMP for a20

with plan_hashs as
 (select 'AWR' as SRC,
         SQL_ID,
         to_number(extractvalue(xmltype(other_xml), '/*/info[@type = "plan_hash_full"]')) as full_plan_hash_value,
         p.PLAN_HASH_VALUE,
         to_number(extractvalue(xmltype(other_xml), '/*/info[@type = "plan_hash_2"]'))    as plan_hash_2,
         p.TIMESTAMP
, dbid
, con_dbid
    from dba_hist_sql_plan p
   where p.other_xml is not null
     and sql_id = nvl('&1', sql_id)--'&&1'
  union
  select 'SQL' as SRC,
         sql_id,
         full_plan_hash_value,
         plan_hash_value,
         to_number(extractvalue(xmltype(other_xml), '/*/info[@type = "plan_hash_2"]'))    as plan_hash_2,
         max(TIMESTAMP)
, to_number(SYS_CONTEXT('USERENV','DBID')) as dbid
, to_number(SYS_CONTEXT('USERENV','CON_DBID')) as con_dbid
    from gv$sql_plan
   where sql_id = nvl('&1', sql_id)--'&&1'
     and other_xml is not null
   group by sql_id, full_plan_hash_value, plan_hash_value, to_number(extractvalue(xmltype(other_xml), '/*/info[@type = "plan_hash_2"]')))
select SRC,
       sql_id,
       full_plan_hash_value,
       plan_hash_value,
       plan_hash_2,
       to_char(TIMESTAMP,'dd.mm.yyyy hh24:mi:ss') as TIMESTAMP
, dbid
, con_dbid
  from plan_hashs
 where (full_plan_hash_value = nvl('&2', full_plan_hash_value) or '&2' = '0')
   and (plan_hash_value = nvl('&3', plan_hash_value) or '&3' = '0')
order by 3, 5, 4
/