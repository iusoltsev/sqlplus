--
-- ASH I/O waits
-- Usage: SQL> @ash_io_waits_temp [waits|reqs|blocks] [10]         "and sample_time > sysdate - 1/24"
--                            ^sort order         ^top N rows  ^ash filter
-- by Igor Usoltsev
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col SQL_PROCESS for a13
col "event(waits:requests:blocks)" for a300
col "waits%"  for a7
col "reqs%"   for a7
col "blocks%" for a7
col inst_id for 9999 hea #i
col PROGRAMS for a60 HEADING 'PROGRAMS BY TYPES                                           '
col t0 for 999
col MIN_SAMPLE_TIME for a22
col MAX_SAMPLE_TIME for a22

with ash as (select * from system.ash_290317_tmp where &3)
, log_block as (select value / (select max(blocksize) from v$log) as ratio from v$parameter where name = 'db_block_size')
select * from (
    select --inst_id,
           SQL_PROCESS,
           SUM(WAIT_COUNT),
           to_char(RATIO_TO_REPORT(SUM(WAIT_COUNT)) OVER() * 100, '990.99') AS "waits%",
           SUM(REQUESTS),
           to_char(RATIO_TO_REPORT(SUM(REQUESTS)) OVER()   * 100, '990.99') AS "reqs%",
           SUM(BLOCKS),
           to_char(RATIO_TO_REPORT(SUM(BLOCKS)) OVER()     * 100, '990.99') AS "blocks%",
           decode(nvl(upper('&&1'), 'BLOCKS')
                                  , 'WAITS' , rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ').extract('//text()') order by WAIT_COUNT desc), '; ')
                                  , 'REQS'  , rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ').extract('//text()') order by REQUESTS desc), '; ')
                                  , 'BLOCKS', rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ').extract('//text()') order by BLOCKS desc), '; ')
                                            , rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ').extract('//text()') order by BLOCKS desc), '; '))
--           rtrim(xmlagg(xmlelement(s, EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ').extract('//text()') order by WAIT_COUNT desc), '; ')
            as "event(waits:requests:blocks)"
--,
--            EXECS,          
--            MIN_SAMPLE_TIME,
--            MAX_SAMPLE_TIME 
      from (select --inst_id,
                   SQL_PROCESS,
                   event,
                   sum(WAIT_COUNT)                   as WAIT_COUNT,
                   sum(WAIT_COUNT * REQS_PER_WAIT)   as REQUESTS,
                   round(sum(WAIT_COUNT * BLOCKS_PER_WAIT) / decode(substr(event, 1, 8), 'log file', log_block.ratio, 1)) as BLOCKS
--,
--                   EXECS,          
--                   MIN_SAMPLE_TIME,
--                   MAX_SAMPLE_TIME 
              from (select count(*) as WAIT_COUNT,
                           nvl(sql_id,case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
                                           when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
                                           when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
                                           when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
                                           else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
                                           end) as SQL_PROCESS,
                           event,
                           case when p2text = 'blocks' then p2
                                when p3text in ('blocks','block cnt') then p3
                                when p1text = 'requests' then p1  
                                else 1
                           end                                                                                            as BLOCKS_PER_WAIT,
                           case when p3text='requests' then p3 when p1text='requests' then p1 else 1 end                  as REQS_PER_WAIT,
                           --inst_id,
                           count(distinct sql_exec_id)                                                                    as EXECS,
                           to_char(min(SAMPLE_TIME),'DD.MM.YYYY HH24:MI:SS')                                              as MIN_SAMPLE_TIME,
                           to_char(max(SAMPLE_TIME),'DD.MM.YYYY HH24:MI:SS')                                              as MAX_SAMPLE_TIME
                      from ash --Gv$active_session_history--
                     where 
                        wait_class in ('User I/O','System I/O') and
                        session_state = 'WAITING'
                     group by nvl(sql_id,case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
                                         when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
                                         when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
                                         when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
                                         else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
                                         end),
                              event,
                              case when p2text = 'blocks' then p2
                                   when p3text in ('blocks','block cnt') then p3
                                   when p1text = 'requests' then p1  
                                   else 1
                              end,
                              case when p3text='requests' then p3 when p1text='requests' then p1 else 1 end
                              --, inst_id
)
                 , log_block
             group by --inst_id,
                      SQL_PROCESS,
                      event,
                      log_block.ratio
--,
--                      EXECS,                                
--                      MIN_SAMPLE_TIME,
--                      MAX_SAMPLE_TIME
             )
     group by --inst_id,
              SQL_PROCESS
--, EXECS, MIN_SAMPLE_TIME, MAX_SAMPLE_TIME
     order by decode(nvl(upper('&&1'),'BLOCKS'), 'WAITS', SUM(WAIT_COUNT), 'REQS', SUM(REQUESTS), 'BLOCKS', SUM(BLOCKS), SUM(BLOCKS)) desc
) where rownum <= nvl('&2', 10)
/
set feedback on echo off VERIFY ON
