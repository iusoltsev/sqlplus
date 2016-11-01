--
-- SQL Profile hints list, including Profiles created by DBMS_SQLTUNE.IMPORT_SQL_PROFILE
-- Usage: SQL> @sql_profile_hints "SQL_Profile_name" "Search_Phrase"
--
set verify off timi off lines 500
col HINT for a400

select * from (
select substr(extractvalue(value(d), '/hint'), 1, 400) as hint
  from xmltable('/outline_data/hint' passing
                (select xmltype(comp_data) as xmlval
                   from sys.sqlobj$data od join sys.sqlobj$ o using (signature, category,obj_type,plan_id)
                  where obj_type = 1 -- type "SQL Profile"
                    and o.name = '&1'
                    and comp_data is not null)) d)
 where hint like upper('%&2%')
/

set verify on timi on