SQL> select * from DBA_HIST_WR_CONTROL;

      DBID SNAP_INTERVAL                                                               RETENTION
---------- --------------------------------------------------------------------------- -----------------
2957000106 +00000 00:15:00.0                                                           +00014 00:00:00.0
BEGIN
  DBMS_WORKLOAD_REPOSITORY.modify_snapshot_settings(
    retention => 86400,        -- Minutes (= 30 Days). Current value retained if NULL.
    interval  => 60);          -- Minutes. Current value retained if NULL.
END;

CONNECT / AS SYSDBA
grant advisor to scott;
grant select_catalog_role to scott;
grant execute on dbms_workload_repository to scott;

--        
select
snap_id, dbid, instance_number, begin_interval_time, end_interval_time
from DBA_HIST_SNAPSHOT
order by begin_interval_time desc

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  900773960, 1, 25556, 25557));

22	01.12.2017 20:00:00	3909292	3516,5	22916	1256416866
23	01.12.2017 21:00:00	2355485	9362	7616	786268124
130121
64	01.02.2018 14:00:00	4828948	14588,5	17865	1101523896
133085

select min(sample_time), max(sample_time) from dba_hist_active_sess_history where snap_id in (397958)
select inst_id, min(sample_time), max(sample_time) from gv$active_session_history group by inst_id

select * from dba_hist_latch_misses_summary where parent_name like 'redo copy%'

select sql_id,
       sql_exec_id,
       sql_plan_line_id,
       sql_plan_operation,
       in_parse,
       in_hard_parse,
       in_sql_execution,
       count(*),
       min(sample_time),
       max(sample_time)
  from dba_hist_active_sess_history
 where --sql_id = '5rrd8z9nt7t2j'
--   and sql_plan_hash_value <> 1613548637 and
 event = 'cursor: pin S wait on X'
   and snap_id between 29296 and 29298
 group by sql_id,
          sql_exec_id,
          sql_plan_line_id,
          sql_plan_operation,
          in_parse,
          in_hard_parse,
          in_sql_execution
 order by count(*) desc



DECLARE
  task_name VARCHAR2(30) := 'SCOTT_ADDM';
  task_desc VARCHAR2(30) := 'ADDM Feature Test';
  task_id   NUMBER;
BEGIN
  select count(*)
    into task_id
    from dba_advisor_tasks
   where task_name = 'SCOTT_ADDM';
  if task_id = 0 then
    dbms_advisor.create_task('ADDM', task_id, task_name, task_desc, null);
  else
    dbms_advisor.reset_task(task_name => 'SCOTT_ADDM');
  end if;
  dbms_advisor.set_task_parameter('SCOTT_ADDM', 'START_SNAPSHOT', 10376);
  dbms_advisor.set_task_parameter('SCOTT_ADDM', 'END_SNAPSHOT', 10379);
--  dbms_advisor.set_task_parameter('SCOTT_ADDM', 'START_SNAPSHOT', 10398);
--  dbms_advisor.set_task_parameter('SCOTT_ADDM', 'END_SNAPSHOT', 10399);
  dbms_advisor.set_task_parameter('SCOTT_ADDM', 'INSTANCE', 1);
  dbms_advisor.set_task_parameter('SCOTT_ADDM', 'DB_ID', 1235232747);
  dbms_advisor.execute_task('SCOTT_ADDM');
END;

select * from dba_advisor_tasks where task_name = 'SCOTT_ADDM'

begin dbms_advisor.delete_task(task_name => 'SCOTT_ADDM'); end;

select dbms_advisor.get_task_report('SCOTT_ADDM', 'TEXT', 'ALL') from sys.dual;

-- make sure to set line size appropriately
-- set linesize 152

select dbms_addm.get_report('ADDM:4190886842_2_367608') from dual

select * from dba_segments where segment_name in (select 'AUCTION_OFFER_BID' from dual
union all select index_name from dba_indexes where table_name in ('AUCTION_OFFER_BID'))
select * from dba_indexes where table_name in ('AUCTION_OFFER_BID')

SELECT DBMS_PERF.REPORT_PERFHUB(outer_start_time    => to_date('22.09.2016 08:00', 'dd.mm.yyyy hh24:mi'),
                                outer_end_time      => to_date('22.09.2016 16:00', 'dd.mm.yyyy hh24:mi'),
                                selected_start_time => to_date('22.09.2016 08:00', 'dd.mm.yyyy hh24:mi'),
                                selected_end_time   => to_date('22.09.2016 16:00', 'dd.mm.yyyy hh24:mi'))
  FROM dual;

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842, 2, 397908, 397909));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  1071336896, 1, 28828, 28832));

select trunc(sample_time,'mi'), session_state, wait_class, count(*) from v$active_session_history where sql_id = '9v54zwyrwfbr5' and session_state = 'WAITING' group by trunc(sample_time,'mi'), session_state, wait_class order by 1
select sql_id, min(sample_time), inst_id from gv$active_session_history group by inst_id
select sql_id, program, inst_id, count(*) from gv$active_session_history
where wait_class 
 group by inst_id

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2763400359,  1, 105042, 105045));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  1, 382449, 382451));

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 387485, 387488));

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  1, 384607, 384609));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 383670, 383673));


select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  1, 383101, 383110));
43	 RAC GC blocks received:           1,781.8               0.5
44	   RAC GC blocks served:           1,430.2               0.4
45	             User calls:          31,835.2               9.2
46	           Parses (SQL):           9,361.3               2.7
47	      Hard parses (SQL):               5.3               0.0
48	     SQL Work Area (MB):             125.1               0.0
49	                 Logons:              27.5               0.0
50	         Executes (SQL):          11,901.3               3.4
51	              Rollbacks:           2,157.7               0.6
52	           Transactions:           3,461.5

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 383102, 383108));
45	             User calls:          26,183.2              14.6
46	           Parses (SQL):           8,219.0               4.6
47	      Hard parses (SQL):               2.2               0.0
48	     SQL Work Area (MB):              54.9               0.0
49	                 Logons:              31.4               0.0
50	         Executes (SQL):           8,806.7               4.9
51	              Rollbacks:           1,346.3               0.8
52	           Transactions:           1,794.4

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  1, 374462, 374468));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 374462, 374468));

select min(sample_time), max(sample_time) from dba_hist_active_sess_history where snap_id between 380617 and 380619

select min(sample_time), max(sample_time) from dba_hist_active_sess_history where snap_id =397933
and event = 'direct path write temp' group by sql_id order by count(*) desc


@ash_iobj_waits_hist blocks 20         "where snap_id between 380617 and 380619"


select * from gv$sqlarea where sql_id = '9t7605j0upt2a'


select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 383998, 384002))
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 380630, 380632));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 384712, 384714));
378803



select * from gv$sqlarea where sql_id = 'anm63t81cmkrx'
--!!!
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  2, 130121, 130125));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  2, 144804, 144806));


select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  1, 133042, 133046));

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  1, 133082, 133084));

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  1, 133086, 133094));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  1, 133097, 133098));-------------------------------------------------------------------

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  2, 130435, 130439));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  2, 133129, 133130));
--!!!

select min(sample_time), max(sample_time) from dba_hist_active_sess_history where snap_id between 335251 and 335262

@ash_sql_wait_tree "event = 'enq: TX - row lock contention'" 100 "where sample_time between to_date('19.09.2016 11:00', 'dd.mm.yyyy hh24:mi') and to_date('19.09.2016 11:30', 'dd.mm.yyyy hh24:mi')"

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 332049, 332050));

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  1, 383019, 383025));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 383019, 383025));

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 383929, 383932));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  2, 383936, 383939));



select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  4190886842,  1, 332390, 332394))
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  455706333,  1, 4964, 4978));

select dbms_addm.get_report('ADDM:2987015588_1_33308') from dual
select dbms_addm.get_report('ADDM:2987015588_1_33308') from dual
select dbms_addm.get_report('ADDM:2987015588_1_33308') from dual
select dbms_addm.get_report('ADDM:2987015588_1_33308') from dual
select dbms_addm.get_report('ADDM:2987015588_1_33308') from dual

select min(sample_time), max(sample_time) from dba_hist_active_sess_history where snap_id in (332050)

select REGEXP_SUBSTR(client_id, '.+\#'), count(*) from dba_hist_active_sess_history where snap_id in (332050,332051)
group by REGEXP_SUBSTR(client_id, '.+\#')
order by count(*) desc

select *--attr_number, attr_value as cbo_hint
  from DBMSHSXP_SQL_PROFILE_ATTR
where profile_name = :SQL_PROFILE_NAME;

SELECT * FROM TABLE(dbms_xplan.display_cursor('4n82kxntbmhd9', format => 'all allstats last'))
select * from v$instance


select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(4190886842, 1, 342907, 342908));
select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(4190886842, 2, 317237, 317242));


select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(4190886842, 2, 300461, 300462));


select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  2, 58446, 58447));

select output from table( DBMS_WORKLOAD_REPOSITORY.awr_sql_report_text(2598577434, 1, 58600, 58642,'dzk9rwxx9qqx2'));

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  2, 58620, 58621));--OEBS2 critic i/o

select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  2, 58641, 58642));--OEBS2 critic i/o


select output from table( DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(  2598577434,  1, 58681, 58682));

select * from v$instance

select output from table( DBMS_WORKLOAD_REPOSITORY.ash_report_text(  4190886842,  1, to_date('27-Dec-11 06:30:17','dd-mon-rr hh24:mi:ss'), to_date('27-Dec-11 08:42:44','dd-mon-rr hh24:mi:ss')));


select output from table( DBMS_WORKLOAD_REPOSITORY.awr_sql_report_text( 4190886842,  2, 228777, 228778, 'bsut9hdfjw86h'));

select output from table( DBMS_WORKLOAD_REPOSITORY.awr_diff_report_text( 4190886842,  1, 278613, 278614,  4190886842,  2, 278805, 278806));



select output from table( DBMS_WORKLOAD_REPOSITORY.awr_report_html(  3022678912,  1, 214276, 214277));

select * from table(dbms_xplan.display_cursor('fvzuq35sd8uv1',3))

select extent_management, allocation_type, segment_space_management from dba_tablespaces

select * from dba_objects where object_name like '%HISTORY%'

begin DBMS_WORKLOAD_REPOSITORY.create_snapshot; end;

select
sna.begin_interval_time,
hse.event_name,
case WHEN (LEAD(total_waits,1) over (ORDER BY hse.snap_id) <= total_waits) THEN null   -- db restarted during interval
            ELSE (LEAD(total_waits,1) over (ORDER BY hse.snap_id) - total_waits) end
from dba_hist_system_event hse, dba_hist_snapshot sna
where hse.snap_id = sna.snap_id
and hse.event_name = 'control file sequential read'
order by 1 desc

select
    sna.instance_number,
    sna.snap_id + 1 as snap_id,
    to_char(sna.end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    hse.event_name,
    case WHEN (LEAD(hse.total_waits,1) over (PARTITION BY hse.instance_number ORDER BY hse.snap_id) <= total_waits) THEN null
                ELSE (LEAD(total_waits,1) over (PARTITION BY hse.instance_number ORDER BY hse.snap_id) - total_waits) end
from dba_hist_system_event hse, dba_hist_snapshot sna
  where hse.snap_id = sna.snap_id
    and hse.instance_number = sna.instance_number
    and hse.event_name like 'direct path write temp'
--    and hse.instance_number = 1
  order by 2 desc, 1

select
    instance_number,
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits) THEN null
                ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits) end
from 
    (select sna.snap_id, sna.end_interval_time, event_name, hse.instance_number, sum(hse.total_waits) as total_waits
     from dba_hist_system_event hse, dba_hist_snapshot sna
     where hse.snap_id = sna.snap_id
     and hse.instance_number = sna.instance_number
     and hse.event_name = 'db file sequential read'
     group by
     sna.snap_id, sna.end_interval_time, event_name, hse.instance_number)
--    and hse.instance_number = 1
  order by 2 desc, 1


select 
trunc(begin_interval_time,'hh24'),
sum(nvl(AVG_WAITS,0)),
avg(nvl(AVG_WAIT_TIME_MS,0)),
sum(nvl(physical_read_IO_requests,0)),
sum(nvl(physical_read_total_bytes,0))
--select *
 from (
select
    instance_number as inst_id,
    snap_id as snap_id,
    end_interval_time--to_char(end_interval_time, 'dd.mm.yyyy hh24:mi')
     as begin_interval_time,
    hse.event_name event,
    case WHEN (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse.total_waits)
              THEN 0--null
              ELSE (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse.total_waits)
         END as AVG_WAITS,
    case WHEN (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse.total_waits)
              THEN 0--null
              ELSE round((LEAD(hse.time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse.time_waited_micro)
                        / (LEAD(hse.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse.total_waits))
         END as AVG_WAIT_TIME_MS,
    hse2.event_name event2,
    case WHEN (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse2.total_waits)
              THEN 0--null
              ELSE (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse2.total_waits)
         END as AVG_WAITS2,
    case WHEN (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse2.total_waits)
              THEN 0--null
              ELSE round((LEAD(hse2.time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse2.time_waited_micro)
                        / (LEAD(hse2.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse2.total_waits))
         END as AVG_WAIT_TIME_MS2,
    case WHEN (LEAD(hse3.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse3.total_waits)
              THEN 0--null
              ELSE (LEAD(hse3.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse3.total_waits)
         END as AVG_WAITS2,
    case WHEN (LEAD(hse3.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hse3.total_waits)
              THEN 0--null
              ELSE round((LEAD(hse3.time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse3.time_waited_micro)
                        / (LEAD(hse3.total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - hse3.total_waits))
         END as AVG_WAIT_TIME_MS3
/*,
    case WHEN (LEAD(hst.value,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hst.value)
              THEN 0--null
         ELSE round((LEAD(hst.value,1) over (PARTITION BY instance_number ORDER BY snap_id) - hst.value)
              / ((to_date(to_char(end_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
               - to_date(to_char(begin_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss'))*86400))
         END as physical_read_IO_requests,
    case WHEN (LEAD(hst2.value,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hst2.value)
              THEN 0--null
         ELSE round((LEAD(hst2.value,1) over (PARTITION BY instance_number ORDER BY snap_id) - hst2.value)
              / ((to_date(to_char(end_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
               - to_date(to_char(begin_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss'))*86400))
         END as physical_read_total_bytes
*/
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     join dba_hist_system_event hse2 using(snap_id, instance_number)
     join dba_hist_system_event hse3 using(snap_id, instance_number)
--     join dba_hist_sysstat hst using(snap_id, instance_number)
--     left join dba_hist_sysstat hst2 using(snap_id, instance_number)
     where hse.event_name = 'log file sync'
     and hse2.event_name = 'log file parallel write'
     and hse3.event_name = 'target log write size'
--     and hst.stat_name    = 'physical read IO requests'
--     and hst2.stat_name   = 'physical write IO requests'
--and snap_id between 133030 and 133050
and instance_number=1
  order by 2 desc, 1
)
-- where snap_id >= 133057 or snap_id between 130080 and 130176
group by trunc(begin_interval_time,'hh24')
order by 1

select * from v$sysstat where name like 'physical%total IO requests'

select distinct p1, count(*) from v$active_session_history where event = 'db file parallel write' group by p1

select * from v$event_name where wait_class = 'System I/O' and lower(name) like '%write%'

--+ Latches
select * from (
select
    instance_number,
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits)
         END as AVG_WAITS,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_MS,
    case WHEN (LEAD(hst.value,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hst.value)
              THEN null
         ELSE round((LEAD(hst.value,1) over (PARTITION BY instance_number ORDER BY snap_id) - hst.value)
              / ((to_date(to_char(end_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
               - to_date(to_char(begin_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss'))*86400))
         END as "read IO requests per sec"
/*, case WHEN (LEAD(hst2.value,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hst2.value)
              THEN null
         ELSE round((LEAD(hst2.value,1) over (PARTITION BY instance_number ORDER BY snap_id) - hst2.value)
              / ((to_date(to_char(end_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
               - to_date(to_char(begin_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss'))*86400))
         END as "write IO requests per sec"
,   case WHEN (LEAD(hsL.immediate_misses,1) over (PARTITION BY instance_number ORDER BY snap_id) <= hsL.immediate_misses)
              THEN null
         ELSE round((LEAD(hsL.immediate_misses,1) over (PARTITION BY instance_number ORDER BY snap_id) - hsL.immediate_misses)
              / ((to_date(to_char(end_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
               - to_date(to_char(begin_interval_time,'yyyy-mm-dd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss'))*86400))
         END as "redo copy immisses per sec"
*/
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     join dba_hist_sysstat hst using(snap_id, instance_number)
--     left join dba_hist_latch hsL using(snap_id, instance_number)
--     left join dba_hist_sysstat hst2 using(snap_id, instance_number)
     where hse.event_name = 'log file sync'
     and hst.stat_name    = 'redo size'
--     and hst2.stat_name    = 'physical write bytes'--'physical write IO requests'
--     and hsL.LATCH_NAME  = 'redo copy'--'redo writing'--
     and instance_number=2
  order by 2 desc, 1
) where snap_id between 380850 and 380870

select * from v$statname where upper(name) like '%REDO%'
Redo size (bytes)

select * from v$statname where lower(name) like '%write%'
select * from v$statname where name like 'user I/O wait time'

select statistic_name, sum(value) from gv$segstat where statistic_name in ('physical reads', 'physical reads direct')--,'physical read requests','optimized physical reads')
group by statistic_name
union all
select name as statistic_name, sum(value) from gv$sysstat where name in ('physical reads', 'physical reads direct','physical reads direct temporary tablespace')
group by name

select * from v$statname where name like 'physical%write%'

--select * from (
select
    instance_number,
--    snap_id as snap_id,
    LEAD(snap_id,1) over (PARTITION BY instance_number ORDER BY snap_id) as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits)
         END as WAITS_COUNT,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_nS,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round(LEAD(time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - time_waited_micro)
         END as sum_time_waited_nS
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where hse.event_name in ('log file sync')--('log file sync')--
--     and snap_id between 387817 and 387849
     and instance_number = 2
  order by 2 desc, 1
--) where snap_id between 388394  and 388424

select
    instance_number,
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits)
         END as AVG_SEQ_READ_WAITS,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_nS,
    case WHEN (LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= time_waited_micro)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro) / 1000)

select
    instance_number as "INST_ID",
    snap_id as begin_snap_id,
    snap_id + 1 as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits)
         END as WAIT_COUNT,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_nS,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round(LEAD(time_waited_micro,1) over (PARTITION BY instance_number, event_name ORDER BY snap_id) - time_waited_micro)
         END as WAIT_TIME_nS
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where hse.event_name = 'log file parallel write'--'db file sequential read'-- 'SQL*Net more data to client'--'log file parallel write'--'LGWR wait for redo copy'--
--       and instance_number = 1--('enq: TX - row lock contention')--('enq: TX - allocate ITL entry')--
--and (snap_id between 334247 and 334252 or snap_id between 332565 and 332575)
  order by 2 desc,1

         END as time_waited_ms
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where hse.event_name in ('log file sync')
  order by 2 desc, 1

select s.*
,round(AVG(AVG_WAIT_TIME_nS) OVER (PARTITION BY INST_ID ORDER BY begin_snap_id ROWS BETWEEN 5 PRECEDING AND 5 FOLLOWING)) as MOV_AVG_WAIT_TIME_nS
 from (
	    ) s
 where WAIT_COUNT is not null
/

02.10.2017 20:00
28.09.2017 11:00
04.12.2017 14:00

@dba_hist_system_event "event_name = 'log file sync' and snap_id > 337230"

select * from v$logfile
select --trunc(logon_time,'mi'), status, 
event, count(*) from gv$session where client_identifier like 'Notifi%' group by --trunc(logon_time,'mi'), status, 
event order by count(*) desc

select * from (
select
    instance_number as "INST_ID",
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    stat_name,
    case WHEN (LEAD(value,1) over (PARTITION BY instance_number, stat_name ORDER BY snap_id) <= value)
              THEN null
              ELSE (LEAD(value,1) over (PARTITION BY instance_number, stat_name ORDER BY snap_id) - value)
         END as Value
from dba_hist_sysstat hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where stat_name = 'Read IO (MB)'-- and instance_number = 1
  order by 2, 1
      ) where Value is not null

select * from dba_hist_sys_time_model where stat_name = 'DB time'
select distinct stat_name from dba_hist_sys_time_model
select distinct stat_name from dba_hist_sysstat

select * from dba_hist_sysmetric_history where metric_name = 'I/O Megabytes per Second'

select
    instance_number as "INST_ID",
    snap_id as snap_id,
    --to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as 
    begin_interval_time,
    metric_name,
      --case WHEN (LEAD(value,1) over (PARTITION BY instance_number, metric_name ORDER BY snap_id) <= value) THEN null ELSE 
      --(LEAD(value,1) over (PARTITION BY instance_number, metric_name ORDER BY snap_id) - value)
      --   END as
       round(Value) as Value
from dba_hist_sysmetric_history hsm
     join dba_hist_snapshot sna using(snap_id, instance_number)
--     where metric_name = 'I/O Megabytes per Second'-- and instance_number = 1
--     and begin_interval_time > sysdate - 1
  order by 3 desc, 1

select * from (
select
    instance_number as "INST_ID",
    snap_id as snap_id,
    dbid,
    cast(end_interval_time as date) as begin_interval_time,
    stat_name,
    case WHEN (LEAD(value,1) over (PARTITION BY instance_number, stat_name, dbid ORDER BY snap_id) <= value)
              THEN null
              ELSE (LEAD(value,1) over (PARTITION BY instance_number, stat_name, dbid ORDER BY snap_id) - value)
         END as Value
from dba_hist_sys_time_model hse
     join dba_hist_snapshot sna using(snap_id, instance_number, dbid)
     where stat_name = 'DB time'-- and instance_number = 1
--and snap_id between 28825 and 28837
and dbid = 1071336896
and end_interval_time > sysdate -60
  order by 6 desc, 1
      ) where Value is not null

select * from dba_hist_sys_time_model where stat_name = 'DB time' and snap_id = 28837
select * from dba_hist_snapshot order by BEGIN_INTERVAL_TIME desc--28837

--$ crsctl stat res -t
--$ crs_start ora.mgmtdb
--sqlplus system/ujh,fnsq@key-db2f/key_dbf_cluster
select *
  from (select to_char(mtime,'dd.mm.yyyy hh24:mi:ss'),
               hostname,
               nid,
               round(bytesinpersec  * 8 / 1024 / 1024 / 1024, 3)                   as "NET_RCV_Gb",
               round(bytesoutpersec * 8 / 1024 / 1024 / 1024, 3)                   as "NET_SENT_Gb",
               round((EFFECTIVEBW) * 8 / 1024 / 1024 / 1024, 3)                    as "NET_IO_Gb"
          from CHM.CHMOS_NIC_INT_TBL
         where mtime > trunc(sysdate)+14/24--between to_date('29.03.2017 21','dd.mm.yyyy hh24') and to_date('30.03.2017 01','dd.mm.yyyy hh24')--
         order by 5 desc)
 where rownum <= 10

select * from (
select to_char(mtime, 'dd.mm.yyyy hh24:mi:ss'),
       hostname,
       round(disk_bytesreadpersec * 8 /1024 /1024 /1024,3) as disk_read_gb,
       round(disk_byteswrittenpersec * 8 /1024 /1024 /1024,3) as disk_write_gb,
       round((disk_bytesreadpersec + disk_byteswrittenpersec) * 8 /1024 /1024 /1024,3) as DISK_IO,
       DISK_NUMIOSPERSEC,
       round(net_bytesrecvpersec * 8 /1024 /1024 /1024,3) as net_rcv_gb,
       round(net_bytessentpersec * 8 /1024 /1024 /1024,3) as net_sent_gb,
       round((net_bytesrecvpersec + net_bytessentpersec) * 8 /1024 /1024 /1024,3) as NET_IO,
       CPUIOWAITPERCENT/100
  from CHM.CHMOS_SYSTEM_SAMPLE_INT_TBL
 where mtime > trunc(sysdate)+14/24--mtime between to_date('29.03.2017 21','dd.mm.yyyy hh24') and to_date('30.03.2017 01','dd.mm.yyyy hh24') --mtime > trunc(sysdate) --+ 12/24 and trunc(sysdate) + 13/24 --trunc(sysdate,'hh24')
-- group by trunc(mtime,'hh24'), hostname
 order by 4 desc
) where rownum <= 100

select * from (
select to_char(mtime, 'dd.mm.yyyy hh24:mi:ss'),
       hostname,
       round(sum(BYTESREADPERSEC) * 8 / 1024 / 1024 / 1024, 3)    as "READPERSEC_Gb",
       round(sum(BYTESWRITTENPERSEC) * 8 / 1024 / 1024 / 1024, 3) as "WRITTENPERSEC_Gb",
       round(sum(TRANSFERBW) * 8 / 1024 / 1024 / 1024, 3)         as "RW_Gb",
       round(avg(QUEUELEN))                                       as QUEUELEN,
       round(avg(utilization))                                    as utilization,
       round(avg(LATENCY))                                        as LATENCY,
       round(avg(servicetime))                                    as servicetime,
       round(avg(totalwaittime))                                  as waittime
 from CHM.CHMOS_DEVICE_INT_TBL
 where mtime between trunc(sysdate-1)+14/24 and trunc(sysdate-1)+20/24
--   and hostname = 'key-db2f'
 and devid like 'sd%5'
group by to_char(mtime, 'dd.mm.yyyy hh24:mi:ss'),
hostname
order by 6 desc
) where rownum <= 100


select to_char(mtime, 'dd.mm.yyyy hh24'),
       hostname,
       round(avg(BYTESREADPERSEC)    * 8 / 1024 / 1024) as "avg_READPERSEC_mb",
       round(avg(BYTESWRITTENPERSEC) * 8 / 1024 / 1024) as "avg_WRITTENPERSEC_mb",
       round(avg(TRANSFERBW)         * 8 / 1024 / 1024) as "avg_RW_mb",
       round(avg(QUEUELEN))                             as AVG_QUEUELEN,
       round(avg(THROUGHPUT))                           as AVG_THROUGHPUT
 from CHM.CHMOS_DEVICE_INT_TBL
where hostname = 'key-db2f'
and devid like 'sd%5'
and mtime between trunc(sysdate) - 8/24 and trunc(sysdate) + 8/24
group by to_char(mtime, 'dd.mm.yyyy hh24'), hostname
order by 1


--???
with w as
( select--+ materialize
               mtime,
               hostname,
               round(sum(BYTESREADPERSEC) * 8 / 1024 / 1024 / 1024, 3)    as READPERSEC_Gb,
               round(sum(BYTESWRITTENPERSEC) * 8 / 1024 / 1024 / 1024, 3) as WRITTENPERSEC_Gb,
               round(sum(TRANSFERBW) * 8 / 1024 / 1024 / 1024, 3)         as RW_Gb,
               round(avg(QUEUELEN))                                       as QUEUELEN,
               round(avg(utilization))                                    as utilization,
               round(avg(LATENCY))                                        as LATENCY,
               round(avg(servicetime)) as servicetime,
               round(avg(totalwaittime)) as waittime,
               avg(CPUUSERPERCENT / 100) as CPUUSERPERCENT,
               avg(CPUUSagePERCENT / 100) as CPUUSagePERCENT,
               avg(CPUIOWAITPERCENT / 100) as CPUIOWAITPERCENT,
               avg(NUMPROCSONCPU / 100) as NUMPROCSONCPU
          from CHM.CHMOS_DEVICE_INT_TBL
          join CHM.CHMOS_SYSTEM_SAMPLE_INT_TBL
         using (mtime, hostname)
         where mtime between trunc(sysdate - 1) + 14 / 24 and
               trunc(sysdate - 1) + 20 / 24
           and hostname = 'key-db2f'
           and devid like 'sd%5'
         group by mtime, hostname
--         order by 1
)
select trunc(mtime, 'mi') as mtime,
       hostname as host,
       round(avg(READPERSEC_Gb),2) as read_gb,
       round(avg(WRITTENPERSEC_Gb),2) as write_gb,
       round(avg(RW_Gb),2)            as RW_Gb,
       round(avg(QUEUELEN),2)         as IO_QUEUE,
       round(avg(utilization),2)      as io_util,
       round(avg(LATENCY),2)          as LATENCY,
       round(avg(servicetime),2)      as servicetime,
       round(avg(waittime),2)         as waittime,
       round(avg(CPUUSERPERCENT),2)   as "User%",
       round(avg(CPUUSagePERCENT),2)  as "Usage%",
       round(avg(CPUIOWAITPERCENT),2) as "IO%",
       round(avg(NUMPROCSONCPU),2)    as "ProcsOnCPU"
 from w
group by trunc(mtime, 'mi'), hostname
order by 1,2

select
    instance_number,
    snap_id as snap_id,
    to_char(end_interval_time, 'dd.mm.yyyy hh24:mi') as begin_interval_time,
    event_name,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits)
         END as AVG_WAIT_count,
    case WHEN (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) <= total_waits)
              THEN null
              ELSE round((LEAD(time_waited_micro,1) over (PARTITION BY instance_number ORDER BY snap_id) - time_waited_micro)
                        / (LEAD(total_waits,1) over (PARTITION BY instance_number ORDER BY snap_id) - total_waits))
         END as AVG_WAIT_TIME_nS
from cdb_hist_system_event hse
     join cdb_hist_snapshot sna using(snap_id, instance_number)
     where hse.event_name in ('library cache pin')
     and snap_id >= 27077
  order by end_interval_time desc, 1
/

select * from cdb_hist_system_event where snap_id = 27077
from dba_hist_system_event hse
     join dba_hist_snapshot sna using(snap_id, instance_number)
     where hse.event_name in ('library cache pin')
     and snap_id = 27077
