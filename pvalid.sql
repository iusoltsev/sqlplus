set feedback off
SET VERIFY OFF

COL pvalid_default HEAD DEFAULT FOR A7
COL pvalid_value   HEAD VALUE   FOR A30
COL pvalid_name    HEAD PARAMETER FOR A50
undefine &1
BREAK ON pvalid_name

PROMPT
PROMPT Valid values for parameters %&&1%

SELECT NAME                                         pvalid_name, 
       ORDINAL                                      ORD,
       VALUE                                        pvalid_value,
       DECODE(ISDEFAULT,'FALSE','','DEFAULT')       pvalid_default
FROM V$PARAMETER_VALID_VALUES
WHERE LOWER(NAME) LIKE LOWER('%&&1%')
ORDER BY name,
      ORD,
      pvalid_default,
      pvalid_Value
/

SET VERIFY ON
set feedback on