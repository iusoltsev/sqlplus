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
declare
  l_theCursor integer default dbms_sql.open_cursor;
  l_status        integer default -1 ;
  v_sqltext       varchar2(32000);
  rows_processed  integer;
  l_clob CLOB;
  l_long LONG;
  l_sign number;
begin
     begin
       l_status := -2;
       select dbms_lob.substr(sql_text,10000), sql_text into v_sqltext, l_clob from dba_hist_sqltext where sql_id in ('bxmkjvrkn27gm');--('cg5t4436jdmzr');--
l_sign := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(l_clob,false);
dbms_output.put_line(to_char(l_sign));
l_sign := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(l_clob,true);
dbms_output.put_line(to_char(l_sign)||': FORCE');
       dbms_output.put_line(l_clob);
l_sign := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(v_sqltext,false);
dbms_output.put_line(to_char(l_sign));
l_sign := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(v_sqltext,true);
dbms_output.put_line(to_char(l_sign)||': FORCE');
       dbms_output.put_line(v_sqltext);
       dbms_sql.parse(l_theCursor, l_clob,    dbms_sql.native);
       dbms_sql.parse(l_theCursor, v_sqltext, dbms_sql.native);
--    rows_processed := DBMS_SQL.EXECUTE(l_theCursor);
--           DBMS_SQL.CLOSE_CURSOR(l_theCursor);
     exception
          when others then raise;
--            then l_status := dbms_sql.last_error_position;
          end;
--     dbms_sql.close_cursor( l_theCursor );
end;
/
alter session set current_schema=b
/
insert into system.Temp_Adg_Sqltext select sql_id, sql_fulltext from gv$sql@b_ro.x.ru where sql_id = '37s5a8jaqtctm' and rownum <= 1
/
alter session set events 'trace [rdbms.SQL_Compiler.*][sql:37s5a8jaqtctm]';
declare
  l_theCursor integer default dbms_sql.open_cursor;
  l_status        integer default -1 ;
  v_sqltext       varchar2(32000);
  l_n_rowcount    NUMBER;
  l_vc_inn        VARCHAR2(128) := '5263091014';
  l_vc_fetch      number        := 10;
id number;
kpp VARCHAR2(128);
v_type VARCHAR2(128);
is_partner number;
name VARCHAR2(128);
client_id number;
client_name VARCHAR2(128);
email VARCHAR2(128);
inn VARCHAR2(128);
invoice_count number;
hidden number;
begin
     begin
       l_status := -2;
       select dbms_lob.substr(sql_fulltext,32000) into v_sqltext from v$sqlarea where sql_id = '37s5a8jaqtctm';
--       select dbms_lob.substr(sql_fulltext,32000) into v_sqltext from system.Temp_Adg_Sqltext where sql_id = '37s5a8jaqtctm';
       dbms_sql.parse(l_theCursor, v_sqltext, dbms_sql.native);
dbms_sql.define_column(l_theCursor,1,id);
dbms_sql.define_column(l_theCursor,2,kpp,128);
dbms_sql.define_column(l_theCursor,3,v_type,128);
dbms_sql.define_column(l_theCursor,4,is_partner);
dbms_sql.define_column(l_theCursor,5,name,128);
dbms_sql.define_column(l_theCursor,6,client_id);
dbms_sql.define_column(l_theCursor,7,client_name,128);
dbms_sql.define_column(l_theCursor,8,email,128);
dbms_sql.define_column(l_theCursor,9,inn,128);
dbms_sql.define_column(l_theCursor,10,invoice_count);
dbms_sql.define_column(l_theCursor,11,hidden);
       DBMS_SQL.BIND_VARIABLE(l_theCursor, ':inn', l_vc_inn);
       DBMS_SQL.BIND_VARIABLE(l_theCursor, ':fetch', l_vc_fetch);
--       l_n_rowcount:=dbms_sql.execute(l_theCursor);
       l_n_rowcount:=dbms_sql.execute_and_fetch(l_theCursor);
         LOOP EXIT WHEN dbms_sql.fetch_rows(l_theCursor)=0;
dbms_sql.column_value(l_theCursor,1,id);
dbms_sql.column_value(l_theCursor,2,kpp);
dbms_sql.column_value(l_theCursor,3,v_type);
dbms_sql.column_value(l_theCursor,4,is_partner);
dbms_sql.column_value(l_theCursor,5,name);
dbms_sql.column_value(l_theCursor,6,client_id);
dbms_sql.column_value(l_theCursor,7,client_name);
dbms_sql.column_value(l_theCursor,8,email);
dbms_sql.column_value(l_theCursor,9,inn);
dbms_sql.column_value(l_theCursor,10,invoice_count);
dbms_sql.column_value(l_theCursor,11,hidden);
         END LOOP;
dbms_sql.close_cursor( l_theCursor );
     exception
          when others then raise;
--            then l_status := dbms_sql.last_error_position;
--     dbms_sql.close_cursor( l_theCursor );
          end;
end;
/

SQL> create global temporary table system.temp_adg_sqltext(sql_id char(13),sql_fulltext clob);

SQL> insert into system.temp_adg_sqltext(sql_id,sql_fulltext) select sql_id, sql_fulltext from gv$sqlarea@balance_ro.yandex.ru where sql_id = '6h35dn6j9m4u8' and rownum <= 1;

1 row inserted

declare
   l_theCursor integer default dbms_sql.open_cursor;
   l_status        integer default -1 ;
   l_sqltext       varchar2(32000);
 begin
      begin
        l_status := -2;
        select dbms_lob.substr(sql_fulltext,32000) into l_sqltext from system.temp_adg_sqltext where sql_id = '6h35dn6j9m4u8';
        dbms_sql.parse(l_theCursor, l_sqltext, dbms_sql.native);
      exception
           when others
             then l_status := dbms_sql.last_error_position;
           end;
      dbms_sql.close_cursor( l_theCursor );
 end;
/
