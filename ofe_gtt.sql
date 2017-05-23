REM
REM https://github.com/oracle/dw-vldb-samples/blob/master/compare_ofe/ofe.sql
REM Compare database settings between different optimizer feature enable (OFE) settings
REM
REM GTTnPattern Search added by I.Usoltsev
REM
WHENEVER SQLERROR EXIT FAILURE

--set trims on
set timi off
set feedback off
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

declare
  not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_exists, -942);
  in_use EXCEPTION;
  PRAGMA EXCEPTION_INIT(in_use, -14452);
--  name_used EXCEPTION;
--  PRAGMA EXCEPTION_INIT(name_used, -955);
begin
  execute immediate 'drop table system.gtt_hiver_fix';
exception
  when not_exists then
    execute immediate 'create global temporary table system.gtt_hiver_fix on commit preserve rows
                       as select bugno, optimizer_feature_enable, value, sql_feature, description from v$session_fix_control where 1=0';
  when in_use then execute immediate 'truncate table system.gtt_hiver_fix';
end;
/

declare
  not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_exists, -942);
  in_use EXCEPTION;
  PRAGMA EXCEPTION_INIT(in_use, -14452);
--  name_used EXCEPTION;
--  PRAGMA EXCEPTION_INIT(name_used, -955);
begin
  execute immediate 'drop table system.gtt_lover_fix';
exception
  when not_exists then
    execute immediate 'create global temporary table system.gtt_lover_fix on commit preserve rows
                       as select bugno, optimizer_feature_enable, value, sql_feature, description from v$session_fix_control where 1=0';
  when in_use then execute immediate 'truncate table system.gtt_lover_fix';
end;
/

declare
  not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_exists, -942);
  in_use EXCEPTION;
  PRAGMA EXCEPTION_INIT(in_use, -14452);
--  name_used EXCEPTION;
--  PRAGMA EXCEPTION_INIT(name_used, -955);
begin
  execute immediate 'drop table system.gtt_hiver_env';
exception
  when not_exists then
    execute immediate 'create global temporary table system.gtt_hiver_env on commit preserve rows
                       as SELECT pi.ksppinm parameter_name, pcv.ksppstvl parameter_value, pcv.ksppstdf isdefault, pi.ksppdesc parameter_desc
                          FROM   sys.x$ksppi pi,
                                 sys.x$ksppcv pcv
                           WHERE pi.indx = pcv.indx
                             AND 1=0';
  when in_use then execute immediate 'truncate table system.gtt_hiver_env';
end;
/

declare
  not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_exists, -942);
  in_use EXCEPTION;
  PRAGMA EXCEPTION_INIT(in_use, -14452);
--  name_used EXCEPTION;
--  PRAGMA EXCEPTION_INIT(name_used, -955);
begin
  execute immediate 'drop table system.gtt_lover_env';
exception
  when not_exists then
    execute immediate 'create global temporary table system.gtt_lover_env on commit preserve rows
                       as SELECT pi.ksppinm parameter_name, pcv.ksppstvl parameter_value, pcv.ksppstdf isdefault, pi.ksppdesc parameter_desc
                          FROM   sys.x$ksppi pi,
                                 sys.x$ksppcv pcv
                           WHERE pi.indx = pcv.indx
                             AND 1=0';
  when in_use then execute immediate 'truncate table system.gtt_lover_env';
end;
/

select distinct regexp_replace(regexp_replace(optimizer_feature_enable,'^8',' 8'),'^9',' 9') available_versions
from   v$session_fix_control
order by 1;

define lover="11.2.0.3"
define hiver="12.1.0.2"

accept lover default &lover. prompt 'Enter low version [default: &lover.]: '
accept hiver default &hiver. prompt 'Enter high version [default: &hiver.]: '

alter session set optimizer_features_enable  = '&hiver';

insert into system.gtt_hiver_fix
select bugno,
       regexp_replace(regexp_replace(optimizer_feature_enable,'^8',' 8'),'^9',' 9') version_from,
       value,
       sql_feature,
       description
from   v$session_fix_control
where  session_id = userenv('sid');

insert into system.gtt_hiver_env
SELECT pi.ksppinm parameter_name, pcv.ksppstvl parameter_value, pcv.ksppstdf isdefault, pi.ksppdesc parameter_desc
FROM   sys.x$ksppi pi,
       sys.x$ksppcv pcv
WHERE pi.indx = pcv.indx;

alter session set optimizer_features_enable  = '&lover';

insert into system.gtt_lover_fix
select bugno,
       regexp_replace(regexp_replace(optimizer_feature_enable,'^8',' 8'),'^9',' 9') version_from,
       value,
       sql_feature,
       description
from   v$session_fix_control
where  session_id = userenv('sid');

insert into system.gtt_lover_env
SELECT pi.ksppinm parameter_name, pcv.ksppstvl parameter_value, pcv.ksppstdf isdefault, pi.ksppdesc parameter_desc
FROM   sys.x$ksppi pi,
       sys.x$ksppcv pcv
WHERE pi.indx = pcv.indx;

define pattern="%"

accept pattern default &pattern. prompt 'Enter search pattern [default: &pattern.]: '

PROMPT
PROMPT ***
PROMPT *** List of OFE-related fix controls added after &lover. - up until &hiver. inclusive:
PROMPT ***

select BUGNO, OPTIMIZER_FEATURE_ENABLE as VERSION_FROM, VALUE, SQL_FEATURE, DESCRIPTION, 'OPT_PARAM(''_fix_control'' ''' || BUGNO || ':0'')' as HINTS4CHECK
  from (select * from system.gtt_hiver_fix
        minus
        select * from system.gtt_lover_fix order by 2, 1)
 where upper(description) like upper('%&pattern%')
    or upper(sql_feature) like upper('%&pattern%');

prompt Press <CR> to continue...
pause

PROMPT ***
PROMPT *** List of additional or changed OFE-related parameters in &hiver. compared to &lover.:
PROMPT ***

select *
  from (select * from system.gtt_hiver_env
        minus
        select * from system.gtt_lover_env order by 1)
 where upper(parameter_desc) like upper('%&pattern%')
    or upper(parameter_name) like upper('%&pattern%');

-- drop table &schname..hiver_fix ;
-- drop table &schname..lover_fix ;

-- drop table &schname..hiver_env ;
-- drop table &schname..lover_env ;

-- disconnect
