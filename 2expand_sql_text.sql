--Расскрыть SQL обращения к вьюшкам

SET SERVEROUTPUT ON 
DECLARE
  l_clob CLOB;
BEGIN
  DBMS_UTILITY.expand_sql_text (
    input_sql_text  => '&1',
    output_sql_text => l_clob
  );
  DBMS_OUTPUT.put_line(l_clob);
END;
/