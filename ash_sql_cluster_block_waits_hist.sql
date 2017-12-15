--
-- ASH script for SQLs and objects grouping from cluster waits concurrency for the same db blocks
-- May be useful for the Cluster waits problem periods
-- Usage: SQL> @ash_sql_cluster_block_waits_temp 8ubrykptawra1 2 500
-- by Igor Usoltsev
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col INST_ID1 for 9999999
col INST_ID2 for 9999999
col EVENT1 for a40
col EVENT2 for a40
col CLIENT_ID for a30
col SQL_OPNAME1 for a12
col SQL_OPNAME2 for a12
col object_type for a20
col object_name for a40

with ash as (select /* MATERIALIZE*/ * from dba_hist_active_sess_history where snap_id between 348233 and 348236
--             where sample_time between nvl(to_date('#1','dd.mm hh24:mi'),sysdate-1e6) and nvl(to_date('#2','dd.mm hh24:mi'),sysdate+1e6)
             )
select ash1.instance_number          as INST_ID1,
       REGEXP_SUBSTR(ash1.client_id, '.+\#') as CLIENT_ID,
       ash1.sql_opname       as SQL_OPNAME1,
       ash1.sql_id           as SQL_ID1,
       ash1.event            as EVENT1,
       ash1.blocking_inst_id as ASH_BLOCK_INST,    -- блокирующий INST_ID по версии ASH
       ash2.instance_number          as REM_BLOCK_INST,    -- блокирующий INST_ID по конкуренции за блоки бд
       ash2.sql_opname       as SQL_OPNAME2,
       ash2.sql_id           as SQL_ID2,
       ash2.event            as EVENT2,
       o.object_type,
       o.object_name,
       count(*)                                                as WAITS_COUNT,
       count(distinct ash1.current_file#||' '||ash1.current_block#) as CONC_BLOCK_COUNT
from ash ash1
join ash ash2 on ash1.current_file#  = ash2.current_file#
             and ash1.current_block# = ash2.current_block#
             and ash1.wait_class     = ash2.wait_class
             and ash1.session_state  = ash2.session_state
             and ash1.p1text         = ash2.p1text
             and ash1.instance_number       <> ash2.instance_number                              -- с разных нод
             and ash2.sample_time    > ash1.sample_time                          -- недублированные
--             and (ash1.sql_id in (nvl('&&1',ash1.sql_id)) or ash2.sql_id in (nvl('&&1',ash2.sql_id)))
and (ash1.client_id like '&&1%' or ash2.client_id like '&&1%')
             and to_char(ash2.sample_time,'SSSSS') - to_char(ash1.sample_time,'SSSSS') <= nvl('&2', 1) -- почти одновременные
left join dba_objects o on ash1.current_obj# = object_id
where ash1.wait_class    = 'Cluster'                                             -- кластерные
  and ash1.p1text        = 'file#'                                               -- блок-ориентированные
  and ash1.session_state = 'WAITING'                                             -- ожидания
group by ash1.instance_number,
         ash1.sql_opname,
         ash1.sql_id,
         ash1.event,
         ash1.blocking_inst_id,
         ash2.instance_number,
         ash2.sql_opname,
         ash2.sql_id,
         ash2.event,
         o.object_type,
         o.object_name,
         REGEXP_SUBSTR(ash1.client_id, '.+\#')
having count(*) > nvl('&3', 500)
order by count(*) desc
/
set feedback on echo off VERIFY ON