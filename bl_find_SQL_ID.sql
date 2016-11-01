--
-- 2find exact SQL_ID and PLAN_HASH_VALUE for SPM baseline, searching for the matching sql text and plan outlines in Shared pool and AWR
-- Usage: SQL> @bl_find_SQL_ID [SQL_148cdf9124bc55dd | SQL_PLAN_1936zk4kbspfxee773f4d]
--                             ^SQL_HANDLE OR PLAN_NAME | SQL_HANDLE AND PLAN_NAME
--

set echo off feedback on heading on VERIFY OFF serveroutput on
BREAK ON BL_EXEC_TIMESTAMP ON BL_REPRODUCED

col sql_id             for a13
col plan_hash_value    for 999999999999999
col SQL_EXEC_TIMESTAMP for a20
col SQL_TYPE           for a15
col SQL_HANDLE         for a20
col PLAN_NAME          for a30
col REPRODUCED         for a13
col BL_LAST_EXECUTED   for a20

with sql_bl_list as ( -- The list of SQLs with the same sql text signature of baseline
select s.sql_id,
       s.plan_hash_value,
       'V$SQL'                                                                     as SQL_TYPE,
       to_char(max(s.last_active_time), 'dd.mm.yyyy hh24:mi:ss')                   as SQL_EXEC_TIMESTAMP,
       bl.sql_handle,
       bl.plan_name,
       bl.enabled,
       bl.accepted,
       bl.fixed,
       bl.REPRODUCED,
       to_char(bl.last_executed, 'dd.mm.yyyy hh24:mi:ss')                          as BL_LAST_EXECUTED
  from dba_sql_plan_baselines bl,
       gv$sql                 s
 where bl.sql_handle = nvl('&&1',bl.sql_handle) and bl.plan_name = nvl('&&2',bl.plan_name) -- OR|AND
   and bl.signature = s.exact_matching_signature
--   and bl.accepted = 'YES'
 group by s.sql_id,
          s.plan_hash_value,
          bl.sql_handle,
          bl.plan_name,
          bl.enabled,
          bl.accepted,
          bl.fixed,
          bl.REPRODUCED,
          to_char(bl.last_executed, 'dd.mm.yyyy hh24:mi:ss')
union
select sa.sql_id,
       spa.plan_hash_value,
       'DBA_HIST_SQL',
       to_char(max(spa.timestamp), 'dd.mm.yyyy hh24:mi:ss'),
       bl.sql_handle,
       bl.plan_name,
       bl.enabled,
       bl.accepted,
       bl.fixed,
       bl.REPRODUCED,
       to_char(bl.last_executed, 'dd.mm.yyyy hh24:mi:ss')
  from dba_sql_plan_baselines bl,
       dba_hist_sqltext       sa,
       dba_hist_sql_plan      spa
 where bl.sql_handle = nvl('&&1',bl.sql_handle) and bl.plan_name = nvl('&&2',bl.plan_name) -- OR|AND
   and sa.sql_id = spa.sql_id
   and bl.signature = DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sa.sql_text)
--   and bl.accepted = 'YES'
 group by sa.sql_id,
          spa.plan_hash_value,
          bl.sql_handle,
          bl.plan_name,
          bl.enabled,
          bl.accepted,
          bl.fixed,
          bl.REPRODUCED,
          to_char(bl.last_executed, 'dd.mm.yyyy hh24:mi:ss'))
, sql_bl_phv_list as -- The list of SQLs with the same signature and plan_hash_value of baseline
(select * from sql_bl_list l
 where not exists
   (select distinct substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
    from xmltable('/*/outline_data/hint' passing
                  (select xmltype(other_xml) as xmlval
                     from gv$sql_plan
                    where sql_id          = l.sql_id
                      and plan_hash_value = l.plan_hash_value
                      and other_xml is not null
                      and rownum <= 1)) d -- the same phv high version count
    union
    select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
    from xmltable('/*/outline_data/hint' passing
                  (select xmltype(other_xml) as xmlval
                     from DBA_HIST_SQL_PLAN
                    where sql_id          = l.sql_id
                      and plan_hash_value = l.plan_hash_value
                      and other_xml is not null)) d
    minus
    select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
      from xmltable('/outline_data/hint' passing
                    (select xmltype(comp_data) as xmlval
                       from sys.sqlobj$data od, sys.sqlobj$ o
                      where o.obj_type = 2
                        and od.obj_type = 2
                        and o.name = l.plan_name
                        and o.signature = od.signature
                        and o.plan_id = od.plan_id
                        and comp_data is not null)) d))
select *
  from sql_bl_phv_list
union all
select distinct sql_id,
                0                 as PLAN_HASH_VALUE,
                'Baseln not used' as SQL_TYPE,
                ''                as SQL_EXEC_TIMESTAMP,
                sql_handle,
                plan_name,
                enabled,
                accepted,
                fixed,
                REPRODUCED,
                BL_LAST_EXECUTED
  from sql_bl_list
 where (select count(*) from sql_bl_phv_list) = 0
/*
with sql_list as (
select distinct sql_id, plan_hash_value
  from dba_sql_plan_baselines bl,
       gv$sql                 s
 where bl.sql_handle = '&&1' and bl.plan_name = nvl('&&2',bl.plan_name)
and DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(bl.sql_text) = DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(s.sql_fulltext)
   and not exists
   (select distinct substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
--    from xmltable('/* /outline_data/hint' passing
                  (select xmltype(other_xml) as xmlval
                     from gv$sql_plan
                    where inst_id         = s.inst_id
                      and sql_id          = s.sql_id
                      and plan_hash_value = s.plan_hash_value
                      and other_xml is not null)) d
    minus
    select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
      from xmltable('/outline_data/hint' passing
                    (select xmltype(comp_data) as xmlval
                       from sys.sqlobj$data od, sys.sqlobj$ o
                      where o.obj_type = 2
                        and od.obj_type = 2
                        and o.name = bl.plan_name
                        and o.signature = od.signature
                        and o.plan_id = od.plan_id
                        and comp_data is not null)) d)
union
select distinct sa.sql_id, plan_hash_value
  from dba_sql_plan_baselines bl,
       dba_hist_sqltext       sa,
       dba_hist_sql_plan      spa
 where bl.sql_handle = '&&1' and bl.plan_name = nvl('&&2',bl.plan_name)
and DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(bl.sql_text) = DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sa.sql_text)
   and sa.sql_id = spa.sql_id
   and not exists
   (select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
--            from xmltable('/* /outline_data/hint' passing
                          (select xmltype(other_xml) as xmlval
                             from DBA_HIST_SQL_PLAN
                            where sql_id = spa.sql_id
                              and plan_hash_value = spa.plan_hash_value
                              and other_xml is not null)) d
    minus
    select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
      from xmltable('/outline_data/hint' passing
                    (select xmltype(comp_data) as xmlval
                       from sys.sqlobj$data od, sys.sqlobj$ o
                      where o.obj_type = 2
                        and od.obj_type = 2
                        and o.name = bl.plan_name
                        and o.signature = od.signature
                        and o.plan_id = od.plan_id
                        and comp_data is not null)) d)
)
select l.SQL_ID,
       l.PLAN_HASH_VALUE,
       to_char(max(nvl(s.last_active_time, h.timestamp)), 'dd.mm.yyyy hh24:mi:ss') as SQL_EXEC_TIMESTAMP,
       nvl2(max(s.sql_id), 'CURRENT', 'ARCHIVE')                                   as SQL_TYPE,
       to_char(max(bl.last_executed), 'dd.mm.yyyy hh24:mi:ss')                     as BL_EXEC_TIMESTAMP,
       max(bl.REPRODUCED)                                                          as BL_REPRODUCED
  from sql_list l
  left join gv$sql s            on l.sql_id = s.sql_id and l.plan_hash_value = s.plan_hash_value
  left join dba_hist_sql_plan h on l.sql_id = h.sql_id and l.plan_hash_value = h.plan_hash_value
  join dba_sql_plan_baselines bl on bl.sql_handle = '&&1' and bl.plan_name = nvl('&&2',bl.plan_name)
 group by l.sql_id, l.plan_hash_value
 order by to_char(max(nvl(s.last_active_time, h.timestamp)), 'dd.mm.yyyy hh24:mi:ss') desc
*/
/
set feedback on echo off VERIFY ON serveroutput off