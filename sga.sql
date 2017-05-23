--
--Current instance SGA/Shared Pool info
--Usage:
--SQL> @sga
--

set feedback off heading on timi off pages 100 lines 200

col name format a40
col object_name format a100
col display_value format a20
col ASMM_Status format a11
col RESIZEABLE format a10
col DESCRIPTION format a60
col Status format a12

@@sysdate

select decode(value,0,'ASMM:off','ASMM:on') as ASMM_Status
from v$parameter
where name in 'sga_target'
/
PROMPT
PROMPT
PROMPT SGA Parameters
COLUMN NAME HEADING 'Parameters'
select name, round(value/1024/1024) as MB, display_value, DESCRIPTION
from v$parameter
where (
name in ('sga_max_size','','sga_target','shared_pool_size')
or name like 'db%cache_size'
or name like '%pool_size')
and name not in 'global_context_pool_size'
order by to_number(value) desc, name
/
PROMPT
PROMPT
PROMPT SGAINFO
COLUMN NAME HEADING 'SGA Info'
select name, round(bytes/1024/1024) as MB, RESIZEABLE from v$sgainfo order by bytes desc
/
PROMPT
PROMPT
PROMPT Shared Pool Components - TOP10
COLUMN NAME HEADING 'Shared Pool Components'
select * from (
select name, round(bytes/1024/1024) as MB
from v$sgastat
where pool = 'shared pool'
order by BYTES desc
) where rownum <= 10
/

PROMPT
PROMPT
PROMPT Shared Pool Cache Top 10

select *
  from (select hash_value,
               substr(name, 1, 100) as object_name,
               namespace,
               type,
               kept,
--               status,
               count(*),
               min(timestamp),
               sum(locked_total),
               sum(pinned_total),
               sum(loads),
               sum(executions),
               sum(sharable_mem)
          from v$db_object_cache
         group by hash_value,
                  substr(name, 1, 100),
                  namespace,
                  type,
                  kept
--                 ,status
         order by sum(sharable_mem) desc)
 where rownum <= 10
/
select *
  from (select sql_id,
               substr(sql_text, 1, 100) as object_name,
               version_count,
               executions,
               loads,
               first_load_time,
               parse_calls,
               sharable_mem,
               persistent_mem,
               runtime_mem
          from v$sqlarea
         order by sharable_mem desc)
 where rownum <= 10
/
PROMPT
PROMPT
PROMPT SGA Resize Ops

col sga_parameter head PARAMETER for a30
col sga_component head COMPONENT for a30
col initial_size for 999,999,999,999
col target_size for 999,999,999,999
col final_size for 999,999,999,999

select * from (
SELECT
    component as sga_component
  , oper_type
  , oper_mode
  , parameter as sga_parameter
  , initial_size
  , target_size
  , final_size
  , status
  , to_char(start_time,'dd.mm.yyyy hh24:mi:ss') as start_time
  , to_char(end_time,'dd.mm.yyyy hh24:mi:ss') as end_time
FROM v$sga_resize_ops
ORDER BY start_time desc
) where rownum <= 20
ORDER BY start_time
/

rem sga+
rem http://blog.tanelpoder.com/2009/06/04/ora-04031-errors-and-monitoring-shared-pool-subpool-memory-utilization-with-sgastatxsql/

PROMPT Shared Pool Subpool distribution:

SELECT
    'shared pool ('||NVL(DECODE(TO_CHAR(ksmdsidx),'0','0 - Unused',ksmdsidx), 'Total')||'):'  subpool
  , SUM(ksmsslen) bytes
  , ROUND(SUM(ksmsslen)/1048576,2) MB
FROM x$ksmss
WHERE ksmsslen > 0
GROUP BY ROLLUP ( ksmdsidx )
ORDER BY subpool ASC
/

/*
SELECT 
    subpool
  , name
  , SUM(bytes)                  
  , ROUND(SUM(bytes)/1048576,2) MB
FROM (
    SELECT
        'shared pool ('||DECODE(TO_CHAR(ksmdsidx),'0','0 - Unused',ksmdsidx)||'):'      subpool
      , ksmssnam      name
      , ksmsslen      bytes
    FROM 
        x$ksmss
    WHERE
        ksmsslen > 0
    AND LOWER(ksmssnam) LIKE LOWER('%&1%')
)
GROUP BY
    subpool
  , name
ORDER BY
    subpool    ASC
  , SUM(bytes) DESC
/

--Diagnosing and Resolving Error ORA-04031 on the Shared Pool or Other Memory Pools [Video] [ID 146599.1]

SELECT KSMCHIDX subpool,
       KSMCHDUR,
'sga heap('||KSMCHIDX||','||to_char(KSMCHDUR-1)||')' as "sga heap",
       KSMCHCLS CLASS,
       COUNT(KSMCHCLS) NUM,
       SUM(KSMCHSIZ) SIZ,
       To_char(((SUM(KSMCHSIZ) / COUNT(KSMCHCLS) / 1024)), '999,999.00') || 'k' "AVG SIZE",
       To_char(((MIN(KSMCHSIZ))), '999,999,999') || 'bytes' "MIN SIZE",
       To_char(((MAX(KSMCHSIZ))), '999,999,999') || 'bytes' "MAX SIZE"
  FROM X$KSMSP
 GROUP BY KSMCHIDX,
          KSMCHDUR,
          KSMCHCLS
 order by KSMCHIDX,
          KSMCHDUR,
          KSMCHCLS
/
select '0 (<140)' BUCKET, KSMCHCLS, KSMCHIDX, 10*trunc(KSMCHSIZ/10) "From",
count(*) "Count" , max(KSMCHSIZ) "Biggest",
trunc(avg(KSMCHSIZ)) "AvgSize", trunc(sum(KSMCHSIZ)) "Total"
from x$ksmsp
where KSMCHSIZ<140
and KSMCHCLS='free'
group by KSMCHCLS, KSMCHIDX, 10*trunc(KSMCHSIZ/10)
UNION ALL
select '1 (140-267)' BUCKET, KSMCHCLS, KSMCHIDX,20*trunc(KSMCHSIZ/20) ,
count(*) , max(KSMCHSIZ) ,
trunc(avg(KSMCHSIZ)) "AvgSize", trunc(sum(KSMCHSIZ)) "Total"
from x$ksmsp
where KSMCHSIZ between 140 and 267
and KSMCHCLS='free'
group by KSMCHCLS, KSMCHIDX, 20*trunc(KSMCHSIZ/20)
UNION ALL
select '2 (268-523)' BUCKET, KSMCHCLS, KSMCHIDX, 50*trunc(KSMCHSIZ/50) ,
count(*) , max(KSMCHSIZ) ,
trunc(avg(KSMCHSIZ)) "AvgSize", trunc(sum(KSMCHSIZ)) "Total"
from x$ksmsp
where KSMCHSIZ between 268 and 523
and KSMCHCLS='free'
group by KSMCHCLS, KSMCHIDX, 50*trunc(KSMCHSIZ/50)
UNION ALL
select '3-5 (524-4107)' BUCKET, KSMCHCLS, KSMCHIDX, 500*trunc(KSMCHSIZ/500) ,
count(*) , max(KSMCHSIZ) ,
trunc(avg(KSMCHSIZ)) "AvgSize", trunc(sum(KSMCHSIZ)) "Total"
from x$ksmsp
where KSMCHSIZ between 524 and 4107
and KSMCHCLS='free'
group by KSMCHCLS, KSMCHIDX, 500*trunc(KSMCHSIZ/500)
UNION ALL
select '6+ (4108+)' BUCKET, KSMCHCLS, KSMCHIDX, 1000*trunc(KSMCHSIZ/1000) ,
count(*) , max(KSMCHSIZ) ,
trunc(avg(KSMCHSIZ)) "AvgSize", trunc(sum(KSMCHSIZ)) "Total"
from x$ksmsp
where KSMCHSIZ >= 4108
and KSMCHCLS='free'
group by KSMCHCLS, KSMCHIDX, 1000*trunc(KSMCHSIZ/1000);
/
*/
set feedback on