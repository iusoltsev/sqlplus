--
-- SQL Profile hints list, including Profiles created by DBMS_SQLTUNE.IMPORT_SQL_PROFILE
-- Usage: SQL> @sql_profile_hints "SQL_Profile_name" "%Search_Phrase%"
--
set verify off timi off lines 500
col HINT for a500

select * from (
select substr(extractvalue(value(d), '/hint'), 1, 4000) as hint
  from xmltable('/outline_data/hint' passing
                (select xmltype(comp_data) as xmlval
                   from sys.sqlobj$data od join sys.sqlobj$ o using (signature, category,obj_type,plan_id)
                  where obj_type = 1 -- type "SQL Profile"
                    and o.name = '&1'
                    and comp_data is not null)) d)
 where hint like upper('%&2%')
/
/*
select * from
   (SELECT o.name as SQL_Profile_name,
           extractValue(value(h), '.') AS hint
      FROM sys.sqlobj$data od,
           sys.sqlobj$ o,
           TABLE(xmlsequence(extract(xmltype(od.comp_data), '/outline_data/hint'))) h
     WHERE od.comp_data is not null
       and od.signature = o.signature
       and od.category  = o.category
       and od.obj_type  = o.obj_type
       and od.plan_id   = o.plan_id
       and o.obj_type   = 1)          -- type "SQL Profile"
where SQL_Profile_name like 'SYS_SQLPROF%'
  and hint like '%_STATS%'
*/
set verify on timi on