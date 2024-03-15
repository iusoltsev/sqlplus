set pages 50

select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from dual
/
select count(*) as APPS_INVALIDS
  from dba_objects
 where owner = 'APPS'
   and status != 'VALID'
   and OBJECT_TYPE != 'MATERIALIZED VIEW'
   and object_name not like 'XXTEST%'
/
select count(*) as timestamp_diffs
  from sys.obj$ do, sys.dependency$ d, sys.obj$ po
 where P_OBJ# = po.obj#(+)
   and D_OBJ# = do.obj#
      ----                 and do.status=1 /*dependent is valid*/
      ----                 and po.status=1 /*parent is valid*/
   and po.stime != p_timestamp /*parent timestamp not match*/
   and do.type# not in (28, 29, 30) /*dependent type is not java*/
   and po.type# not in (28, 29, 30) /*parent type is not java*/
/
select * from
    (
      select
          case when object_name like 'XX%' then owner||'.'||'XX' else owner end owner
        , object_type
        , count(decode(actual,'Y',1,NULL)) Actual
        , count(decode(actual,'N',1,NULL)) Stub
        , count(*) Total
      from
          apps.ad_objects
      where status='INVALID'
        and (sys_context('userenv', 'current_schema') = 'SYSTEM' or
             sys_context('userenv', 'current_schema') = 'SYS' or
             owner = sys_context('userenv', 'current_schema')
             )
      group by case when object_name like 'XX%' then owner||'.'||'XX' else owner end
              , object_type
    ) x
 where total > 0
 order by 1,2
/
--mba/admin/salt-oebs/services/oracle-bora-paysys/files/opt/oracle/admin/sql/get_oebs_invalids.sql
