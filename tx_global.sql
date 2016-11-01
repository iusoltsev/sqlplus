--
--Global Transaction info, based on 
--Script to show Active Distributed Transactions (Doc ID 104420.1)
--https://support.oracle.com/epmos/faces/DocContentDisplay?id=104420.1
--Oracle Server, 7.3.x to 12.1
--https://github.com/xtender/xt_scripts/blob/master/transactions/global.sql
--

set feedback off
column "ORIGIN/GTX_INIT_PROC" format a20
column "FROM_DB.GTXID" format a64
column LSESSION format a10
column STATE format a8
column waiting format a60

/* --original
Select --+ ORDERED
    substr(s.ksusemnm,1,10)||'-'|| substr(s.ksusepid,1,10) "ORIGIN",
    substr(g.K2GTITID_ORA,1,35) "GTXID",
    substr(s.indx,1,4)||'.'|| substr(s.ksuseser,1,5) "LSESSION" ,
    substr(decode(bitand(ksuseidl,11),
               1,'ACTIVE',
               0, decode(bitand(ksuseflg,4096),0,'INACTIVE','CACHED'),
               2,'SNIPED',
               3,'SNIPED', 'KILLED'),1,1) "S",
    event "WAITING"
from  x$k2gte g, x$ktcxb t, x$ksuse s, v$session_wait w
-- where  g.K2GTeXCB =t.ktcxbxba <= use this if running in Oracle7
where  g.K2GTDXCB =t.ktcxbxba -- comment out if running in Oracle8 or later
   and g.K2GTDSES=t.ktcxbses
   and s.addr=g.K2GTDSES
   and w.sid=s.indx;
*/

Select --+ ORDERED
    substr(s.ksusemnm,1,10)||'-'|| substr(s.ksusepid,1,10) "ORIGIN/GTX_INIT_PROC",
    g.K2GTITID_ORA                                         "FROM_DB.GTXID",
    to_number(hextoraw(reverse(regexp_replace(g.k2gtitid_ora,'^(.*)\.(\w+)\.(\d+\.\d+\.\d+)$','\2'))),'XXXXXXXXXXXX') "FROM_DBID",
    nvl2(replace(g.k2gtibid,'0'),'FROM REMOTE','TO REMOTE') DIRECTION,
    substr(s.indx,1,4)||'.'|| substr(s.ksuseser,1,5)       "LSESSION",
    to_char(KSUSELTM,'dd.mm.yyyy hh24:mi:ss')              "LOGON_TIME",
    t.ktcxbstm                                             "TX_STIME",
    to_char(KSUSEPESTA,'dd.mm.yyyy hh24:mi:ss')            "SQL_STIME",
    decode(bitand(ksuseidl,11),
           1,'ACTIVE',
           0, decode(bitand(ksuseflg,4096),0,'INACTIVE','CACHED'),
           2,'SNIPED',
           3,'SNIPED', 'KILLED')                           "STATE",
   (select name from v$event_name where event#=s.ksuseopc) "EVENT",
    s.ksusewtm                                             "WAIT_TIME",
--    decode(state, 'WAITING', EVENT, 'On CPU / runqueue')   "WAITING",
    s.ksusesqi                                             "SQL",
    s.ksusepsi                                             "PREV_SQL",
    s.ksuudnam                                             "USERNAME",
    s.ksusemnm                                             "MACHIME",
    s.ksusepnm                                             "PROGRAM",
    s.ksuseapp                                             "MODULE",
    t.ktcxbxid                                             "XID"
from  x$k2gte g,
      x$ktcxb t,
      x$ksuse s
where  g.K2GTDXCB = t.ktcxbxba
   and g.K2GTDSES = t.ktcxbses
   and s.addr     = g.K2GTDSES
/
REM distri_details.sql
set headin off
select /*+ ORDERED */
'--------------------------------------------------------------------------------'||'
Curent Time : '|| substr(to_char(sysdate,'dd-Mon-YYYY HH24.MI.SS'),1,22) ||'
'||'GTXID='||substr(g.K2GTITID_EXT,1,10) ||'
'||'Ascii GTXID='||g.K2GTITID_ORA ||'
'||'Branch = '||g.K2GTIBID||' = "'||decode(g.K2GTIBID,'0000','',UTL_I18N.RAW_TO_CHAR(g.K2GTIBID))||'"'||'
Client Process ID is '|| substr(s.ksusepid,1,10)||'
running in machine : '||substr(s.ksusemnm,1,80)||'
  Local TX Id  ='||substr(t.KXIDUSN||'.'||t.kXIDSLT||'.'||t.kXIDSQN,1,10) ||'
  Local Session SID.SERIAL ='||substr(s.indx,1,4)||'.'|| s.ksuseser ||'
  is : '||decode(bitand(ksuseidl,11),1,'ACTIVE',0,
          decode(bitand(ksuseflg,4096),0,'INACTIVE','CACHED'),
          2,'SNIPED',3,'SNIPED', 'KILLED') ||
  ' and '|| substr(STATE,1,9)||
  ' since '|| to_char(SECONDS_IN_WAIT,'9999')||' seconds' ||'
  Wait Event is :'||'
  '||  substr(event,1,30)||' '||p1text||'='||p1
        ||','||p2text||'='||p2
        ||','||p3text||'='||p3    ||'
  Waited '||to_char(SEQ#,'99999')||' times '||'
  Server for this session:' ||decode(s.ksspatyp,1,'Dedicated Server',
                                                2,'Shared Server',
                                                3,'PSE',
                                                  'None') "Server"
from  x$k2gte g, x$ktcxb t, x$ksuse s, v$session_wait w
-- where  g.K2GTeXCB =t.ktcxbxba <= use this if running Oracle7
where  g.K2GTDXCB =t.ktcxbxba -- comment out if running Oracle8 or later
   and  g.K2GTDSES=t.ktcxbses
   and  s.addr=g.K2GTDSES
   and  w.sid=s.indx;

set headin on
set feedback on