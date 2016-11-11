col KGLNAOBJ for a100
col SQL_TEXT for a100

select --+ ordered
       l.kgllkhdl     as HANDLER,
       l.kgllktype,
       w.kglhdnsd     as NAMESP,
       w.kglobtyd,
       w.kglnaown,
--       dbms_lob.substr(w.kglnaobj,100) as kglnaobj,
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
       substr(nvl(a.sql_text,kglnaobj),1,100) as sql_text
  from (select * from v$session where sid = &1) s
       join dba_kgllock l    on l.kgllkuse = s.saddr
       left join x$kglob w   on l.kgllkhdl = w.kglhdadr
       left join v$sqlarea a on s.sql_address    = a.address
                            and s.sql_hash_value = a.hash_value
 where nvl('&2',w.kglhdnsd) = w.kglhdnsd
order by l.kgllkhdl, s.seconds_in_wait desc, l.kgllktype
/
