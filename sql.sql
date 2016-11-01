col sql_text for a60
select s.PREV_SQL_ID as SQL_ID,
       s.PREV_CHILD_NUMBER as CHILD,
       prev_c.SQL_TEXT
  from v$session s, v$sql prev_c
 where s.SID = sys_context('userenv', 'sid')
   and s.PREV_SQL_ID = prev_c.SQL_ID
   and s.PREV_CHILD_NUMBER = prev_c.CHILD_NUMBER
/