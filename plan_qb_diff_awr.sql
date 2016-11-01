--
-- SQL Plan QBlock Section[s] Differences from AWR
-- Usage: SQL> @plan_qb_diff_awr 6r6sanrs05550 3541904711        2970372553        "SEL$6444526D','SET$1"
--                               ^SQL_ID       ^PLAN_HASH_VALUE1 ^PLAN_HASH_VALUE2  ^QBLOCK_LIST in form "[QB1[','QB2...]]"
-- when QBLOCK_LIST parameter is null then script outputs the whole plans comparision
-- by Igor Usoltsev
--

set feedback off heading on timi off pages 500 lines 500 echo off  VERIFY OFF

col OPERATION    for a90
col ID           for 9999
col OBJECT_OWNER for a30
col OBJECT_NAME  for a30
col QBLOCK_NAME  for a20

with
pt1 as
 (select *
    from dba_hist_sql_plan
   where sql_id = '&&1'
     and plan_hash_value = nvl('&&2',0)),
pt2 as
 (select *
    from dba_hist_sql_plan
   where sql_id = '&&1'
     and plan_hash_value = nvl('&&3',0))
SELECT decode(rownum,1,to_char(pt1.plan_hash_value),'') as plan_hash_value,
       pt1.qblock_name,
       pt1.id,
       lpad(' ', 2 * level) || pt1.operation || ' ' || pt1.options as OPERATION,
       pt1.object_owner,
       pt1.object_name,
       pt1.cardinality,
       pt1.bytes,
       pt1.cost
  FROM pt1
CONNECT BY PRIOR pt1.id = pt1.parent_id
 START WITH pt1.id in (select MIN_ID from (select qblock_name, min(id) as MIN_ID from pt1 where qblock_name in ('&&4') group by qblock_name)
                       union all --select 0 from dual where '&&4' is null
                                 select 0 from dual where exists (select column_value from TABLE(sys.OdciVarchar2List('&&4')) where column_value is null))
union all
select distinct '---------------',
                '--------------------',
                null,
                '------------------------------------------------------------------------------------------',
                '------------------------------',
                '------------------------------',
                null,null,null FROM pt2
union all
SELECT decode(rownum,1,to_char(pt2.plan_hash_value),''),
       pt2.qblock_name,
       pt2.id,
       lpad(' ', 2 * level) || pt2.operation || ' ' || pt2.options as OPERATION,
       pt2.object_owner,
       pt2.object_name,
       pt2.cardinality,
       pt2.bytes,
       pt2.cost
  FROM pt2
CONNECT BY PRIOR pt2.id = pt2.parent_id
 START WITH pt2.id in (select MIN_ID from (select qblock_name, min(id) as MIN_ID from pt2 where qblock_name in ('&&4') group by qblock_name)
                       union all --select 0 from dual where '&&4' is null
                                 select 0 from dual where exists (select column_value from TABLE(sys.OdciVarchar2List('&&4')) where column_value is null))
/

set feedback on VERIFY ON timi on