--
-- SQL Plans from Shared Pool or AWR comparision, incl. Query Block[s] diff (Oracle 11g-12c with Adaptive Plans)
-- Usage: SQL> @sql_plan_diff 6r6sanrs05550 3541904711        6r6sanrs05550 2970372553        "SEL$6444526D','SET$1"
--                            ^SQL_ID1      ^PLAN_HASH_VALUE1 ^SQL_ID2      ^PLAN_HASH_VALUE2  ^QBLOCK_LIST "[QB1[','QB2...]]"
-- when QBLOCK_LIST parameter is null then script outputs the whole plans comparision
-- by Igor Usoltsev
--

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

col OPERATION       for a100
col ID              for 9999
col OWNER           for a30
col OBJECT          for a40
col QBLOCK_NAME     for a20
col PLAN_HASH_VALUE for 999999999999999
col CARDINALITY     for 99999999999999999999
col BYTES           for 99999999999999999999
col "COST(IO)"      for 99999999999999999999
col TEMP            for 999999999999
col TIME            for 9999999999
col OBJECT_ALIAS    for a30

pro
pro -------------------------------
pro SQL Plans [by Query block] diff
pro -------------------------------

WITH display_map1 AS
 (SELECT X.*
  FROM dba_hist_sql_plan,
       XMLTABLE ( '/other_xml/display_map/row' passing XMLTYPE(other_xml ) COLUMNS 
                        op  NUMBER PATH '@op',    -- operation
                        dis NUMBER PATH '@dis',   -- display
                        par NUMBER PATH '@par',   -- parent
                        prt NUMBER PATH '@prt',   -- ?
                        dep NUMBER PATH '@dep',   -- depth
                        skp NUMBER PATH '@skp' )  -- skip
                    AS X
  WHERE sql_id        = '&&1'
  AND plan_hash_value =  &&2
  AND other_xml   IS NOT NULL
  union
  SELECT X.*
  FROM gv$sql_plan,
       XMLTABLE ( '/other_xml/display_map/row' passing XMLTYPE(other_xml ) COLUMNS 
                        op  NUMBER PATH '@op',    -- operation
                        dis NUMBER PATH '@dis',   -- display
                        par NUMBER PATH '@par',   -- parent
                        prt NUMBER PATH '@prt',   -- ?
                        dep NUMBER PATH '@dep',   -- depth
                        skp NUMBER PATH '@skp' )  -- skip
                    AS X
  WHERE sql_id        = '&&1'
  AND plan_hash_value =  &&2
  AND other_xml   IS NOT NULL
  and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&1' and plan_hash_value = &&2 and rownum <= 1))
, p1 as
 (select nvl2(s.DEPTH,'SQL','AWR') || '_' || nvl(s.PLAN_HASH_VALUE,h.PLAN_HASH_VALUE) as PHV,
          nvl(s.ACCESS_PREDICATES,h.ACCESS_PREDICATES) as ACCESS_PREDICATES,
          nvl(s.BYTES,h.BYTES) as BYTES,
          nvl(s.CARDINALITY,h.CARDINALITY) as CARDINALITY,
          nvl(s.COST,h.COST) as COST,
          nvl(s.CPU_COST,h.CPU_COST) as CPU_COST,
          nvl(s.DEPTH,h.DEPTH) as DEPTH,
          nvl(s.DISTRIBUTION,h.DISTRIBUTION) as DISTRIBUTION,
          nvl(s.FILTER_PREDICATES,h.FILTER_PREDICATES) as FILTER_PREDICATES,
          nvl(s.ID,h.ID) as ID,
          nvl(s.IO_COST,h.IO_COST) as IO_COST,
          nvl(s.OBJECT#,h.OBJECT#) as OBJECT#,
          nvl(s.OBJECT_ALIAS,h.OBJECT_ALIAS) as OBJECT_ALIAS,
          nvl(s.OBJECT_NAME,h.OBJECT_NAME) as OBJECT_NAME,
          nvl(s.OBJECT_NODE,h.OBJECT_NODE) as OBJECT_NODE,
          nvl(s.OBJECT_OWNER,h.OBJECT_OWNER) as OBJECT_OWNER,
          nvl(s.OBJECT_TYPE,h.OBJECT_TYPE) as OBJECT_TYPE,
          nvl(s.OPERATION,h.OPERATION) as OPERATION,
          nvl(s.OPTIMIZER,h.OPTIMIZER) as OPTIMIZER,
          nvl(s.OPTIONS,h.OPTIONS) as OPTIONS,
          nvl(s.OTHER,h.OTHER) as OTHER,
          nvl(s.OTHER_TAG,h.OTHER_TAG) as OTHER_TAG,
          nvl(s.PARENT_ID,h.PARENT_ID) as PARENT_ID,
          nvl(s.PARTITION_ID,h.PARTITION_ID) as PARTITION_ID,
          nvl(s.PARTITION_START,h.PARTITION_START) as PARTITION_START,
          nvl(s.PARTITION_STOP,h.PARTITION_STOP) as PARTITION_STOP,
          nvl(s.PLAN_HASH_VALUE,h.PLAN_HASH_VALUE) as PLAN_HASH_VALUE,
          nvl(s.POSITION,h.POSITION) as POSITION,
          nvl(s.PROJECTION,h.PROJECTION) as PROJECTION,
          nvl(s.QBLOCK_NAME,h.QBLOCK_NAME) as QBLOCK_NAME,
          nvl(s.REMARKS,h.REMARKS) as REMARKS,
          nvl(s.SEARCH_COLUMNS,h.SEARCH_COLUMNS) as SEARCH_COLUMNS,
          nvl(s.SQL_ID,h.SQL_ID) as SQL_ID,
          nvl(s.TEMP_SPACE,h.TEMP_SPACE) as TEMP_SPACE,
          nvl(s.TIME,h.TIME) as TIME,
          nvl(s.TIMESTAMP,h.TIMESTAMP) as TIMESTAMP
    from (select * from gv$sql_plan
          where sql_id = '&&1'
            and plan_hash_value = &&2
            and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&1' and plan_hash_value = &&2 and rownum <= 1)) s
    full outer join (select * from dba_hist_sql_plan h where h.sql_id = '&&1' and h.plan_hash_value = &&2) h
      on s.id = h.id)
, display_map2 AS
 (SELECT X.*
  FROM dba_hist_sql_plan,
       XMLTABLE ( '/other_xml/display_map/row' passing XMLTYPE(other_xml ) COLUMNS 
                        op  NUMBER PATH '@op',    -- operation
                        dis NUMBER PATH '@dis',   -- display
                        par NUMBER PATH '@par',   -- parent
                        prt NUMBER PATH '@prt',   -- ?
                        dep NUMBER PATH '@dep',   -- depth
                        skp NUMBER PATH '@skp' )  -- skip
                    AS X
  WHERE sql_id        = '&&3'
  AND plan_hash_value =  nvl('&&4',0)
  AND other_xml   IS NOT NULL
  union
  SELECT X.*
  FROM gv$sql_plan,
       XMLTABLE ( '/other_xml/display_map/row' passing XMLTYPE(other_xml ) COLUMNS 
                        op  NUMBER PATH '@op',    -- operation
                        dis NUMBER PATH '@dis',   -- display
                        par NUMBER PATH '@par',   -- parent
                        prt NUMBER PATH '@prt',   -- ?
                        dep NUMBER PATH '@dep',   -- depth
                        skp NUMBER PATH '@skp' )  -- skip
                    AS X
  WHERE sql_id        = '&&3'
  AND plan_hash_value =  nvl('&&4',0)
  AND other_xml   IS NOT NULL
  and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&3' and plan_hash_value = nvl('&&4', 0) and rownum <= 1))
, p2 as
 (select nvl2(s.DEPTH,'SQL','AWR') || '_' || nvl(s.PLAN_HASH_VALUE,h.PLAN_HASH_VALUE) as PHV,
          nvl(s.ACCESS_PREDICATES,h.ACCESS_PREDICATES) as ACCESS_PREDICATES,
          nvl(s.BYTES,h.BYTES) as BYTES,
          nvl(s.CARDINALITY,h.CARDINALITY) as CARDINALITY,
          nvl(s.COST,h.COST) as COST,
          nvl(s.CPU_COST,h.CPU_COST) as CPU_COST,
          nvl(s.DEPTH,h.DEPTH) as DEPTH,
          nvl(s.DISTRIBUTION,h.DISTRIBUTION) as DISTRIBUTION,
          nvl(s.FILTER_PREDICATES,h.FILTER_PREDICATES) as FILTER_PREDICATES,
          nvl(s.ID,h.ID) as ID,
          nvl(s.IO_COST,h.IO_COST) as IO_COST,
          nvl(s.OBJECT#,h.OBJECT#) as OBJECT#,
          nvl(s.OBJECT_ALIAS,h.OBJECT_ALIAS) as OBJECT_ALIAS,
          nvl(s.OBJECT_NAME,h.OBJECT_NAME) as OBJECT_NAME,
          nvl(s.OBJECT_NODE,h.OBJECT_NODE) as OBJECT_NODE,
          nvl(s.OBJECT_OWNER,h.OBJECT_OWNER) as OBJECT_OWNER,
          nvl(s.OBJECT_TYPE,h.OBJECT_TYPE) as OBJECT_TYPE,
          nvl(s.OPERATION,h.OPERATION) as OPERATION,
          nvl(s.OPTIMIZER,h.OPTIMIZER) as OPTIMIZER,
          nvl(s.OPTIONS,h.OPTIONS) as OPTIONS,
          nvl(s.OTHER,h.OTHER) as OTHER,
          nvl(s.OTHER_TAG,h.OTHER_TAG) as OTHER_TAG,
          nvl(s.PARENT_ID,h.PARENT_ID) as PARENT_ID,
          nvl(s.PARTITION_ID,h.PARTITION_ID) as PARTITION_ID,
          nvl(s.PARTITION_START,h.PARTITION_START) as PARTITION_START,
          nvl(s.PARTITION_STOP,h.PARTITION_STOP) as PARTITION_STOP,
          nvl(s.PLAN_HASH_VALUE,h.PLAN_HASH_VALUE) as PLAN_HASH_VALUE,
          nvl(s.POSITION,h.POSITION) as POSITION,
          nvl(s.PROJECTION,h.PROJECTION) as PROJECTION,
          nvl(s.QBLOCK_NAME,h.QBLOCK_NAME) as QBLOCK_NAME,
          nvl(s.REMARKS,h.REMARKS) as REMARKS,
          nvl(s.SEARCH_COLUMNS,h.SEARCH_COLUMNS) as SEARCH_COLUMNS,
          nvl(s.SQL_ID,h.SQL_ID) as SQL_ID,
          nvl(s.TEMP_SPACE,h.TEMP_SPACE) as TEMP_SPACE,
          nvl(s.TIME,h.TIME) as TIME,
          nvl(s.TIMESTAMP,h.TIMESTAMP) as TIMESTAMP
    from (select * from gv$sql_plan
          where sql_id = '&&3'
            and plan_hash_value = &&4
            and (inst_id, child_number) in (select inst_id, child_number from gv$sql_plan where sql_id = '&&3' and plan_hash_value = &&4 and rownum <= 1)) s
    full outer join (select * from dba_hist_sql_plan h where h.sql_id = '&&3' and h.plan_hash_value = &&4) h
      on s.id = h.id)
SELECT decode(rownum,1,to_char(p1.phv),'') as PLAN_HASH_VALUE,
       p1.QBLOCK_NAME,
       NVL(m.dis, p1.ID) as ID,
       lpad(' ', level - 1) || p1.operation || ' ' || p1.options as OPERATION,
       QBLOCK_NAME,
       OBJECT_ALIAS,
       nvl2(p1.object_name,'"'||p1.object_owner||'"."'||p1.object_name||'"','') as OBJECT,
       p1.CARDINALITY,
       p1.BYTES,
       to_char(p1.cost) || '(' || to_char(io_cost) || ')' as "COST(IO)",
       p1.temp_space as TEMP,
       p1.TIME
  FROM p1 left join display_map1 m on p1.id = m.op
  where nvl(m.skp,0) <> 1
 CONNECT BY PRIOR p1.id = p1.parent_id
 START WITH p1.id in (select MIN_ID from (select qblock_name, min(id) as MIN_ID from p1 where qblock_name in ('&&5') group by qblock_name)
                       union all select 0 from dual where exists (select column_value from TABLE(sys.OdciVarchar2List('&&5')) where column_value is null))
union all
select  '---------------',
        '--------------------',
        null,
        '--------------------------------------------------------------------------------',
        '--------------------',
        '------------------------------',
        '----------------------------------------',
        null,null,null,null,null FROM dual
union all
SELECT decode(rownum,1,to_char(p2.phv),'') as plan_hash_value,
       p2.qblock_name,
       NVL(m.dis, p2.ID),
       lpad(' ', level - 1) || p2.operation || ' ' || p2.options as OPERATION,
       QBLOCK_NAME,
       OBJECT_ALIAS,
       nvl2(p2.object_name,'"'||p2.object_owner||'"."'||p2.object_name||'"','') as OBJECT,
       p2.cardinality,
       p2.bytes,
       to_char(p2.cost) || '(' || to_char(io_cost) || ')'        as "COST(IO)",
       p2.temp_space as TEMP,
       p2.time
  FROM p2 left join display_map2 m on p2.id = m.op
  where nvl(m.skp,0) <> 1
CONNECT BY PRIOR p2.id = p2.parent_id
 START WITH p2.id in (select MIN_ID from (select qblock_name, min(id) as MIN_ID from p2 where qblock_name in ('&&5') group by qblock_name)
                       union all select 0 from dual where exists (select column_value from TABLE(sys.OdciVarchar2List('&&5')) where column_value is null))
-- ORDER BY NVL(m.dis, p2.ID) -- as a vaiant, instead of CPNNECT BY PRIOR
/
@@sql_plan_diff_notes &&1 &&2 &&3 &&4
@@sql_plan_diff_outl  &&1 &&2 &&3 &&4 &&5
set feedback on VERIFY ON timi on
