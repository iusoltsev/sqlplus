set feedback off
SET VERIFY OFF

COL pvalid_default HEAD DEFAULT FOR A7
COL pvalid_value   HEAD VALUE   FOR A30
COL pvalid_name    HEAD PARAMETER FOR A50

undefine &1
BREAK ON pvalid_name

SELECT 
	NAME_KSPVLD_VALUES      pvalid_name, 
--	ORDINAL_KSPVLD_VALUES   ORDER, 
	VALUE_KSPVLD_VALUES	pvalid_value,
	DECODE(ISDEFAULT_KSPVLD_VALUES, 'FALSE', '', 'DEFAULT' ) pvalid_default
FROM 
	X$KSPVLD_VALUES 
WHERE 
	LOWER(NAME_KSPVLD_VALUES) LIKE LOWER('%&1%')
ORDER BY
	pvalid_name,
	ORDINAL_KSPVLD_VALUES,
	pvalid_default,
	pvalid_Value
/
SET VERIFY ON
set feedback on