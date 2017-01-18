--
-- Sql Plan Hash pairs (PLAN_HASH_VALUE and FULL_PLAN_HASH_VALUE) list
-- SQL> @sql_plan_hashs &sql_id [&full_plan_hash_value] [&plan_hash_value]
--
col TIMESTAMP for a20

with plan_hashs as
 (select 'AWR' as SRC,
         SQL_ID,
         to_number(extractvalue(h.column_value, '/info')) as FULL_PLAN_HASH_VALUE,
         p.PLAN_HASH_VALUE,
         p.TIMESTAMP
    from dba_hist_sql_plan p,
         table(xmlsequence(extract(xmltype(p.other_xml), '/other_xml/info'))) h
   where p.other_xml is not null
     and sql_id = '&&1'
     and extractvalue(h.column_value, '/info/@type') = 'plan_hash_full'
  union
  select 'SQL' as SRC,
         sql_id,
         full_plan_hash_value,
         plan_hash_value,
         max(TIMESTAMP)
    from gv$sql_plan
   where sql_id = '&&1'
   group by sql_id, full_plan_hash_value, plan_hash_value)
select SRC,
       sql_id,
       full_plan_hash_value,
       plan_hash_value,
       to_char(TIMESTAMP,'dd.mm.yyyy hh24:mi:ss') as TIMESTAMP
  from plan_hashs
 where full_plan_hash_value = nvl('&2', full_plan_hash_value)
   and plan_hash_value = nvl('&3', plan_hash_value)
order by 3, 4
/