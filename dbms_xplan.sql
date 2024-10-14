--!!! Wrong results ???
SQL> explain plan for select * from sales s where time_id in ( :a, :b, :c, :d);
Explained.
--!!! Wrong results ???
SQL> select * from table(dbms_xplan.display('','','+alias +outline -predicate'));
--!!! Wrong results ???
SELECT lpad(' ',2*level)||operation||' '||options||' '||object_name "Query Plan" FROM plan_table where STATEMENT_ID = 'BITRIX' CONNECT BY PRIOR id = parent_id START WITH id = 1

alter session set events '10053 trace name context forever';

SELECT/*+ gather_plan_statistics*/ *
  FROM (SELECT ACC.*, C.CAN_AUTHOR
          FROM SK_ACCOUNT ACC, SK_COMPANY C
         WHERE C.ID = ACC.COMPANY_ID
           AND ('1' = '1' OR C.ID = '1447')
           AND UPPER(ACC.NAME || '' || ACC.LASTNAME) LIKE
               UPPER('%John%')
         order by acc.TIMESTAMP_X desc)
 WHERE ROWNUM <= '100'
  
alter session set events '10053 trace name context off';

select sql_text, sql_id, plan_hash_value, hash_value, child_number from gv$sql where sql_text like '%MYIN%'
select INST_ID, sql_id, plan_hash_value, hash_value, child_number,SQL_FULLTEXT from gv$sql where sql_id = 'ap1kvy9g20rrc'

select * from gv$sqlarea where sql_id = 'ap1kvy9g20rrc'
INST_ID  SQL_TEXT  SQL_FULLTEXT  SQL_ID  SHARABLE_MEM  PERSISTENT_MEM  RUNTIME_MEM  SORTS  VERSION_COUNT  LOADED_VERSIONS  OPEN_VERSIONS  USERS_OPENING  FETCHES  EXECUTIONS  PX_SERVERS_EXECUTIONS  END_OF_FETCH_COUNT  USERS_EXECUTING  LOADS  FIRST_LOAD_TIME  INVALIDATIONS  PARSE_CALLS  DISK_READS  DIRECT_WRITES  BUFFER_GETS  APPLICATION_WAIT_TIME  CONCURRENCY_WAIT_TIME  CLUSTER_WAIT_TIME  USER_IO_WAIT_TIME  PLSQL_EXEC_TIME  JAVA_EXEC_TIME  ROWS_PROCESSED  COMMAND_TYPE  OPTIMIZER_MODE  OPTIMIZER_COST  OPTIMIZER_ENV  OPTIMIZER_ENV_HASH_VALUE  PARSING_USER_ID  PARSING_SCHEMA_ID  PARSING_SCHEMA_NAME  KEPT_VERSIONS  ADDRESS  HASH_VALUE  OLD_HASH_VALUE  PLAN_HASH_VALUE  MODULE  MODULE_HASH  ACTION  ACTION_HASH  SERIALIZABLE_ABORTS  OUTLINE_CATEGORY  CPU_TIME  ELAPSED_TIME  OUTLINE_SID  LAST_ACTIVE_CHILD_ADDRESS  REMOTE  OBJECT_STATUS  LITERAL_HASH_VALUE  LAST_LOAD_TIME  IS_OBSOLETE  CHILD_LATCH  SQL_PROFILE  PROGRAM_ID  PROGRAM_LINE#  EXACT_MATCHING_SIGNATURE  FORCE_MATCHING_SIGNATURE  LAST_ACTIVE_TIME  BIND_DATA  TYPECHECK_MEM
2  with s_dt as (             select to_date(lpad(12, 2, '0')||'.'||2010, 'MM.YYYY') as dt               from dual         )         select mn.group_code,                mm.manager_code,                m.status,                mm.month,                mm.kpi_pct/100   as kpi_pct,                my.bonus         as kpi_bonus,                (                 -- нужен индекс                 -- create index t_paid_acts$dt on t_paid_acts(dt);                   select /*+ ordered*/ sum(round(pa.amount * i.currency_rate/ (1 + i.nds * i.nds_pct / 100),2))                     from bo.t_paid_acts     pa                     join bo.t_act_trans     ta  on ta.id = pa.act_trans_id                     join bo.t_act           a   on a.id = ta.act_id                     join bo.t_invoice       i   on i.id = a.invoice_id                    where pa.dt between (select dt from s_dt) and add_months((select dt from s_dt), 1) - 1/86400                      and ta.manager_code = mm.manager_code      	<CLOB>	ap1kvy9g20rrc	140250	41328	34720	1	1	1	1	0	1	1	0	0	1	1	2011-01-19/12:29:18	0	1	18586	1	5543806	0	2814	84498288	66465028	291	0	100	3	ALL_ROWS	38	E289FB89A4E49800CE001000AEFAC3E2CFFA3310564145555195A1105555551545545558591555449665851D5511058555155511152552455580588055A1454A8E0950002120000020000000000100001000000001002080007D000000000C0300FF9B0010100000C0C30F40000080FF4D0000008601404A8E09504646A6202040262320030020003020A000A5A000	3546195780	0	0	SYS	0	00000003C29411F0	1579179756	2340863979	1220288551	PL/SQL Developer	1190136663	SQL Window - BALANCEADMIN-23.sql	350789200	0		92139075	233532269		000000036E25C3E0	N	VALID	0	19.01.2011 12:29:18	N	10		0	0	1,22383934647688E19	1,22383934647688E19	19.01.2011 12:33:17		0
select INSTANCE_NUMBER from v$instance
INSTANCE_NUMBER
1

SELECT lpad(' ', 2 * level) || pt.operation || ' ' || pt.options || ' ' ||pt.object_name "Query Plan"
, pt.cost, pt.cardinality, pt.bytes, pt.cpu_cost, pt.io_cost, pt.temp_space, pt.access_predicates, pt.filter_predicates, pt.qblock_name
  FROM (select * from gv$sql_plan
                where --plan_hash_value = 3597661060
--                and hash_value = 1979532573
                sql_id = '07y7muprznt7v'
                and child_number = 1
                and inst_id = 1
                ) pt
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0

SELECT id as OPERATION_ID,
lpad(' ', 2 * level) || pt.operation || ' ' || pt.options "Query Plan", pt.object_owner, pt.object_name, pt.qblock_name
, pt.cost, pt.cardinality, pt.bytes, pt.cpu_cost, pt.io_cost, pt.temp_space, pt.access_predicates, pt.filter_predicates
, pt.other_xml, pt.temp_space
  FROM (
        select * from gv$sql_plan
                where --plan_hash_value = 3237382297 and
                sql_id = 'g2d3t7r371r54'
--                and child_number = 2
                and inst_id = 1
                and CHILD_ADDRESS = HEXTORAW('00000001D9610A10')
                ) pt
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0

select * from v$sql where --CHILD_ADDRESS = HEXTORAW('00000001D9610A10') and 
sql_id = 'g2d3t7r371r54'
and hash_value = 3329285284
 
select * from V$SQL_PLAN_MONITOR where sql_id = '46mu3jc0ccajy' and status = 'EXECUTING'

SELECT lpad(' ', 2 * level) || pt.plan_operation || ' ' || pt.plan_options || ' ' ||
       pt.plan_object_name "Query Plan",
       pt.plan_cost,
       pt.plan_cardinality,
       pt.plan_bytes,
       pt.plan_cpu_cost,
       pt.plan_io_cost,
       pt.plan_temp_space,
       pt.starts,
       pt.output_rows,
       pt.workarea_mem,
       pt.workarea_tempseg,
       pt.physical_read_requests,
       pt.physical_write_requests
  FROM (select *
          from v$sql_plan_monitor pt
         where sql_id = '&sql_id'
--                and sql_plan_hash_value = &sql_plan_hash_value
--                and sid = &sid
--                and sql_exec_id = &sql_exec_id
           and status = 'EXECUTING') pt
CONNECT BY PRIOR pt.plan_line_id = pt.plan_parent_id
 START WITH pt.plan_line_id = 0

select * from gv$sql_plan_monitor where sql_id = 'agz6x0ccrk37j'

--4PX
SELECT pt.plan_line_id,
       lpad(' ', 1 * level) || pt.plan_operation || ' ' || pt.plan_options as plan_operation,
       pt.plan_object_name object_name,
       pt.plan_cost,
       pt.plan_cardinality,
       pt.plan_bytes,
       pt.plan_cpu_cost,
       pt.plan_io_cost,
       pt.plan_temp_space,
       pt.starts,
       pt.output_rows,
       pt.workarea_mem,
       pt.workarea_tempseg,
       pt.physical_read_requests,
       pt.physical_write_requests
  FROM 
--select * from
(select --*
       pt.plan_line_id,
       max(pt.plan_parent_id) as plan_parent_id,
       pt.plan_operation,
       pt.plan_options,
       max(pt.plan_object_name) as plan_object_name,
       max(pt.plan_cost) as plan_cost,
       max(pt.plan_cardinality) as plan_cardinality,
       max(pt.plan_bytes) as plan_bytes,
       max(pt.plan_cpu_cost) as plan_cpu_cost,
       max(pt.plan_io_cost) as plan_io_cost,
       max(pt.plan_temp_space) as plan_temp_space,
       sum(pt.starts) as starts,
       sum(pt.output_rows) as output_rows,
       sum(pt.workarea_mem) as workarea_mem,
       sum(pt.workarea_tempseg) as workarea_tempseg,
       sum(pt.physical_read_requests) as physical_read_requests,
       sum(pt.physical_write_requests) as physical_write_requests
          from v$sql_plan_monitor pt
         where sql_id = '&sql_id'
--                and sql_plan_hash_value = &sql_plan_hash_value
--                and sid = &sid
--                and sql_exec_id = &sql_exec_id
           and status = 'EXECUTING'
group by pt.plan_line_id,
         pt.plan_operation,
         pt.plan_options
--, pt.plan_parent_id
--         , pt.plan_object_name
order by 1) pt
CONNECT BY PRIOR pt.plan_line_id = pt.plan_parent_id
 START WITH pt.plan_line_id = 0

SELECT * FROM TABLE(dbms_xplan.display_cursor( 'agz6x0ccrk37j',0,format => 'all allstats advanced -qbregistry last'));--123954910
SELECT * FROM TABLE(dbms_xplan.display_cursor( 'f6kwf4q4quac8',0,format => 'all allstats advanced -qbregistry last'));
SELECT * FROM TABLE(dbms_xplan.display_cursor( '7f9t3rqnkp3r9',1,format => 'all allstats advanced -qbregistry last'));

select * from v$instance

--dba_hist_sql_plan
SELECT lpad(' ', 2 * level) || pt.operation || ' ' || pt.options, pt.object_owner, pt.object_name
, pt.cost, pt.cardinality, pt.bytes, pt.cpu_cost, pt.io_cost, pt.temp_space, pt.access_predicates, pt.filter_predicates, pt.qblock_name
, pt.other_xml
  FROM (select * from dba_hist_sql_plan
                where
                sql_id = 'bkx799gtk6r0h'
                and plan_hash_value = 1595733709
                ) pt
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0

SELECT * FROM TABLE(dbms_xplan.display_awr('aq07w6jd7yv7b','1482337619', 693408832,'all allstats advanced last'))

select * from table(dbms_xplan.display('','','all allstats advanced last'));
select * from v$sql_plan

alter session set "_connect_by_use_union_all" = false--Bug 9906422 - ORA-600 [qctVCO:csform] from query using WITH, CONNECT BY and CLOBs [ID 9906422.8]

--Plan for multi-child-records

SELECT /*+ opt_param('_connect_by_use_union_all' 'false') */ id as OPERATION_ID,
lpad(' ', 2 * level) || pt.operation || ' ' || pt.options "Query Plan", pt.object_owner, pt.object_name
/*, pt.qblock_name
, pt.cost, pt.cardinality, pt.bytes, pt.cpu_cost, pt.io_cost, pt.temp_space, pt.access_predicates, pt.filter_predicates
, pt.other_xml, pt.temp_space*/
  FROM 
       (select p.* from gv$sql_plan p, gv$sql s
                where p.sql_id = 'fn68sykdm9vx2'
                  and p.plan_hash_value = 473736415
                  and p.child_number = 0
                  and p.inst_id = 1
                  and p.inst_id = s.inst_id
                  and p.sql_id = s.sql_id
                  and p.child_number = s.child_number
                  and p.address = s.address
                  and s.is_obsolete <> 'Y' -- for multi-records-by-child-in-v$sql case
       ) pt
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0


select * from dba_hist_sql_plan
                where plan_hash_value = 242467142


select * from table(dbms_xplan.display_sql_plan_baseline(sql_handle=>'SQL_ba0364542c9e3baf',plan_name=>'SQL_PLAN_bn0v4ahq9wfxg2e06cd3a', format=>'ADVANCED'));

/*+ gather_plan_statistics*/
SELECT * FROM TABLE(dbms_xplan.display_cursor( '21a0wc7axkh1k','0','all allstats advanced last'))

SELECT * FROM TABLE(dbms_xplan.display_cursor( '4bh1kmzwgkh0g'))

SELECT * FROM TABLE(dbms_xplan.display_cursor( '3jvhsp0zha0jf'))

SELECT * FROM TABLE(dbms_xplan.display_cursor( 'ca7zs0s25xnc4','9'))

SELECT * FROM TABLE(dbms_xplan.display_cursor('','','all allstats advanced -alias -outline +note +parallel +remote -projection +peeked_binds +predicate last'));
SELECT * FROM TABLE(dbms_xplan.display_cursor('8bqf8qfgpcq9t','0','all allstats advanced -alias -outline +note +parallel +remote -projection +peeked_binds +predicate last'));



SELECT * FROM TABLE(dbms_xplan.display_awr('5cd798u1gc15n',format => 'all allstats advanced last'))


SELECT * FROM TABLE(dbms_xplan.display_awr('8t56m5ynrj5gb',759403728,format => 'all allstats advanced last'))--+++
                                                           759403728
SELECT * FROM TABLE(dbms_xplan.display_awr('4p946fhyarxhp', 451742568,format => 'all allstats advanced last'))
SELECT * FROM TABLE(dbms_xplan.display_awr('5rv3114yt6ytr',1512399953,format => 'all allstats advanced last'))

SELECT * FROM TABLE(dbms_xplan.display_awr('21a0wc7axkh1k',3508191194,format => 'all allstats advanced last'))
SELECT * FROM TABLE(dbms_xplan.display_awr('5bwj7gjn9n0s9',2117373955,format => 'all allstats advanced last'))
SELECT * FROM TABLE(dbms_xplan.display_cursor( '0zw2p8qg6ghca'))

select * from dba_indexes where table_name = 'XXOKE_DOP_LOCK'

select * from dba_segments where segment_name in ('DOP_LOCK_REF_UQ','XXOKE_DOP_LOCK')

SELECT * FROM TABLE(dbms_xplan.display_awr('2r5tx6faqu2yh',format => 'all allstats advanced last'))


select * from v$sql where sql_id = 'azud4wasaryf1'

select * from v$sql where sql_text like 'select/*+ RESULT_CACHE*/ distinct e.entity_id, ea.attr_as_str%'

select * from v$sql_plan_statistics_all where sql_id = 'b7mvfgbpybcry'--'bjcxu2x15a0vy'

select * from v$instance

alter session set "_cursor_plan_unparse_enabled"=false

select * from v$sql_plan_statistics_all where PLAN_HASH_VALUE=3661571671
order by child_number, id


select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'9zn9gxqny74dd', report_level=>'all', type=>'text') SQL_Report from dual;
SELECT * FROM TABLE(dbms_xplan.display_cursor( 'c64z5pv6vvpcb',0,format => 'all allstats advanced last'));

select * from v$sql_monitor where sql_id = '09uf004tg06vk'

select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'f1zthk97w0qbx', report_level=>'all', type=>'html') SQL_Report from dual;
2sata46nws1gz
select * from v$sql_monitor where sql_id = 'f1zthk97w0qbx'

select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'b0m5ftjxcxjt7', report_level=>'BASIC +PLAN +BINDS', type=>'html') SQL_Report from dual;-- 11.2+
select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'c5f4n96jvg0xy', report_level=>'all +binds', type=>'text') SQL_Report from dual;

select b.sql_text, a.bind_vars, c.datatype, c.value
from v$sql_cursor a, v$sql b, v$sql_bind_data c
where b.address = a.parent_handle
  and a.curno = c.cursor_num
  and b.sql_id= 'b0m5ftjxcxjt7'
  and b.child_number = 0

select * from v$open_cursor where sql_id = 'd1t8cyzf83tv6'


-------------------OUTLINE_HINTS DBA_HIST_SQL_PLAN
select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from DBA_HIST_SQL_PLAN
                  where sql_id = 'aq07w6jd7yv7b'
                    and plan_hash_value = 1482337619
                  --and plan_hash_value = &plan_hash_value
                    and other_xml is not null)) d;
                    
-------------------OUTLINE_HINTS
select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
  from xmltable('/*/outline_data/hint' passing
                (select xmltype(other_xml) as xmlval
                   from v$sql_plan
                  where sql_id = '&sql_id'
                    and child_number = &child_number
                  --and plan_hash_value = &plan_hash_value
                    and other_xml is not null)) d;

-------------------BASELINE_HINTS
select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
  from xmltable('/outline_data/hint' passing
                (select xmltype(comp_data) as xmlval
                   from sys.sqlobj$data od, sys.sqlobj$ o
                  where o.obj_type = 2
                    and od.obj_type = 2
                    and o.name = 'SQL_PLAN_cx7t606tv57km47640326'
                    and o.signature = od.signature
                    and o.plan_id = od.plan_id
                    and comp_data is not null)) d
/

-------------------SQLPATCH_HINTS
select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
  from xmltable('/outline_data/hint' passing
                (select xmltype(comp_data) as xmlval
                   from sys.sqlobj$data od, sys.sqlobj$ o
                  where od.obj_type = 3
                    and (o.name = 'SQL_PLAN_c8a0ztuknsw949b8d4f09' and o.obj_type = 2)
--                    and (o.name = 'NO_CF' and o.obj_type = 3)
                    and o.signature = od.signature
                    and comp_data is not null)) d
/

--from 10053 trace
SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
 extractvalue(xmlval, '/*/info[@type = "sql_profile"]'),
 extractvalue(xmlval, '/*/info[@type = "sql_patch"]'),
 extractvalue(xmlval, '/*/info[@type = "baseline"]'),
 extractvalue(xmlval, '/*/info[@type = "outline"]'),
 extractvalue(xmlval, '/*/info[@type = "dynamic_sampling"]'),
 extractvalue(xmlval, '/*/info[@type = "dop"]'),
 extractvalue(xmlval, '/*/info[@type = "row_shipping"]'),
 extractvalue(xmlval, '/*/info[@type = "index_size"]'),
 extractvalue(xmlval, '/*/info[@type = "result_checksum"]'),
 extractvalue(xmlval, '/*/info[@type = "cardinality_feedback"]'),
 extractvalue(xmlval, '/*/info[@type = "plan_hash"]')
  from (select xmltype(:v_other_xml) xmlval from dual)

--OTHER_XML from V$SQL_PLAN
col plan_hash for a15
col profile for a30
col patch for a30
col baseline for a30
col outline for a30
col dyn_sampling for a15
col dop for a3
col row_shipping for a15
col index_size for a15
col result_checksum for a15
col CF for a3
SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
 sql_id,
 inst_id,
 child_number                                                    as CHILD,
 plan_hash_value,
 extractvalue(xmlval, '/*/info[@type = "plan_hash"]')            as plan_hash,
 extractvalue(xmlval, '/*/info[@type = "sql_profile"]')          as profile,
 extractvalue(xmlval, '/*/info[@type = "sql_patch"]')            as patch,
 extractvalue(xmlval, '/*/info[@type = "baseline"]')             as baseline,
 extractvalue(xmlval, '/*/info[@type = "outline"]')              as outline,
 extractvalue(xmlval, '/*/info[@type = "dynamic_sampling"]')     as dyn_sampling,
 extractvalue(xmlval, '/*/info[@type = "dop"]')                  as dop,
 extractvalue(xmlval, '/*/info[@type = "row_shipping"]')         as row_shipping,
 extractvalue(xmlval, '/*/info[@type = "index_size"]')           as index_size,
 extractvalue(xmlval, '/*/info[@type = "result_checksum"]')      as result_checksum,
 extractvalue(xmlval, '/*/info[@type = "cardinality_feedback"]') as CF
  from (select xmltype(other_xml) xmlval, child_number, inst_id, sql_id, plan_hash_value
          from gv$sql_plan
         where sql_id = '&v1'
           and other_xml is not null)
--------------------v$sql_plan_statistics_all
SELECT lpad(' ', 2 * level) || pt.operation || ' ' || pt.options "Query Plan", pt.object_owner, pt.object_name 
, pt.cost
, pt.starts
, pt.cardinality
, pt.output_rows
, pt.bytes
, pt.cr_buffer_gets
, pt.disk_reads
, pt.time
, pt.elapsed_time
--, pt.cpu_cost, pt.io_cost, pt.temp_space
--, pt.access_predicates, pt.filter_predicates
--, pt.other_xml, pt.temp_space
  FROM (select * from v$sql_plan_statistics_all
                where sql_id = 'b7mvfgbpybcry'
                and child_number = 0
                ) pt
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 1

----v$sql_plan + v$sql_plan_monitor

select min(key)
  from v$sql_plan_monitor
 where sql_id = '5aq3prc35nm2r'
   and sql_exec_start = (select max(sql_exec_start)
                           from v$sql_plan_monitor
                          where sql_id = '5aq3prc35nm2r')

SELECT id as OPERATION_ID,
lpad(' ', 2 * level) || pt.operation || ' ' || pt.options "Query Plan", pt.object_owner, pt.object_name 
, pt.cost, pt.cardinality, pt.bytes, pt.cpu_cost, pt.io_cost, pt.temp_space, pt.access_predicates, pt.filter_predicates
, pt.other_xml, pt.temp_space
, starts
, output_rows
, workarea_mem
, workarea_max_mem
, workarea_tempseg
, workarea_max_tempseg
  FROM (
       select p.*,
       m.starts,
       m.output_rows,
       m.workarea_mem,
       m.workarea_max_mem,
       m.workarea_tempseg,
       m.workarea_max_tempseg
       from v$sql_plan p, v$sql_plan_monitor m
                where p.sql_id = '5aq3prc35nm2r'
                and p.plan_hash_value = 3461608119
                and m.key = 25769817260
                and p.sql_id = m.sql_id
                and p.plan_hash_value = m.sql_plan_hash_value
                and p.id = m.plan_line_id
                ) pt
CONNECT BY PRIOR pt.id = pt.parent_id
 START WITH pt.id = 0

create user scott identified by tiger;
grant create session, dba to scott;
create table t1 tablespace users
as
select * from all_objects
where rownum < 10001
/
create index t1_object_type on t1(object_type) tablespace users;


select * from v$instance

http://www.juliandyke.com/Optimisation/Operations/SortUniqueNoSort.html

SELECT * FROM TABLE(dbms_xplan.display_awr('9s7ppf88qzx2w', plan_hash_value => '2589330326',format => 'all allstats advanced last'))
select * from v$instance


select min(sample_time) from v$active_session_history where sql_id = '4p946fhyarxhp'

select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'a6b03616hfvh4', report_level=>'all', type=>'html') SQL_Report from dual;

SELECT * FROM TABLE(dbms_xplan.display_cursor('a6b03616hfvh4',2,format => 'all allstats advanced last'))--2795130570
SELECT * FROM TABLE(dbms_xplan.display_cursor('bu0t5rb32s791',3,format => 'all allstats advanced last'))--3835647942 + index full scan

287	| 262 |                    NESTED LOOPS                             |                                |  15371 |      1 |    22 |     2   (0)| 00:00:01 |       |       |  15371 |00:11:29.84 |     879K|       |       |          |
288	|*263 |                     INDEX FULL SCAN                         | HR_ORGANIZATION_UNITS_PK       |  15371 |      1 |     4 |     1   (0)| 00:00:01 |       |       |  15371 |00:11:29.73 |     864K|       |       |          |



SELECT * FROM TABLE(dbms_xplan.display_cursor('4xu0dm5t4w6k4',0,format => 'all allstats advanced last'))
SELECT * FROM TABLE(dbms_xplan.display_awr('327mp3fnsukq1',289502100,format => 'all allstats advanced last'))
SELECT * FROM TABLE(dbms_xplan.display_awr('327mp3fnsukq1',4139511155,format => 'all allstats advanced last'))


select * from v$sql where sql_id = '327mp3fnsukq1'

select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'345awufgp6qhz',sql_exec_id => 16777217, report_level=>'all', type=>'text') SQL_Report from dual;


select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'5j9vf6vtb16kh', sql_exec_id => 17446977, report_level=>'all', type=>'text') SQL_Report from dual;


select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'0kxvuz89s4zgj', report_level=>'all', type=>'html') SQL_Report from dual;

select * from dba_segments where --TABLESPACE_name = 'YACC_PERSONTS' and
 segment_type = 'TEMPORARY'


select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'52trm39w571rd', report_level=>'all', type=>'html') SQL_Report from dual;

select * from gv$active_session_history where sql_id = 'c3bcrguh757dw' order by sample_time desc

select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'f8d7nsw3baj5h', report_level=>'all', type=>'html') SQL_Report from dual;
SELECT * FROM TABLE(dbms_xplan.display_cursor('gdp7531krb0ya',0,format => 'all allstats advanced +adaptive last'))


select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'9sr3y570p9rh7', report_level=>'all', type=>'html') SQL_Report from dual;
SELECT * FROM TABLE(dbms_xplan.display_cursor('gubc93zqbrz9h',8,format => 'all allstats advanced +adaptive last'))
SELECT * FROM TABLE(dbms_xplan.display_cursor('66qbr9hu67vcj',0,format => 'all allstats advanced +adaptive last'))

SELECT * FROM TABLE(dbms_xplan.display_awr('66qbr9hu67vcj',format => 'all allstats advanced +adaptive last'))

select * from gv$sqlarea where sql_id = 'gubc93zqbrz9h'

07n6jwz7rgjwk 795211316

SELECT * FROM TABLE(dbms_xplan.display_awr('1vk063c6q2nwt',3231461275,format => 'all allstats advanced +adaptive last'))
SELECT * FROM TABLE(dbms_xplan.display_awr('fzt9shqa6ftrd',3676399490,format => 'all allstats advanced +adaptive last'))

@sql_plan_diff 6wy5gf6t3a8ng 811920337 6wy5gf6t3a8ng 2726197683

select * from gv$sql where sql_id = 'cgwcz3ba7gjt5'

select LAST_ACTIVE_TIME from gv$sql where sql_id='57m3n8v2511bx';

alter session set "_parallel_syspls_obey_force" = FALSE;
select dbms_sqltune.report_sql_monitor('6296wwc2nfydu', type => 'ACTIVE') from dual;
select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'7425z7wsuuf22', report_level=>'all', type=>'text') SQL_Report from dual
select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'b4utv9ujd6ymw', report_level=>'all', type=>'text') SQL_Report from dual
select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'acsbd6fuwyvaj', report_level=>'all', type=>'text') SQL_Report from dual
select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'b5tq6435p6j2h', sql_exec_id => 33571733, report_level=>'all', type=>'text') SQL_Report from dual

select * from dba_segments where segment_name = 'XXYA_ALL_SLA_STORE_TBL'
--sum(bytes)
582646366208
select * from dba_tables where table_name = 'XXYA_ALL_SLA_STORE_TBL'
1942179081

select * from XXYA.XXYA_ALL_SLA_STORE_TBL DATA_GROUP=39--PARTITION (DATA_GROUP_39)
select * from dba_part_key_columns where name = 'XXYA_ALL_SLA_STORE_TBL'

select 40000*582646366208/1942179081 from dual

select * from gv$sql_plan_monitor where sql_id ='5c9a2kxp12v6x' order by refresh_count desc

select * from dba_hist_reports where COMPONENT_NAME = 'sqlmonitor' and key1 = '13v06gxdvabhd' order by generation_time desc
SELECT dbms_auto_report.Report_repository_detail(rid=>6430928, TYPE=>'text') FROM dual;

select 
    instance_number,
    snap_id,
    sn.begin_interval_time,
    round(st.executions_delta) as execs,
    st.sql_id,
    st.plan_hash_value as plan,
    st.SQL_PROFILE,
    st.optimizer_cost as cost,
    round(st.parse_calls_delta/decode(st.executions_delta,0,1,st.executions_delta),3) as parse_per_exec,
--    st.elapsed_time_delta,
    TO_CHAR(round(st.elapsed_time_delta/decode(st.executions_delta,0,1,st.executions_delta)),'999,999,999,999') as ela_per_exec,
    round(st.cpu_time_delta/decode(st.executions_delta,0,1,st.executions_delta)) as cpu_per_exec,
    round(st.buffer_gets_delta/decode(st.executions_delta,0,1,st.executions_delta)) as gets_per_exec,
    round(st.physical_read_bytes_delta/decode(st.executions_delta,0,1,st.executions_delta)/1024/1024) as read_mb_per_exec,
    round(st.physical_read_requests_delta/decode(st.executions_delta,0,1,st.executions_delta)) as reads_per_exec,
    round(st.physical_write_bytes_delta/decode(st.executions_delta,0,1,st.executions_delta)/1024/1024) as writes_mb_per_exec,
    round(st.physical_write_requests_delta/decode(st.executions_delta,0,1,st.executions_delta)) as writes_per_exec,
    round(st.direct_writes_delta/decode(st.executions_delta,0,1,st.executions_delta)) as direct_writes_per_exec,
    round(st.disk_reads_delta/decode(st.executions_delta,0,1,st.executions_delta)) as disk_reads_per_exec,
    round(st.rows_processed_delta/decode(st.executions_delta,0,1,st.executions_delta)) as rows_per_exec,
    st.rows_processed_delta,
    round(st.fetches_delta/decode(st.executions_delta,0,1,st.executions_delta)) as fetches_per_exec,
    round(st.iowait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as iowaits_per_exec,
    round(st.clwait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as clwaits_per_exec,
    round(st.apwait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as apwaits_per_exec,
    round(st.ccwait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as ccwaits_per_exec,
    round(st.plsexec_time_delta/decode(st.executions_delta,0,1,st.executions_delta)) as PLSQL_PER_EXEC,
    round(st.px_servers_execs_delta/decode(st.executions_delta,0,1,st.executions_delta)) as px_per_exec,
    round(st.SORTS_DELTA/decode(st.executions_delta,0,1,st.executions_delta)) as SORTS_per_exec
,PARSING_SCHEMA_NAME,VERSION_COUNT
from dba_hist_sqlstat st join dba_hist_snapshot sn using (snap_id, instance_number)
--where sql_id in (select sql_id from dba_hist_sqltext where upper(sql_text) like '%OPT_PARAM(''_FIX_CONTROL''%')--
where sql_id in ('&3rb269wd116ar')--('f3dusgwud6zak')--('1prg9yty81yc0')--
--(select sql_id from dba_hist_sqltext where sql_text like 'SELECT t_export.classname AS t_export_classname, t_export.object_id AS t_export_object_id, t_export.type AS t_export_type, t_export.update_dt AS t_export_update_dt, t_export.rate AS t_export_rate, t_export.next_export AS t_export_next_export, t_export.state AS t_export_state, t_export.error AS t_export_error, t_export.export_dt AS t_export_export_dt, t_export.hostname AS t_export_hostname, t_export.priority AS t_export_priority, t_export.input AS t_export_input, t_export.traceback AS t_export_traceback, t_export.output AS t_export_output, t_export.reason AS t_export_reason, t_export.config AS t_export_config %FROM t_export %WHERE (t_export.classname, t_export.object_id, t_export.type) IN ((%')--('fbh11z8p6zd8y')--
--insert /*+ append parallel(8) DYNAMIC_SAMPLING(0) OPT_PARAM('_fix_control' '7452863:0') */ into bo.t_comm_prof_src select s.*, to_date('11.04.2016 12:03:41', 'DD.MM.YYYY HH24:MI:SS') as insert_dt  from bo.v_comm_prof_src s
--      and st.snap_id = sn.snap_id
--      and st.instance_number = sn.instance_number
--      and st.executions_delta > 10
and (st.elapsed_time_delta > 0 and st.executions_delta is not null)
      and st.plan_hash_value = nvl('&3760070478',st.plan_hash_value)
--and (snap_id between 401306 and 401313 or snap_id between 401447 and 401454)
--and instance_number = 1
--and sn.begin_interval_time > trunc(sysdate) - 11
order by sn.begin_interval_time desc, instance_number

SELECT * FROM TABLE(dbms_xplan.display_awr( '44gwnw4mk9nr4',3760070478 ,format => 'all allstats advanced last'))
|   1 |  TEMP TABLE TRANSFORMATION                                   |                                |        |       |            |          |       |       |
|   2 |   LOAD AS SELECT                                             |                                |        |       |            |          |       |       |
|1257 |          TABLE ACCESS BY INDEX ROWID                         | PA_PROJECT_ASSET_LINES_ALL     |      1 |     8 |     3   (0)| 00:00:01 |       |       |
----------------------------------------------------------------------------------------------------------------------------------------------------------------
Peeked Binds

SELECT * FROM TABLE(dbms_xplan.display_awr( '3rb269wd116ar',4072864899,format => 'all allstats advanced last'))
-->LOAD AS SELECT
TEMP TABLE TRANSFORMATION
| 537 |        INDEX UNIQUE SCAN                                   | PA_EXPENDITURE_ITEMS_U1        |      1 |       |       |     2   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------------------------------------------------------------
Peeked Binds

select * from gv$sqlarea where sql_id = '3rb269wd116ar'

SELECT * FROM TABLE(dbms_xplan.display_cursor( '8yfyhrq76gf17',format => 'all hint_report +alias +predicate -projection last'));
@sql_plan_diff_notes c8jdwqhdhuuz7 3898771739 c8jdwqhdhuuz7 3107666625

select * from gv$active_session_history where sql_id in ('32700fyy0jh2k')

select * from gv$sqlarea where sql_text like 'INSERT INTO t_export (classname, object_id, type, rate, state, error, export_dt, hostname, priority, input, traceback, output, reason, config) VALUES (:classname, :object_id, :type, :rate, :state, :error, :export_dt, :hostname, :priority, :input, :traceback, :output, :reason, :config)%'

select * from dba_segments where segment_name in ('TON','AQ$_TON_I')

select * from gv$active_session_history where sql_id = '4yc50ydwpxhvg'
muzzle.get_effective_client_info#

select * from v$instance

SELECT * FROM TABLE(dbms_xplan.display_cursor('9rgwbhkz2dyya',format => 'all allstats advanced +adaptive last'))
select DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id =>'g0r7ba19sy81q', report_level=>'all', type=>'html') SQL_Report from dual


DECLARE
  my_sql_id    VARCHAR2(30) := '&sql_id';
  my_task_name VARCHAR2(30);
BEGIN
  begin
     DBMS_SQLTUNE.DROP_TUNING_TASK(my_sql_id);
     exception when others then NULL;
  end;
  my_task_name := DBMS_SQLTUNE.CREATE_TUNING_TASK(
          sql_id      => my_sql_id,
        --sql_text    => 'select ...', --if SQL not in shared pool--
          scope       => 'COMPREHENSIVE',
          time_limit  => 600,
          task_name   => my_sql_id,
          description => 'SQL analysis for SQL_ID=' || my_sql_id);
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK(task_name => my_task_name);
END;
 
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK( '&sql_id' ) FROM DUAL;

--11.1
select
    round(st.executions) as execs,
    st.sql_id,
    st.plan_hash_value as plan,
    round(st.elapsed_time/decode(st.executions,0,1,st.executions)) as ela_per_exec,
    round(st.cpu_time/decode(st.executions,0,1,st.executions)) as cpu_per_exec,
--    round(st.physical_read_bytes/decode(st.executions,0,1,st.executions)/1024/1024) as read_mb_per_exec,
--    round(st.physical_read_requests/decode(st.executions,0,1,st.executions)) as reads_per_exec,
    round(st.disk_reads/decode(st.executions,0,1,st.executions)/1024/1024) as disk_reads_per_exec,
--    round(st.physical_write_bytes/decode(st.executions,0,1,st.executions)/1024/1024) as writes_mb_per_exec,
--    round(st.physical_write_requests/decode(st.executions,0,1,st.executions)) as writes_per_exec,
    round(st.direct_writes/decode(st.executions,0,1,st.executions)) as direct_writes_per_exec,
    round(st.rows_processed/decode(st.executions,0,1,st.executions)) as rows_per_exec,
    round(st.fetches/decode(st.executions,0,1,st.executions)) as fetch_per_exec,
    round(st.px_servers_executions/decode(st.executions,0,1,st.executions)) as px_per_exec,
    round(st.user_io_wait_time/decode(st.executions,0,1,st.executions)) as iowaits_per_exec
--select *
from gv$sqlstats st
where sql_id in ('9bcupsqystqws')
      and st.executions > 0

select
      instance_number,
      snap_id,
      to_char(sn.begin_interval_time, 'dd.mm.yyyy hh24:mi')||' - '||to_char(sn.end_interval_time, 'dd.mm.yyyy hh24:mi') as "INTERVAL",
      sql_id,
      round(st.executions_delta) as EXECS_DELTA,
      st.plan_hash_value,
      st.optimizer_cost,
      st.sql_profile,
      st.optimizer_mode,
      st.loaded_versions,
      st.version_count,
      round(st.elapsed_time_delta/decode(st.executions_delta,0,1,st.executions_delta)) as ELA_PER_EXEC,
      round(st.cpu_time_delta/decode(st.executions_delta,0,1,st.executions_delta)) as CPU_PER_EXEC,
      round(st.buffer_gets_delta/decode(st.executions_delta,0,1,st.executions_delta)) as GETS_PER_EXEC,
      round(st.rows_processed_delta/decode(st.executions_delta,0,1,st.executions_delta)) as ROWS_PER_EXEC,
      round(st.iowait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as IOW_PER_EXEC,
      round(st.disk_reads_delta/decode(st.executions_delta,0,1,st.executions_delta)) as READS_PER_EXEC,
      round(st.direct_writes_delta/decode(st.executions_delta,0,1,st.executions_delta)) as DIR_WRITES_PER_EXEC,
      round(st.ccwait_delta/decode(st.executions_delta,0,1,st.executions_delta)) as CC_PER_EXEC,
      round(st.fetches_delta/decode(st.executions_delta,0,1,st.executions_delta)) as FTCH_PER_EXEC,
      round(st.rows_processed_delta/decode(st.fetches_delta,0,1,st.fetches_delta)) as ROWS_PER_FTCH,
      round(st.px_servers_execs_delta/decode(st.executions_delta,0,1,st.executions_delta)) as PX_PER_EXEC
from dba_hist_sqlstat st join dba_hist_snapshot sn using (instance_number, snap_id)
where sql_id in ('bz23nucn5jd7n')
--  and snap_id in (14451,14524)
--and st.executions_delta > 0
order by snap_id desc, instance_number

select * from dba_hist_sqlstat
--11.1
