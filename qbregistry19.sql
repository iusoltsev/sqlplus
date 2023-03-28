rem
rem     Script:         qbregistry_query.sql
rem     Author:         Oracle Corp / Jonathan Lewis
rem     Dated:          Aug 2021
rem
rem     Last tested 
rem             19.10.0.0
rem
rem With additions for usability and 19c compatibility by Igor Usoltsev
rem @qbregistry_query.sql 0urb01mp7w5dq 123456
rem                       ^sql_id       ^phv
 
rem define m_sql_id='0urb01mp7w5dq'
rem define m_origin = 2

set pages 100 lines 100
col QBREG for a120
 
with query_block_origin as (select
 0 as ORIGIN_ID,                                           'NOT NAMED' as NAME, '' as HINT_TOKEN from dual union all select
 1, 'ALLOCATE',                                            '' from dual union all select
 2, 'PARSER',                                              '' from dual union all select
 3, 'HINT',                                                '' from dual union all select
 4, 'COPY',                                                '' from dual union all select
 5, 'SAVE',                                                '' from dual union all select
 6, 'MV REWRITE',                                          'REWRITE' from dual union all select
 7, 'PUSHED PREDICATE',                                    'PUSH_PRED' from dual union all select
 8, 'STAR TRANSFORM SUBQUERY',                             '' from dual union all select
 9, 'COMPLEX VIEW MERGE',                                  '' from dual union all select
10, 'COMPLEX SUBQUERY UNNEST',                             '' from dual union all select
11, 'OR EXPANSION',                                        'USE_CONCAT' from dual union all select
12, 'SUBQ INTO VIEW FOR COMPLEX UNNEST',                   '' from dual union all select
13, 'PROJECTION VIEW FOR CVM',                             '' from dual union all select
14, 'GROUPING SET TO UNION',                               '' from dual union all select
15, 'SPLIT/MERGE QUERY BLOCKS',                            '' from dual union all select
16, 'COPY PARTITION VIEW',                                 '' from dual union all select
17, 'RESTORE',                                             '' from dual union all select
18, 'VIEW MERGE',                                          'MERGE' from dual union all select
19, 'SUBQUERY UNNEST',                                     'UNNEST' from dual union all select
20, 'STAR TRANSFORM',                                      'STAR_TRANSFORMATION' from dual union all select
21, 'INDEX JOIN',                                          '' from dual union all select
22, 'STAR TRANSFORM TEMP TABLE',                           '' from dual union all select
23, 'MAP QUERY BLOCK',                                     '' from dual union all select
24, 'VIEW ADDED',                                          '' from dual union all select
25, 'SET QUERY BLOCK',                                     '' from dual union all select
26, 'QUERY BLOCK TABLES CHANGED',                          '' from dual union all select
27, 'QUERY BLOCK SIGNATURE CHANGED',                       '' from dual union all select
28, 'MV UNION QUERY BLOCK',                                '' from dual union all select
29, 'SPLIT QUERY BLOCK FOR GSET-TO-UNION',                 'EXPAND_GSET_TO_UNION' from dual union all select
30, 'PREDICATES REMOVED FROM QUERY BLOCK',                 'PULL_PRED' from dual union all select
31, 'PREDICATES ADDED TO QUERY BLOCK',                     '' from dual union all select
32, 'OLD PUSHED PREDICATE',                                'OLD_PUSH_PRED' from dual union all select
33, 'ORDER BY REMOVED FROM QUERY BLOCK',                   'ELIMINATE_OBY' from dual union all select
34, 'JOIN REMOVED FROM QUERY BLOCK',                       'ELIMINATE_JOIN' from dual union all select
35, 'OUTER-JOIN REMOVED FROM QUERY BLOCK',                 'OUTER_JOIN_TO_INNER' from dual union all select
36, 'STAR TRANSFORMATION JOINBACK ELIMINATION',            'ELIMINATE_JOIN' from dual union all select
37, 'BITMAP JOIN INDEX JOINBACK ELIMINATION',              'ELIMINATE_JOIN' from dual union all select
38, 'CONNECT BY COST BASED TRANSFORMATION',                'CONNECT_BY_COST_BASED' from dual union all select
39, 'CONNECT BY WITH FILTERING',                           'CONNECT_BY_FILTERING' from dual union all select
40, 'CONNECT BY WITH NO FILTERING',                        'NO_CONNECT_BY_FILTERING' from dual union all select
41, 'CONNECT BY START WITH QUERY BLOCK',                   '' from dual union all select
42, 'CONNECT BY FULL SCAN QUERY BLOCK',                    '' from dual union all select
43, 'PLACE GROUP BY',                                      'PLACE_GROUP_BY' from dual union all select
44, 'CONNECT BY NO FILTERING COMBINE',                     'NO_CONNECT_BY_FILTERING' from dual union all select
45, 'VIEW ON SELECT DISTINCT',                             '' from dual union all select
46, 'COALESCED SUBQUERY',                                  'COALESCE_SQ' from dual union all select
47, 'QUERY HAS COALESCED SUBQUERIES',                      'COALESCE_SQ' from dual union all select
48, 'SPLIT QUERY BLOCK FOR DISTINCT AGG OPTIM',            'TRANSFORM_DISTINCT_AGG' from dual union all select
49, 'CONNECT BY ELIMINATE DUPLICATES FROM INPUT',          'CONNECT_BY_ELIM_DUPS' from dual union all select
50, 'CONNECT BY COST BASED TRANSFORMATION FOR WHR ONLY',   'CONNECT_BY_CB_WHR_ONLY' from dual union all select
51, 'TABLE EXPANSION',                                     'EXPAND_TABLE' from dual union all select
52, 'TABLE EXPANSION BRANCH',                              '' from dual union all select
53, 'JOIN FACTORIZATION SET QUERY BLOCK',                  'FACTORIZE_JOIN' from dual union all select
54, 'DISTINCT PLACEMENT',                                  'PLACE_DISTINCT' from dual union all select
55, 'JOIN FACTORIZATION BRANCH QUERY BLOCK',               '' from dual union all select
56, 'TABLE LOOKUP BY NESTED LOOP QUERY BLOCK',             'TABLE_LOOKUP_BY_NL' from dual union all select
57, 'FULL OUTER JOIN TRANSFORMED TO OUTER',                'FULL_OUTER_JOIN_TO_OUTER' from dual union all select
58, 'LEFT OUTER JOIN TRANSFORMED TO ANTI',                 'OUTER_JOIN_TO_ANTI' from dual union all select
59, 'VIEW DECORRELATED',                                   'DECORRELATE' from dual union all select
60, 'QUERY VIEW DECORRELATED',                             'DECORRELATE' from dual union all select
61, 'NOT EXISTS SQ ADDED',                                 '' from dual union all select
62, 'BRANCH WITH OUTER JOIN',                              '' from dual union all select
63, 'BRANCH WITH ANTI JOIN',                               '' from dual union all select
64, 'UNION ALL FOR FULL OUTER JOIN',                       '' from dual union all select
65, 'VECTOR TRANSFORMATION',                               'VECTOR_TRANSFORM' from dual union all select
66, 'VECTOR TRANSFORMATION TEMP TABLE',                    '' from dual union all select
67, 'QUERY ANSI REARCHiTECTURE',                           'ANSI_REARCH' from dual union all select
68, 'VIEW ANSI REARCHiTECTURE',                            'ANSI_REARCH' from dual union all select
69, 'ELIMINATION OF GROUP BY',                             'ELIM_GROUPBY' from dual union all select
70, 'UAL BRANCH OF UNNESTED SUBQUERY',                     '' from dual union all select
71, 'QUERY BLOCK HAS BUSHY JOIN',                          'BUSHY_JOIN' from dual union all select
72, 'SUBQUERY ELIMINATE',                                  'ELIMINATE_SQ' from dual union all select
73, 'OR EXPANSION UNION ALL BRANCH',                       '' from dual union all select
74, 'OR EXPANSION UNION ALL VIEW',                         'OR_EXPAND' from dual union all select
75, 'DIST AGG GROUPING SETS UNION ALL TRANSFORMATION',     'USE_DAGG_UNION_ALL_GSETS' from dual union all select
76, 'MATERIALIZED WITH CLAUSE',                            '' from dual union all select
77, 'STATISTCS BASED TRANSFORMED QB',                      '' from dual union all select
78, 'PQ TABLE EXPANSION',                                  '' from dual union all select
79, 'LEFT OUTER JOIN TRANSFORMED TO BOTH INNER AND ANTI',  '' from dual union all select
80, 'SHARD TEMP TABLE',                                    '' from dual union all select
81, 'BRANCH OF COMPLEX UNNESTED SET QUERY BLOCK',          '' from dual union all select
82, 'DIST AGG GROUPING SETS OPTIMIZATION',                 'DAGG_OPTIM_GSETS' from dual),
--select * from query_block_origin
xml as (
        select  other_xml
        from    gV$sql_plan 
--        where   sql_id = '&m_sql_id' 
        where   sql_id = '&1' and plan_hash_value = &2
        and     id = 1
        and     other_xml is not null
and rownum <= 1
union all
        select  other_xml
        from    dba_hist_sql_plan
--        where   sql_id = '&m_sql_id' 
        where   sql_id = '&1' and plan_hash_value = &2
        and     id = 1
        and     other_xml is not null
and rownum <= 1
and not exists (select 1 from gV$sql_plan where sql_id = '&1' and plan_hash_value = &2)
)
--select * from xml
,
allqbs as ( 
        select 
                extractvalue(d.column_value, '/q/n')  qbname, 
                extractvalue(d.column_value, '/q/@f') final, 
                extractvalue(d.column_value, '/q/p')  prev, 
                extractvalue(d.column_value, '/q/@o') origin 
        from 
                table(xmlsequence(extract(xmltype ((select other_xml from xml)), '/other_xml/qb_registry/q'))) d 
), 
inpqbs as ( 
        select 
                xml.qbname qbname, 
                listagg(xml.depqbs, ',') within group (
                        order by xml.depqbs) depqbs 
        from 
                xmltable('/other_xml/qb_registry/q/i/o' passing xmltype((select other_xml from xml)) 
                        columns depqbs varchar2(256) path 'v', 
                        qbname varchar2(256) path './../../n'
                ) xml 
        where     xml.depqbs in ( select qbname from allqbs) 
        group by xml.qbname
), 
recqb   (src, origin, dest, final, lvl, inpobjs) as ( 
        select 
                qbname src, origin origin, null dest, final final, 1 lvl, null inpobjs 
        from 
                allqbs
        where 
--              origin = &m_origin
                origin in (2,3)
        union all 
        select 
                a.qbname src, a.origin origin, a.prev dest, a.final final, lvl+1, 
                (select depqbs from inpqbs i where i.qbname = a.qbname) inpobjs 
        from
                allqbs a, 
                recqb r 
        where a.prev = r.src
)
search depth first by src asc set ordseq, 
finalans as ( 
        select 
                src,
                (
                select 
                        name||' ('||HINT_TOKEN||')'
                from    query_block_origin--v$query_block_origin 
                where 
                        origin_id=origin
                )       origin, 
                dest, final, lvl, inpobjs 
        from recqb order by ordseq
) 
select
        /*+ opt_param('parallel_execution_enabled', 'false') */ 
        g.qbreg 
from (
        select 
                rpad(' ', 2*(lvl-1)) || 
                src || ' (' || origin || 
                        case when length(dest)>0 
                                then ' ' || dest 
                                else '' 
                        end || 
                        case when length(inpobjs)>0 
                                then ' ; ' || inpobjs 
                                else ' ' 
                        end ||
                        ')' || 
                        case when final='y' 
                                then ' [final]' 
                                else '' 
                        end 
                qbreg
        from 
                finalans
        ) g
/
