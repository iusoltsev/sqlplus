--https://www.linkedin.com/pulse/how-list-patches-details-through-sql-statement-syed-jaffar-hussain
with a as
 (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
select x.*
  from a,
       xmltable('InventoryInstance/patches/*' passing a.patch_output
                columns patch_id     number       path 'patchID',
                        patch_uid    number       path 'uniquePatchID',
                        description  varchar2(80) path 'patchDescription',
                        applied_date varchar2(30) path 'appliedDate',
                        sql_patch    varchar2(8)  path 'sqlPatch',
                        rollbackable varchar2(8)  path 'rollbackable') x
/
--exec DBMS_QOPATCH.SET_CURRENT_OPINST ('db1g.oebs.yandex.net','OEBS1')
--select xmltransform (dbms_qopatch.get_opatch_lsinventory(), dbms_qopatch.GET_OPATCH_XSLT()) from dual;
--Queryable Patch Inventory -- SQL Interface to view, compare, validate database patches (Doc ID 1585814.1)