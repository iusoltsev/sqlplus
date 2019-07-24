-- For SQL Developer only!!!
declare
    cursor_name INTEGER;
    rows_processed INTEGER;
    sql_text    VARCHAR2(32000) := '
...';
BEGIN
    cursor_name := dbms_sql.open_cursor;
    DBMS_SQL.PARSE(cursor_name, sql_text--'select sysdate from dual'
  , DBMS_SQL.NATIVE);
--    DBMS_SQL.BIND_VARIABLE(cursor_name, ':x', salary);
    rows_processed := DBMS_SQL.EXECUTE(cursor_name);
    DBMS_SQL.CLOSE_CURSOR(cursor_name);
EXCEPTION
WHEN OTHERS THEN raise;
   -- DBMS_SQL.CLOSE_CURSOR(cursor_name);
END;
/
