--
-- High version count reason for 11.1
-- Usage: 
-- 11.1.0.7.@ SQL> @shared_cu111 &sql_id
--

set feedback off heading on timi off pages 100 lines 300 echo off  VERIFY OFF

col sql_id for a13
col version_count for 99999999999999
col SHARED_CU_CNT for 99999999999999
col EXECS for 999999999
col PARSING_SCHEMA_NAME for a30
col Reason for a60
col sql_text for a100

select/*+RULE*/ sql_id as sql_id, version_count, SHARED_CU_CNT, executions as EXECS, address, hash_value, parsing_schema_name, reason, substrb(sql_text,1,100) as sql_text
from (
 select sql_id, address,
        decode(max( UNBOUND_CURSOR),'Y', ' UNBOUND_CURSOR')
      ||decode(max( SQL_TYPE_MISMATCH),'Y', ' SQL_TYPE_MISMATCH')
      ||decode(max( OPTIMIZER_MISMATCH),'Y', ' OPTIMIZER_MISMATCH')
      ||decode(max( OUTLINE_MISMATCH),'Y', ' OUTLINE_MISMATCH')
      ||decode(max( STATS_ROW_MISMATCH),'Y', ' STATS_ROW_MISMATCH')
      ||decode(max( LITERAL_MISMATCH),'Y', ' LITERAL_MISMATCH')
      -- ||decode(max( SEC_DEPTH_MISMATCH),'Y', ' SEC_DEPTH_MISMATCH')
      ||decode(max( EXPLAIN_PLAN_CURSOR),'Y', ' EXPLAIN_PLAN_CURSOR')
      ||decode(max( BUFFERED_DML_MISMATCH),'Y', ' BUFFERED_DML_MISMATCH')
      ||decode(max( PDML_ENV_MISMATCH),'Y', ' PDML_ENV_MISMATCH')
      ||decode(max( INST_DRTLD_MISMATCH),'Y', ' INST_DRTLD_MISMATCH')
      ||decode(max( SLAVE_QC_MISMATCH),'Y', ' SLAVE_QC_MISMATCH')
      ||decode(max( TYPECHECK_MISMATCH),'Y', ' TYPECHECK_MISMATCH')
      ||decode(max( AUTH_CHECK_MISMATCH),'Y', ' AUTH_CHECK_MISMATCH')
      ||decode(max( BIND_MISMATCH),'Y', ' BIND_MISMATCH')
      ||decode(max( DESCRIBE_MISMATCH),'Y', ' DESCRIBE_MISMATCH')
      ||decode(max( LANGUAGE_MISMATCH),'Y', ' LANGUAGE_MISMATCH')
      ||decode(max( TRANSLATION_MISMATCH),'Y', ' TRANSLATION_MISMATCH')
      ||decode(max( ROW_LEVEL_SEC_MISMATCH),'Y', ' ROW_LEVEL_SEC_MISMATCH')
      ||decode(max( INSUFF_PRIVS),'Y', ' INSUFF_PRIVS')
      ||decode(max( INSUFF_PRIVS_REM),'Y', ' INSUFF_PRIVS_REM')
      ||decode(max( REMOTE_TRANS_MISMATCH),'Y', ' REMOTE_TRANS_MISMATCH')
      ||decode(max( LOGMINER_SESSION_MISMATCH),'Y', ' LOGMINER_SESSION_MISMATCH')
      ||decode(max( INCOMP_LTRL_MISMATCH),'Y', ' INCOMP_LTRL_MISMATCH')
      ||decode(max( OVERLAP_TIME_MISMATCH),'Y', ' OVERLAP_TIME_MISMATCH')
      -- ||decode(max( SQL_REDIRECT_MISMATCH),'Y', ' SQL_REDIRECT_MISMATCH')
      ||decode(max( MV_QUERY_GEN_MISMATCH),'Y', ' MV_QUERY_GEN_MISMATCH')
      ||decode(max( USER_BIND_PEEK_MISMATCH),'Y', ' USER_BIND_PEEK_MISMATCH')
      ||decode(max( TYPCHK_DEP_MISMATCH),'Y', ' TYPCHK_DEP_MISMATCH')
      ||decode(max( NO_TRIGGER_MISMATCH),'Y', ' NO_TRIGGER_MISMATCH')
      ||decode(max( FLASHBACK_CURSOR),'Y', ' FLASHBACK_CURSOR')
      ||decode(max( ANYDATA_TRANSFORMATION),'Y', ' ANYDATA_TRANSFORMATION')
      ||decode(max( INCOMPLETE_CURSOR),'Y', ' INCOMPLETE_CURSOR')
      ||decode(max( TOP_LEVEL_RPI_CURSOR),'Y', ' TOP_LEVEL_RPI_CURSOR')
      ||decode(max( DIFFERENT_LONG_LENGTH),'Y', ' DIFFERENT_LONG_LENGTH')
      ||decode(max( LOGICAL_STANDBY_APPLY),'Y', ' LOGICAL_STANDBY_APPLY')
      ||decode(max( DIFF_CALL_DURN),'Y', ' DIFF_CALL_DURN')
      ||decode(max( BIND_UACS_DIFF),'Y', ' BIND_UACS_DIFF')
      ||decode(max( PLSQL_CMP_SWITCHS_DIFF),'Y', ' PLSQL_CMP_SWITCHS_DIFF')
      ||decode(max( CURSOR_PARTS_MISMATCH),'Y', ' CURSOR_PARTS_MISMATCH')
      ||decode(max( STB_OBJECT_MISMATCH),'Y', ' STB_OBJECT_MISMATCH')
      -- ||decode(max( ROW_SHIP_MISMATCH),'Y', ' ROW_SHIP_MISMATCH')
      ||decode(max( PQ_SLAVE_MISMATCH),'Y', ' PQ_SLAVE_MISMATCH')
      ||decode(max( TOP_LEVEL_DDL_MISMATCH),'Y', ' TOP_LEVEL_DDL_MISMATCH')
      ||decode(max( MULTI_PX_MISMATCH),'Y', ' MULTI_PX_MISMATCH')
      ||decode(max( BIND_PEEKED_PQ_MISMATCH),'Y', ' BIND_PEEKED_PQ_MISMATCH')
      ||decode(max( MV_REWRITE_MISMATCH),'Y', ' MV_REWRITE_MISMATCH')
      ||decode(max( ROLL_INVALID_MISMATCH),'Y', ' ROLL_INVALID_MISMATCH')
      ||decode(max( OPTIMIZER_MODE_MISMATCH),'Y', ' OPTIMIZER_MODE_MISMATCH')
      ||decode(max( PX_MISMATCH),'Y', ' PX_MISMATCH')
      ||decode(max( MV_STALEOBJ_MISMATCH),'Y', ' MV_STALEOBJ_MISMATCH')
      ||decode(max( FLASHBACK_TABLE_MISMATCH),'Y', ' FLASHBACK_TABLE_MISMATCH')
      ||decode(max( LITREP_COMP_MISMATCH),'Y', ' LITREP_COMP_MISMATCH')
      --Added in Oracle 11g
      ||decode(max( PLSQL_DEBUG),'Y', ' PLSQL_DEBUG')
      ||decode(max( LOAD_OPTIMIZER_STATS),'Y', ' LOAD_OPTIMIZER_STATS')
      ||decode(max( ACL_MISMATCH),'Y', ' ACL_MISMATCH')
      ||decode(max( FLASHBACK_ARCHIVE_MISMATCH),'Y', ' FLASHBACK_ARCHIVE_MISMATCH')
      ||decode(max( LOCK_USER_SCHEMA_FAILED),'Y', ' LOCK_USER_SCHEMA_FAILED')
      ||decode(max( REMOTE_MAPPING_MISMATCH),'Y', ' REMOTE_MAPPING_MISMATCH')
      ||decode(max( LOAD_RUNTIME_HEAP_FAILED),'Y', ' LOAD_RUNTIME_HEAP_FAILED')
      ||decode(max( HASH_MATCH_FAILED),'Y', ' HASH_MATCH_FAILED')
      --||decode(max( PURGED_CURSOR),'Y', ' PURGED_CURSOR')
      --||decode(max( BIND_LENGTH_UPGRADEABLE),'Y', ' BIND_LENGTH_UPGRADEABLE')
      as Reason
      , count(child_number) as SHARED_CU_CNT
  from v$sql_shared_cursor
   where sql_id = '&&1'
  group by sql_id, address)
join v$sqlarea using(address, sql_id)
  where version_count>1
 order by version_count desc,address
/
set feedback on pages 200 lines 2000  VERIFY ON