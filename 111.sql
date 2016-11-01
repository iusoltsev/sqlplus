ACCEPT ash_table_name DEFAULT 'GV$ACTIVE_SESSION_HISTORY' PROMPT 'Enter ASH table name (whith conditions):'
ACCEPT SQL_ID 						  PROMPT 'Enter SQL_ID (required):'
ACCEPT HASH_VALUE                                         PROMPT 'Enter PLAN_HASH_VALUE or FULL_PLAN_HASH_VALUE (if available):'
ACCEPT SQL_EXEC_ID                                        PROMPT 'Enter SQL_EXEC_ID (if available):'
select count(*) from &ash_table_name
/