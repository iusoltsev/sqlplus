--11.2.0.2+
set feedback off heading on timi on pages 200 lines 500 echo off  VERIFY OFF
col INST for 9999
col EXECS for 99999999
col CHILD for 99999
col BIND_SENSE for a10
col BIND_AWARE for a10
col SHAREABLE for a10
col USE_FEEDBACK_STATS for a18
col OPTIMIZER_STATS for a16
col BIND_EQ_FAILURE for a16
col Reason for a400
col SQL_PLAN_BASELINE for a30
col SQL_PATCH for a30
col SQL_PROFILE for a64

/*
with R as (
select sc.inst_id as INST, is_obsolete, 
       pq_slave_mismatch, top_level_rpi_cursor,
       (select reasons || '  |  ' || details
          from xmltable('/ChildNode' passing
                        (select case when dbms_lob.instr(reason, '<ChildNode>', 1, 2) = 0 then
                                   xmltype(reason)
                                  else
                                    xmltype(dbms_lob.substr(reason, dbms_lob.instr(reason, '<ChildNode>', 1, 2) - 1))
                                  end as xmlval
                           from gv$sql_shared_cursor
                          where dbms_lob.substr(reason, 256) <> ' '
                            and sql_id = sc.sql_id
                            and inst_id = sc.inst_id
                            and child_address = sc.child_address)
                        columns Reasons varchar2(60) path '/ChildNode/reason',
                        Details varchar2(60) path '/ChildNode/details')) as Reason1,
       (select reasons || '  |  ' || details
          from xmltable('/ChildNode' passing
                        (select xmltype(dbms_lob.substr(reason, dbms_lob.instr(reason, '</ChildNode>', 1, 2) - dbms_lob.instr(reason, '</ChildNode>', 1, 1), dbms_lob.instr(reason, '<ChildNode>', 1, 2)))
                           from gv$sql_shared_cursor
                          where dbms_lob.substr(reason, 256) <> ' '
                            and sql_id = sc.sql_id
                            and inst_id = sc.inst_id
                            and child_address = sc.child_address)
                        columns Reasons varchar2(60) path '/ChildNode/reason',
                        Details varchar2(60) path '/ChildNode/details')) as Reason2
  from gv$sql_shared_cursor sc, gv$sql s
 where sc.sql_id = '&1'
   and sc.inst_id = s.inst_id
   and sc.sql_id = s.sql_id
   and sc.child_address = s.child_address)
select inst, is_obsolete, 
       pq_slave_mismatch, top_level_rpi_cursor,
       Reason1, Reason2, count(*) from R
group by inst, is_obsolete, pq_slave_mismatch, top_level_rpi_cursor, Reason1, Reason2
order by count(*) desc
*/
SELECT INST,
       count(*),
       is_obsolete,
--       pq_slave_mismatch,
--       top_level_rpi_cursor,
       Reason
from (
SELECT INST,
       is_obsolete,
--       pq_slave_mismatch,
--       top_level_rpi_cursor,
       LISTAGG(Reason, '; ') WITHIN GROUP (ORDER BY to_number(rid)) AS Reason
FROM (select sc.sql_id,
             sc.child_address,
             sc.inst_id as INST,
             is_obsolete, 
--             pq_slave_mismatch,
--             top_level_rpi_cursor,
             xt.rid || ' |' || xt.Reasons || ' |' || xt.Details as Reason,
             xt.rid
             from gv$sql_shared_cursor sc, gv$sql s,
               xmltable('/Reasonz/ChildNode' passing xmltype('<Reasonz>'||sc.reason||'</Reasonz>')
                        columns
                        RID varchar2(60) path 'ID',
                        Reasons varchar2(60) path 'reason',
                        Details varchar2(60) path 'details') xt
                          where dbms_lob.substr(reason, 256) <> ' '
                            and '&&1' = sc.sql_id
                            and s.sql_id = sc.sql_id
                            and s.child_address = sc.child_address
                            and s.inst_id = sc.inst_id)
GROUP BY INST,
         is_obsolete,
--         pq_slave_mismatch,
--         top_level_rpi_cursor,
         child_address)
GROUP BY INST,
         is_obsolete,
--         pq_slave_mismatch,
--         top_level_rpi_cursor,
         Reason
order by count(*) desc
/

set feedback on VERIFY ON