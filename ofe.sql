REM
REM https://github.com/oracle/dw-vldb-samples/blob/master/compare_ofe/ofe.sql
REM Compare database settings between different optimizer feature enable (OFE) settings
REM Pattern Search added by I.Usoltsev
REM
WHENEVER SQLERROR EXIT FAILURE

set trims on
set timi off
set feedback on
set linesize 220
set pagesize 1000
set verify oFF
column version_from format a12
column HINTS4CHECK for a60
column sql_feature format a36
column parameter_value format a40
column parameter_desc format a80
column description format a80
column parameter_name format a40
column version format a20
column available_versions format a20

PROMPT
PROMPT *****
PROMPT ***** WARNING:
PROMPT ***** If you have explicitly set any Optimizer parameters
PROMPT ***** then be aware that this can mask differences between
PROMPT ***** different optimizer_features_enable settings.
PROMPT ***** This can make the results of the comparison (below) incomplete.
PROMPT *****
PROMPT
PROMPT Press <CR> to continue...
PAUSE

define schname="SCOTT"
accept schname default &schname. prompt 'Enter the name of a schema where it is safe to create tables [default: &schname.]: '

declare
  ORA_00942 exception; pragma Exception_Init(ORA_00942, -00942);
begin
  execute immediate 'drop table &schname..hiver_fix ';
exception when ORA_00942 then null;
end;
/

declare
  ORA_00942 exception; pragma Exception_Init(ORA_00942, -00942);
begin
  execute immediate 'drop table &schname..lover_fix ';
exception when ORA_00942 then null;
end;
/

declare
  ORA_00942 exception; pragma Exception_Init(ORA_00942, -00942);
begin
  execute immediate 'drop table &schname..hiver_env ';
exception when ORA_00942 then null;
end;
/

declare
  ORA_00942 exception; pragma Exception_Init(ORA_00942, -00942);
begin
  execute immediate 'drop table &schname..lover_env ';
exception when ORA_00942 then null;
end;
/

select distinct regexp_replace(regexp_replace(optimizer_feature_enable,'^8',' 8'),'^9',' 9') available_versions
from   v$session_fix_control
order by 1;

define lover="11.2.0.4"
define hiver="12.1.0.2"

accept lover default &lover. prompt 'Enter low version [default: &lover.]: '
accept hiver default &hiver. prompt 'Enter high version [default: &hiver.]: '

alter session set optimizer_features_enable  = '&hiver';

create table &schname..hiver_fix as
select bugno,
       regexp_replace(regexp_replace(optimizer_feature_enable,'^8',' 8'),'^9',' 9') version_from,
       value,
       sql_feature,
       description
from   v$session_fix_control
where  session_id = userenv('sid');

create table &schname..hiver_env as
SELECT pi.ksppinm parameter_name, pcv.ksppstvl parameter_value, pcv.ksppstdf isdefault, pi.ksppdesc parameter_desc
FROM   sys.x$ksppi pi,
       sys.x$ksppcv pcv
WHERE pi.indx = pcv.indx ;

alter session set optimizer_features_enable  = '&lover';

create table &schname..lover_fix as
select bugno,
       regexp_replace(regexp_replace(optimizer_feature_enable,'^8',' 8'),'^9',' 9') version_from,
       value,
       sql_feature,
       description
from   v$session_fix_control
where  session_id = userenv('sid');

create table &schname..lover_env as
SELECT pi.ksppinm parameter_name, pcv.ksppstvl parameter_value, pcv.ksppstdf isdefault, pi.ksppdesc parameter_desc
FROM   sys.x$ksppi pi,
       sys.x$ksppcv pcv
WHERE pi.indx = pcv.indx ;

define pattern="%"

accept pattern default &pattern. prompt 'Enter search pattern [default: &pattern.]: '

PROMPT
PROMPT ***
PROMPT *** List of OFE-related fix controls added after &lover. - up until &hiver. inclusive:
PROMPT ***

select BUGNO, VERSION_FROM, VALUE, SQL_FEATURE, DESCRIPTION, 'OPT_PARAM(''_fix_control'' ''' || BUGNO || ':0'')' as HINTS4CHECK
  from (select * from &schname..hiver_fix
        minus
        select * from &schname..lover_fix order by 2, 1)
 where upper(description) like upper('%&pattern%')
    or upper(sql_feature) like upper('%&pattern%');

prompt Press <CR> to continue...
pause

PROMPT ***
PROMPT *** List of additional or changed OFE-related parameters in &hiver. compared to &lover.:
PROMPT ***

select *
  from (select * from &schname..hiver_env
        minus
        select * from &schname..lover_env order by 1)
 where upper(parameter_desc) like upper('%&pattern%')
    or upper(parameter_name) like upper('%&pattern%');

-- drop table &schname..hiver_fix ;
-- drop table &schname..lover_fix ;

-- drop table &schname..hiver_env ;
-- drop table &schname..lover_env ;

-- disconnect