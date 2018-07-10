--
-- Copyright (c) 1988, 2005, Oracle.  All Rights Reserved.
--
-- NAME
--   glogin.sql
--
-- DESCRIPTION
--   SQL*Plus global login "site profile" file
--
--   Add any SQL*Plus commands here that are to be executed when a
--   user starts SQL*Plus, or uses the SQL*Plus CONNECT command.
--
-- USAGE
--   This script is automatically run
--
col ver  new_value ver
col host new_value host
col inst new_value inst
set termout off
select substr(version,1,instr(version,'.',1,4)) ver,
       upper(instance_name) inst,
       substr(host_name,1,instr(host_name,'.',1,1) - 1) host
 from v$instance;
set termout on
--set sqlprompt "&&ver&&_USER@&&_CONNECT_IDENTIFIER SQL> "
set sqlprompt "&&ver&&_USER@&&host/&&inst SQL> "
set linesize 500 pagesize 2000 timi on
alter session set max_dump_file_size = unlimited;