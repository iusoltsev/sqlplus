--
-- Outline hints list for sql execution plan from Shared Pool or AWR
-- Usage: SQL> @sql_plan_hints fppuw3hpvww2d [4285086053      ["RA_CUSTOMER_TRX_ALL""@""SEL$118"]]
--                             ^SQL_ID        ^PHV             ^Choose hints like upper('%RA_CUSTOMER_TRX_ALL"@"SEL$118%')
--

set verify off feedback off timi off lines 500
col HINT for a400

/*
select distinct outline_hints
  from (select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
          from xmltable('/*\/outline_data/hint' passing
                        (select xmltype(other_xml) as xmlval
                           from v$sql_plan
                          where sql_id = '&&1'
                            and plan_hash_value = nvl('&&2', plan_hash_value)
                            and other_xml is not null)) d
        union all
        select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
          from xmltable('/*\/outline_data/hint' passing
                        (select xmltype(other_xml) as xmlval
                           from dba_hist_sql_plan
                          where sql_id = '&&1'
                            and plan_hash_value = nvl('&&2', plan_hash_value)
                            and other_xml is not null)) d)
where outline_hints like upper('%&&3%')
*/
select distinct plan_hash_value, hint
  from (select plan_hash_value, b.hint
          from gv$sql_plan m,
               xmltable('/other_xml/outline_data/hint' passing
                        xmltype(m.OTHER_XML) columns hint varchar2(4000) path '/hint') b
         where sql_id = '&&1'
           and plan_hash_value = nvl('&&2', plan_hash_value)
           and trim(OTHER_XML) is not null
        union all
        select plan_hash_value, b.hint
          from dba_hist_sql_plan m,
               xmltable('/other_xml/outline_data/hint' passing
                        xmltype(m.OTHER_XML) columns hint varchar2(4000) path '/hint') b
         where sql_id = '&&1'
           and plan_hash_value = nvl('&&2', plan_hash_value)
           and trim(OTHER_XML) is not null)
 where hint like '%' || upper('&&3') || '%'
-- order by 1
/

/* Hint Usage
select plan_hash_value
     , s.hint as stmt_hint_usage
--     , q.hint as query_hint_usage
--     , t.hint as table_hint_usage
          from gv$sql_plan m
             , xmltable('/other_xml/hint_usage/s/h'   passing xmltype(m.OTHER_XML) columns hint varchar2(4000) path '/h') s
--             , xmltable('/other_xml/hint_usage/q/h'   passing xmltype(m.OTHER_XML) columns hint varchar2(4000) path '/h') q
--             , xmltable('/other_xml/hint_usage/q/t/h' passing xmltype(m.OTHER_XML) columns hint varchar2(4000) path '/h') t
         where sql_id = 'fxm93duu1s001'
and child_number = 0
and trim(OTHER_XML) is not null
*/
set verify on feedback on timi on