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
col Reason for a100
col SQL_PLAN_BASELINE for a30
col SQL_PATCH for a30
col SQL_PROFILE for a64
col        IS_OBSOLETE for a11
col        FLASHBACK_CURSOR for a16
col        IS_SHAREABLE for a12

SELECT INST,
       child_number,
       is_obsolete as "IS_OBSOLETE",
       flashback_cursor as "FLASHBACK_CURSOR",
       is_shareable as "IS_SHAREABLE",
       LISTAGG(Reason, '; ') WITHIN GROUP (ORDER BY to_number(rid)) AS Reason
FROM (select sc.sql_id,
             sc.child_number,
             sc.child_address,
             sc.inst_id as INST,
             is_obsolete, 
             flashback_cursor,
             is_shareable,
             xt.rid || ' |' || xt.Reasons || ' |' || xt.Details as Reason,
             xt.rid
             from gv$sql_shared_cursor sc, gv$sql s,
               xmltable('/Reasonz/ChildNode' passing xmltype('<Reasonz>'||sc.reason||'</Reasonz>')
                        columns
                        RID varchar2(60) path 'ID',
                        Reasons varchar2(60) path 'reason',
                        Details varchar2(60) path 'details') xt
                          where dbms_lob.substr(reason, 256) <> ' '
                            and '&1' = sc.sql_id
                            and s.sql_id = sc.sql_id
                            and s.child_address = sc.child_address
                            and 1 = sc.inst_id)
GROUP BY INST,
         is_obsolete,
         flashback_cursor,
         is_shareable,
         child_number,
         child_address
/

set feedback on VERIFY ON