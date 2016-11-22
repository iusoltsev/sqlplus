--
-- @sql_plan_dep3 4hnjr40pspnzk 2528178990
-- DISPLAY_RAW function from Greg Rahn http://structureddata.org/2007/10/16/how-to-display-high_valuelow_value-columns-from-user_tab_col_statistics/
--

set feedback on heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col DEP_TREE_BY_ID for a80
col DEP_TREE for a60
col DEPENDS_ON for a12
COLUMN LAST_TIME FORMAT A100 HEADING "LAST_DDL \\ LAST_ANALYZED \\ Temp? \\ DEGREE \\ Indices#"
col LAST_MODIFIED for a17
col REFERENCED    for a60

WITH
function display_raw (rawval raw, type varchar2) return varchar2 is
    cn     number;
    cv     varchar2(32);
    cd     date;
    cnv    nvarchar2(32);
    cr     rowid;
    cc     char(32);
    cbf    binary_float;
    cbd    binary_double;
begin
    if    (type = 'VARCHAR2')      then dbms_stats.convert_raw_value(rawval, cv);  return to_char(cv);
    elsif (type = 'DATE')          then dbms_stats.convert_raw_value(rawval, cd);  return to_char(cd);
    elsif (type = 'TIMESTAMP')     then dbms_stats.convert_raw_value(rawval, cd);  return to_char(cd,'dd.mm.yyyy hh24:mi:ss');
    elsif (type = 'NUMBER')        then dbms_stats.convert_raw_value(rawval, cn);  return to_char(cn);
    elsif (type = 'BINARY_FLOAT')  then dbms_stats.convert_raw_value(rawval, cbf); return to_char(cbf);
    elsif (type = 'BINARY_DOUBLE') then dbms_stats.convert_raw_value(rawval, cbd); return to_char(cbd);
    elsif (type = 'NVARCHAR2')     then dbms_stats.convert_raw_value(rawval, cnv); return to_char(cnv);
    elsif (type = 'ROWID')         then dbms_stats.convert_raw_value(rawval, cr);  return to_char(cr);
    elsif (type = 'CHAR')          then dbms_stats.convert_raw_value(rawval, cc);  return to_char(cc);
    else return 'UNKNOWN DATATYPE';
    end if;
end;
select sql_id,
       child_number,
       plan_hash_value,
       EXTRACTVALUE(VALUE(D), '/bind/@nam') as NAME,
       to_number(EXTRACTVALUE(VALUE(D), '/bind/@pos')) as POSITION,
       EXTRACTVALUE(VALUE(D), '/bind/@ppo') as PPO,
       EXTRACTVALUE(VALUE(D), '/bind/@dty') as DATATYPE,
       EXTRACTVALUE(VALUE(D), '/bind/@csi') as CSI,
       EXTRACTVALUE(VALUE(D), '/bind/@frm') as FRM,
       EXTRACTVALUE(VALUE(D), '/bind/@pre') as PRE,
       EXTRACTVALUE(VALUE(D), '/bind/@scl') as SCL,
       EXTRACTVALUE(VALUE(D), '/bind/@mxl') as MAXLENGTH,
       EXTRACTVALUE(VALUE(D), '/bind/@captured') as CAPTURED,
       EXTRACTVALUE(VALUE(D), '/bind') as VALUE,
       display_raw(EXTRACTVALUE(VALUE(D), '/bind'),
                          decode(EXTRACTVALUE(VALUE(D), '/bind/@dty'),
                                 1,  'VARCHAR2',
                                 2,  'NUMBER',
                                 12, 'DATE',
                                 21, 'BINARY_FLOAT',
                                 22, 'BINARY_DOUBLE',
                                 69, 'ROWID',
                                 96, 'CHAR',
                                 180, 'TIMESTAMP'))
  FROM v$sql_plan,
       TABLE(XMLSEQUENCE(EXTRACT(xmltype(other_xml), '/*/peeked_binds/bind'))) D
 where sql_id = '4hnjr40pspnzk'
   and other_xml is not null
 order by child_number, POSITION;
/

set feedback on VERIFY ON