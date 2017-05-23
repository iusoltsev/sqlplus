--
-- ASH I/O waits for phys.stby MOUNTED instance
-- Usage: SQL> @ash_io_waitsby [waits|reqs|blocks] [10]        "sample_time > sysdate - 1/24"
--                            ^sort order         ^top N rows  ^ash filter(REQUIRED!)
-- by Igor Usoltsev
--

set echo off feedback off heading on timi off pages 1000 lines 500 VERIFY OFF

col SQL_PROCESS for a13
col "event(waits:requests:blocks)" for a500
col "waits%"  for a7
col "reqs%"   for a7
col "blocks%" for a7
col inst_id for 9999 hea #i
col PROGRAMS for a60 HEADING 'PROGRAMS BY TYPES                                           '
col t0 for 999

select * from (
    select inst_id,
           SQL_PROCESS,
           SUM(WAIT_COUNT),
           to_char(RATIO_TO_REPORT(SUM(WAIT_COUNT)) OVER() * 100, '990.99') AS "waits%",
           SUM(REQUESTS),
           to_char(RATIO_TO_REPORT(SUM(REQUESTS)) OVER()   * 100, '990.99') AS "reqs%",
           SUM(BLOCKS),
           to_char(RATIO_TO_REPORT(SUM(BLOCKS)) OVER()     * 100, '990.99') AS "blocks%"
          ,decode(nvl(upper('&&1'), 'BLOCKS') -- listagg from ORA-00600: internal error code, arguments: [qmxtcsxmlt:xmltype]
                                  , 'WAITS' , listagg( EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ') WITHIN GROUP (order by WAIT_COUNT desc) || ')'
                                  , 'REQS'  , listagg( EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ') WITHIN GROUP (order by REQUESTS   desc) || ')'
                                  , 'BLOCKS', listagg( EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ') WITHIN GROUP (order by BLOCKS     desc) || ')'
                                            , listagg( EVENT || '(' || WAIT_COUNT||':'|| REQUESTS ||':'|| BLOCKS, '); ') WITHIN GROUP (order by BLOCKS     desc) || ')')
            as "event(waits:requests:blocks)"
      from (select inst_id,
                   SQL_PROCESS,
                   event,
                   sum(WAIT_COUNT)                   as WAIT_COUNT,
                   sum(WAIT_COUNT * REQS_PER_WAIT)   as REQUESTS,
                   round(sum(WAIT_COUNT * BLOCKS_PER_WAIT) / case when event like 'log file%'     then (select value / (select max(blocksize) from v$log) as ratio from v$parameter where name = 'db_block_size')
                                                                  when event like 'control file%' then (select value / (select max(block_size) from v$controlfile) as ratio from v$parameter where name = 'db_block_size')
                                                                  else 1 end) as BLOCKS
              from (select count(*) as WAIT_COUNT,
                           nvl(sql_id,case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
                                           when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
                                           when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
                                           when REGEXP_INSTR(program, '\(PR..\)')     > 0 then '(PR..)'
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
                           inst_id
                      from gv$active_session_history ash
                     where 
                        wait_class in ('User I/O','System I/O') and
                        session_state = 'WAITING'
                        and &3
                     group by nvl(sql_id,case when REGEXP_INSTR(program, '\([A-Z]...\)') = 0 then '(USER)'
                                         when REGEXP_INSTR(program, '\(ARC.\)')     > 0 then '(ARC.)'
                                         when REGEXP_INSTR(program, '\(O...\)')     > 0 then '(O...)'
                                         when REGEXP_INSTR(program, '\(PR..\)')     > 0 then '(PR..)'
                                         when REGEXP_INSTR(program, '\(P...\)')     > 0 then '(P...)'
                                         else REGEXP_REPLACE(REGEXP_SUBSTR(program, '\([^\)]+\)'), '([[:digit:]])', '.')
                                         end),
                              event,
                              case when p2text = 'blocks' then p2
                                   when p3text in ('blocks','block cnt') then p3
                                   when p1text = 'requests' then p1  
                                   else 1
                              end,
                              case when p3text='requests' then p3 when p1text='requests' then p1 else 1 end,
                              inst_id)
             group by inst_id,
                      SQL_PROCESS,
                      event
                      )
     group by inst_id, SQL_PROCESS
     order by decode(nvl(upper('&&1'),'BLOCKS'), 'WAITS', SUM(WAIT_COUNT), 'REQS', SUM(REQUESTS), 'BLOCKS', SUM(BLOCKS), SUM(BLOCKS)) desc
) where rownum <= nvl('&2', 10)
/
set feedback on echo off VERIFY ON
