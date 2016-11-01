-- Baseline hints list
-- Usage: SQL> @bl_hints SQL_PLAN_acg49cdw0088v4085ecd2
--
set verify off feedback off timi off

select substr(extractvalue(value(d), '/hint'), 1, 200) as outline_hints
  from xmltable('/outline_data/hint' passing
                (select xmltype(comp_data) as xmlval
                   from sys.sqlobj$data od, sys.sqlobj$ o
                  where o.obj_type = 2
                    and od.obj_type = 2
                    and o.name = '&&1'
                    and o.signature = od.signature
                    and o.plan_id = od.plan_id
                    and comp_data is not null)) d
/

set verify on feedback on timi on