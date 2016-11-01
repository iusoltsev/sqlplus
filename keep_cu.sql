set feedback off
declare
    v_address_hash varchar2(60);
begin
    select address||', '||hash_value
       into v_address_hash
    from v$sqlarea
    where sql_id = '&&1';
sys.dbms_shared_pool.keep(v_address_hash, 'c');
end;
/
set feedback on