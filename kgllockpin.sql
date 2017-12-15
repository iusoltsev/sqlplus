set feedback off heading on timi off pages 100 lines 800 echo off  VERIFY OFF

col HANDLER 		for	a16
col NAMESP		for	a30
col kglobtyd 		for	a30
col kglnaown 		for 	a30
col kglnaobj 		for 	a30
col kgllktype 		for 	a10
col mode_held 		for 	a10
col mode_req 		for 	a10
col secs_in_wait 	for 	a12
col event 		for 	a40
col sid 		for 	a6
col serial 		for 	a7
col program 		for 	a44
col sql_text 		for 	a100
COL SQL4REMOTE_INST HEADING "SQL for executing on other instances:" FORMAT A150
col sql_exec_start      for     a15

select --+ ordered
       to_char(s.sql_exec_start,'mm/dd hh24:mi:ss') as sql_exec_start,
       b.p1raw     as HANDLER,
       l.kgllktype,
       w.kglhdnsd  as NAMESP,
       w.kglobtyd,
       w.kglnaown,
       w.kglnaobj,
       decode(l.kgllkmod, 0, 'None', 1, 'Null', 2, 'Share', 3, 'Exclusive', 'Unknown') mode_held,
       decode(l.kgllkreq, 0, 'None', 1, 'Null', 2, 'Share', 3, 'Exclusive', 'Unknown') mode_req,
       to_char(s.seconds_in_wait) as secs_in_wait,
       s.event,
       s.seconds_in_wait,
       s.client_identifier,
       to_char(s.sid) as sid,
       to_char(s.serial#) as serial,
       s.saddr,
       s.program,
       a.sql_id,
       substr(a.sql_text,1,100) as sql_text
  from (select distinct p1raw from v$session where state = 'WAITING' and event in ('library cache lock', 'library cache pin')) b
       join dba_kgllock l    on l.kgllkhdl = b.p1raw -- this is LOCAL view ONLY
       join v$session s      on l.kgllkuse = s.saddr
       left join x$kglob w   on l.kgllkhdl = w.kglhdadr
       left join v$sqlarea a on s.sql_address    = a.address
                            and s.sql_hash_value = a.hash_value
order by
-- to_char(s.sql_exec_start,'mm/dd hh24:mi:ss'), l.kgllkhdl, s.seconds_in_wait desc, l.kgllktype
KGLNAOWN, KGLNAOBJ, MODE_HELD,  MODE_REQ
/
prompt
prompt
prompt SQL for executing on other instances:
/*
select --+ ordered
       distinct
       'select /+ ordered /'
       ||chr(13)||chr(10)||'     w.kglhdadr   as HANDLER,'
       ||chr(13)||chr(10)||'     l.kgllktype,'
       ||chr(13)||chr(10)||'     w.kglhdnsd   as NAMESP,'
       ||chr(13)||chr(10)||'     w.kglobtyd,'
       ||chr(13)||chr(10)||'     w.kglnaown,'
       ||chr(13)||chr(10)||'     w.kglnaobj,'
       ||chr(13)||chr(10)||'     decode(l.kgllkmod, 0, ''None'', 1, ''Null'', 2, ''Share'', 3, ''Exclusive'', ''Unknown'') mode_held,'
       ||chr(13)||chr(10)||'     decode(l.kgllkreq, 0, ''None'', 1, ''Null'', 2, ''Share'', 3, ''Exclusive'', ''Unknown'') mode_req,'
       ||chr(13)||chr(10)||'     to_char(s.seconds_in_wait) as secs_in_wait,'
       ||chr(13)||chr(10)||'     s.event,'
       ||chr(13)||chr(10)||'     s.seconds_in_wait,'
       ||chr(13)||chr(10)||'     s.client_identifier,'
       ||chr(13)||chr(10)||'     to_char(s.sid) as sid,'
       ||chr(13)||chr(10)||'     to_char(s.serial#) as serial,'
       ||chr(13)||chr(10)||'     s.saddr,'
       ||chr(13)||chr(10)||'     s.program,'
       ||chr(13)||chr(10)||'     a.sql_id,'
       ||chr(13)||chr(10)||'     substr(a.sql_text,1,100) as sql_text'
       ||chr(13)||chr(10)||' from x$kglob w'
       ||chr(13)||chr(10)||' join dba_kgllock l on l.kgllkhdl = w.kglhdadr'
       ||chr(13)||chr(10)||' join v$session s   on l.kgllkuse = s.saddr'
       ||chr(13)||chr(10)||' left join v$sqlarea a on s.sql_address = a.address'
       ||chr(13)||chr(10)||'                     and s.sql_hash_value = a.hash_value'
       ||chr(13)||chr(10)||' where (kglhdnsd,kglobtyd,kglnaown,kglnaobj) in (('''
       || w.kglhdnsd || ''','''|| w.kglobtyd || ''','''|| w.kglnaown || ''','''|| w.kglnaobj || '''))'
       ||chr(13)||chr(10)||chr(47)
    as SQL4REMOTE_INST
  from (select distinct p1raw from v$session where state = 'WAITING' and event in ('library cache lock', 'library cache pin')) b
       join dba_kgllock l  on l.kgllkhdl = b.p1raw -- this is LOCAL view ONLY
       left join x$kglob w on l.kgllkhdl = w.kglhdadr
*/
rem @@mutex_waits
set feedback on VERIFY ON timi on