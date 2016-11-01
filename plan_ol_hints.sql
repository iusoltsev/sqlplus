--
-- Outline hints list for sql execution plan from Shared Pool or AWR
-- Usage: SQL> @plan_ol_hints guh7dff6fsac9 [1752872774]     [index]
--                            ^SQL_ID       ^PLAN_HASH_VALUE  ^Hint like upper('%index%')
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
 where hint like upper('%&&3%')
-- order by 1
/

set verify on feedback on timi on