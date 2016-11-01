drop table SYSTEM.GV_D_ASM_DISK_LC
/
create global temporary table SYSTEM.GV_D_ASM_DISK_LC on commit preserve rows
as select * from SYS.GV$ASM_DISK where 1=0
/
begin
  insert into SYSTEM.GV_D_ASM_DISK_LC select * from SYS.GV$ASM_DISK;
  dbms_lock.sleep(10);-- XX sec timeout
  dbms_output.put_line('Inst #' ||' '|| lpad('Disk',12) ||' '|| lpad('Reads',6) ||' '|| 'Min - Max, ms' ||' '|| 'Writes' ||' '|| 'Min - Max, ms' ||' '||
                          'Avg.COLDRead / WriteSize,Bytes' ||' '|| 'Avg.HOT Read / WriteSize,Bytes');
  dbms_output.put_line('------ ------------ ------ ------------- ------ ------------- ------------------------------ ------------------------------');
  for reco in (select curr.inst_id,
                      curr.NAME as asm_disk,
                      sum((curr.reads - prev.reads)) reads,
                      min(round(((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4)) * 1000 ms_per_read_min,
                      max(round(((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4)) * 1000 ms_per_read,
                      sum((curr.WRITES - prev.WRITES)) writes,
                      min(round(((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4)) * 1000 ms_per_write_min,
                      max(round(((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4)) * 1000 ms_per_write,
                      avg(round(((curr.COLD_BYTES_READ - prev.COLD_BYTES_READ) / decode((curr.COLD_READS - prev.COLD_READS),0,-1,(curr.COLD_READS - prev.COLD_READS))))) avg_cold_read_size,
                      avg(round(((curr.COLD_BYTES_WRITTEN - prev.COLD_BYTES_WRITTEN) / decode((curr.COLD_WRITES - prev.COLD_WRITES),0,-1,(curr.COLD_WRITES - prev.COLD_WRITES))))) avg_cold_write_size,
                      avg(round(((curr.HOT_BYTES_READ - prev.HOT_BYTES_READ) / decode((curr.HOT_READS - prev.HOT_READS),0,-1,(curr.HOT_READS - prev.HOT_READS))))) avg_hot_read_size,
                      avg(round(((curr.HOT_BYTES_WRITTEN - prev.HOT_BYTES_WRITTEN) / decode((curr.HOT_WRITES - prev.HOT_WRITES),0,-1,(curr.HOT_WRITES - prev.HOT_WRITES))))) avg_hot_write_size
                 from GV$ASM_DISK curr, SYSTEM.GV_D_ASM_DISK_LC prev
                where curr.name is not null
                  and prev.name is not null
                  and prev.disk_number = curr.DISK_NUMBER
                  and prev.group_number = curr.group_number
                  and prev.inst_id = curr.inst_id
                  and nvl(prev.failgroup, 'n') = nvl(curr.failgroup, 'n')
                  and ( (curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads)) > 1 / 1000    -- read longer than XX ms
                      or
                      (curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES)) > 1 / 1000 )-- write longer than XX ms
                  and curr.NAME like 'SSD%'
               group by curr.inst_id, curr.NAME
               order by 1,2)
  loop
    dbms_output.put_line( lpad(reco.inst_id, 6) ||' '||
                          lpad(reco.asm_disk,12) ||' '||
                          lpad(reco.reads,6) ||' '||
                          lpad(to_char(reco.ms_per_read_min, '9990.9'),6) || '-' || lpad(to_char(reco.ms_per_read, '9990.9'),6) ||' '||
                          lpad(reco.writes,6) ||' '||
                          lpad(to_char(reco.ms_per_write_min, '9990.9'),6) || '-' || lpad(to_char(reco.ms_per_write, '9990.9'),6) ||' '||
                          lpad(to_char(reco.avg_cold_read_size, '9999990'),12) || ' / ' || rpad(lpad(to_char(reco.avg_cold_write_size, '9999990'),9),15) ||' '||
                          lpad(to_char(reco.avg_hot_read_size, '9999990'),12) || ' / ' || rpad(lpad(to_char(reco.avg_hot_write_size, '9999990'),9),15));
  end loop;
  rollback;
end;
/
begin
  insert into SYSTEM.GV_D_ASM_DISK_LC select * from SYS.V$ASM_DISK;
  dbms_lock.sleep(10);-- 1 sec timeout
  for reco in (
               select--+ ORDERED NO_QUERY_TRANSFORMATION
                      curr.NAME asm_disk,
                      round(((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4) * 1000 ms_per_read,
                      round(((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4) * 1000 ms_per_write
                 from
                 (select/*+ no_unnest */ name, disk_number, group_number, failgroup, read_time, reads, WRITE_TIME, writes from V$ASM_DISK where name is not null group by name, disk_number, group_number, failgroup, read_time, reads, WRITE_TIME, writes) prev,
                 (select/*+ no_unnest */ name, disk_number, group_number, failgroup, read_time, reads, WRITE_TIME, writes from V$ASM_DISK where name is not null group by name, disk_number, group_number, failgroup, read_time, reads, WRITE_TIME, writes) curr
                where prev.disk_number = curr.DISK_NUMBER
                  and prev.group_number = curr.group_number
                  and nvl(prev.failgroup, 'n') = nvl(curr.failgroup, 'n')
                  and ( (curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads)) > 50 / 1000    -- read longer than 50 ms
                      or
                      (curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES)) > 50 / 1000 )-- write longer than 100 ms
                  )
  loop
    dbms_output.put_line(reco.asm_disk || ': read time ' ||
                         to_char(reco.ms_per_read, '9999.9') || ' ms; write time ' ||
                         to_char(reco.ms_per_write, '9999.9') || ' ms');
  end loop;
  rollback;
end;

SELECT * FROM TABLE(system.db_state_mon.asm_dg_stat(''))


declare
io_type char := 'R';
read_val varchar2(4096) := '';
write_val varchar2(4096) := '';
round_digs number := 0;
type V_ASM_DISK_TYPE is table of sys.V$ASM_DISK%rowtype;
V_ASM_DISK_TABLE_1 V_ASM_DISK_TYPE;
V_ASM_DISK_TABLE_2 V_ASM_DISK_TYPE;
V_ASM_DISK_TABLE_D V_ASM_DISK_TYPE;
begin

  select * BULK COLLECT into V_ASM_DISK_TABLE_1 from sys.V$ASM_DISK;
  dbms_lock.sleep(1);
  select * BULK COLLECT into V_ASM_DISK_TABLE_2 from sys.V$ASM_DISK;

  FOR i IN V_ASM_DISK_TABLE_2.FIRST .. V_ASM_DISK_TABLE_2.LAST
  LOOP
        for j IN V_ASM_DISK_TABLE_1.FIRST .. V_ASM_DISK_TABLE_1.LAST
        loop
        if V_ASM_DISK_TABLE_1(j).disk_number = V_ASM_DISK_TABLE_2(i).disk_number
        and V_ASM_DISK_TABLE_1(j).group_number = V_ASM_DISK_TABLE_2(i).group_number
        and nvl(V_ASM_DISK_TABLE_1(j).failgroup, 'n') = nvl(V_ASM_DISK_TABLE_2(i).failgroup, 'n')
        then
        V_ASM_DISK_TABLE_D(i).read_time := V_ASM_DISK_TABLE_D(i).read_time - V_ASM_DISK_TABLE_D(i).read_time
        end loop; 
        dbms_output.put_line(V_ASM_DISK_TABLE(i).disk_number);
  END LOOP;

      return;

    dbms_lock.sleep(1);
    for reco in (
                  select
                        substr(curr.NAME, 1, 5) asm_disk_target,
                        max((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads), 0, -1, (curr.reads - prev.reads))) * 1000 ms_per_read,
                        max((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES), 0, -1, (curr.WRITES - prev.WRITES))) * 1000 ms_per_write
                      
                 from
                 sys.V$ASM_DISK prev,
                 sys.V$ASM_DISK curr
                where prev.disk_number = curr.DISK_NUMBER
                  and prev.group_number = curr.group_number
                  and nvl(prev.failgroup, 'n') = nvl(curr.failgroup, 'n')
                  group by substr(curr.NAME, 1, 5)
                  )
    loop
      if read_val = '{[asm_dg_max_readtime=' then
        read_val := read_val || lower(reco.asm_disk_target) || ':' ||
                    round(reco.ms_per_read, round_digs);
      else
        read_val := read_val || ' ' || lower(reco.asm_disk_target) || ':' ||
                    round(reco.ms_per_read, round_digs);
      end if;
      if write_val = '{[asm_dg_max_writetime=' then
        write_val := write_val || lower(reco.asm_disk_target) || ':' ||
                     round(reco.ms_per_write, round_digs);
      else
        write_val := write_val || ' ' || lower(reco.asm_disk_target) || ':' ||
                     round(reco.ms_per_write, round_digs);
      end if;
    end loop;
    rollback;
    if io_type = 'R' then dbms_output.put_line(read_val || ']}'); RETURN; end if;
    if io_type = 'W' then dbms_output.put_line(write_val || ']}'); RETURN; end if;
    dbms_output.put_line(read_val || ']}'); dbms_output.put_line(write_val || ']}'); RETURN;
end;

DECLARE
--    TYPE DateType IS OBJECT ( PayPeriod DATE );
--    dd date;
--    TYPE TableList IS TABLE OF dd%type;
--    List1 TableList;
type V_ASM_DISK_TYPE is table of sys.V$ASM_DISK%rowtype;
V_ASM_DISK_TABLE V_ASM_DISK_TYPE;

BEGIN

  SELECT ddd--DateType(payperiod)
    BULK COLLECT INTO List1
    FROM (select sysdate as ddd from dual);

  FOR c1 IN (SELECT dd--payperiod
                    FROM TABLE( CAST( List1 AS TableList)) )

  LOOP
    DBMS_OUTPUT.PUT_LINE( c1.payperiod );
  END LOOP;

END;


                  select
                        substr(curr.NAME, 1, 5) asm_disk_target,
                        max((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads), 0, -1, (curr.reads - prev.reads))) * 1000 ms_per_read,
                        max((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES), 0, -1, (curr.WRITES - prev.WRITES))) * 1000 ms_per_write
                      
                 from
                 sys.V$ASM_DISK prev,
                 sys.V$ASM_DISK curr
                where prev.disk_number = curr.DISK_NUMBER
                  and prev.group_number = curr.group_number
                  and nvl(prev.failgroup, 'n') = nvl(curr.failgroup, 'n')
                  group by substr(curr.NAME, 1, 5)


select * from dba_objects where object_name like '%VIEW%'

select * from V_$FIXED_VIEW_DEFINITION where VIEW_NAME = 'GV$ASM_DISK'

select * from V_$FIXED_VIEW_DEFINITION where VIEW_NAME = 'GV$ASM_DISK_IOSTAT'

select * from V_$FIXED_VIEW_DEFINITION where VIEW_NAME = 'GV$ASM_DISK_STAT'

select
d.DISK_NUMBER,
d.group_number,
d.FAILGROUP,
d.READ_TIME-di.READ_TIME,
d.READS-di.READS,
d.WRITE_TIME-di.WRITE_TIME,
d.WRITES-di.WRITES,
d.READ_TIME-ds.READS,
d.READS-ds.READS,
d.WRITE_TIME-ds.WRITE_TIME,
d.WRITES-ds.WRITES
from V$ASM_DISK d, V$ASM_DISK_IOSTAT di, V$ASM_DISK_STAT ds
where
d.DISK_NUMBER = di.DISK_NUMBER
and d.group_number = di.group_number
and d.DISK_NUMBER = ds.DISK_NUMBER
and d.group_number = ds.group_number
and nvl(d.FAILGROUP, 'n') = nvl(di.FAILGROUP, 'n')
and nvl(d.FAILGROUP, 'n') = nvl(ds.FAILGROUP, 'n')

select substr(name, 1, 6) asm_disk_target, sum(reads) as reads, sum(read_time) as read_time, sum(writes) as writes, sum(write_time) as write_time from v_$asm_disk_stat where name is not null group by substr(name, 1, 6)

select x.inst_id as "INST_ID",
x.indx + 1 as "NUM",
ksppinm as "NAME",
ksppity as "TYPE",
ksppstvl as "VALUE",
ksppstdvl as "DISPLAY_VALUE",
ksppstdf as "ISDEFAULT",
decode(bitand(ksppiflg / 256, 1), 1, 'TRUE', 'FALSE') as "ISSES_MODIFIABLE",
decode(bitand(ksppiflg / 65536, 3),
1,'IMMEDIATE',2,'DEFERRED',3,'IMMEDIATE','FALSE') as "ISSYS_MODIFIABLE",
decode(bitand(ksppiflg, 4),4,'FALSE',
decode(bitand(ksppiflg / 65536, 3), 0, 'FALSE', 'TRUE')) as "ISINSTANCE_MODIFIABLE",
decode(bitand(ksppstvf, 7), 1, 'MODIFIED', 4, 'SYSTEM_MOD', 'FALSE') as "ISMODIFIED",
decode(bitand(ksppstvf, 2), 2, 'TRUE', 'FALSE') as "ISADJUSTED",
decode(bitand(ksppilrmflg / 64, 1), 1, 'TRUE', 'FALSE') as "ISDEPRECATED",
decode(bitand(ksppilrmflg / 268435456, 1), 1, 'TRUE', 'FALSE') as "ISBASIC",
ksppdesc as "DESCRIPTION",
ksppstcmnt as "UPDATE_COMMENT",
ksppihash as "HASH"
from x$ksppi x, x$ksppcv y
where (x.indx = y.indx)
--and ((translate(ksppinm, '_', '#') not like '##%')
and ((translate(ksppinm, '_', '#') like '#newsort#enabled%'))

select name asm_disk_target, sum(reads) as reads, sum(read_time) as read_time, sum(writes) as writes, sum(write_time) as write_time from v\$asm_disk_stat where name is not null

select d.name dbid, i.instance_number inst_num from v$database d, v$instance i

select count(*) from v$asm_disk_stat

select name asm_disk_name, reads, read_time, writes, write_time from v$asm_disk_stat where name is not null

select name asm_disk_name, reads, round(read_time*1000), writes, round(write_time*1000) from v$asm_disk where name is not null order by name

FAST_FUNCTION(PARAM_LIST_1)


begin
  insert into SYSTEM.V_D_ASM_DISK_LC select * from SYS.V$ASM_DISK;
  dbms_lock.sleep(10);-- 1 sec timeout
  for reco in (
               select curr.NAME asm_disk,
                      max(round(((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4)) * 1000 ms_per_read,
                      min(round(((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4)) * 1000 ms_per_read_min,
                      max(round(((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4)) * 1000 ms_per_write,
                      min(round(((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4)) * 1000 ms_per_write_min
                 from V$ASM_DISK curr, SYSTEM.V_D_ASM_DISK_LC prev
                where curr.name is not null
                  and prev.name is not null
                  and prev.disk_number = curr.DISK_NUMBER
                  and prev.group_number = curr.group_number
                  and nvl(prev.failgroup, 'n') = nvl(curr.failgroup, 'n')
                  and ( (curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads)) > 0 / 1000    -- read longer than 50 ms
                      or
                      (curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES)) > 0 / 1000 )-- write longer than 100 ms
               group by curr.NAME
               order by
               max(round(((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4))
               +
               max(round(((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4))
               desc
              )
  loop
    dbms_output.put_line(reco.asm_disk || ': read time ' ||
                         to_char(reco.ms_per_read, '999999.9') || ' ms; write time ' ||
                         to_char(reco.ms_per_write, '999999.9') || ' ms'
                         --|| ': read time min ' || to_char(reco.ms_per_read_min, '9999.9') || ' ms; write time min ' ||
                         --to_char(reco.ms_per_write, '9999.9') || ' ms'
                         );
  end loop;
  rollback;
end;

select * from v$instance

begin
  insert into SYSTEM.V_D_ASM_DISK_LC select * from SYS.V$ASM_DISK;
  dbms_lock.sleep(10);-- timeout
  for reco in (
               select curr.NAME asm_disk,
                      max(round(((round(curr.read_time*1000) - round(prev.read_time*1000)) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4)) ms_per_read,
                      min(round(((round(curr.read_time*1000) - round(prev.read_time*1000)) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4)) ms_per_read_min,
                      max(round(((round(curr.WRITE_TIME*1000) - round(prev.WRITE_TIME*1000)) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4)) ms_per_write,
                      min(round(((round(curr.WRITE_TIME*1000) - round(prev.WRITE_TIME*1000)) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4)) ms_per_write_min
                 from V$ASM_DISK curr, SYSTEM.V_D_ASM_DISK_LC prev
                where curr.name is not null
                  and prev.name is not null
                  and prev.disk_number = curr.DISK_NUMBER
                  and prev.group_number = curr.group_number
                  and nvl(prev.failgroup, 'n') = nvl(curr.failgroup, 'n')
                  and ( (curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads)) > 10 / 1000    -- read longer than 50 ms
                      or
                      (curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES)) > 10 / 1000 )-- write longer than 100 ms
               group by curr.NAME
               order by
               max(round(((curr.read_time - prev.read_time) / decode((curr.reads - prev.reads),0,-1,(curr.reads - prev.reads))),4))
               +
               max(round(((curr.WRITE_TIME - prev.WRITE_TIME) / decode((curr.WRITES - prev.WRITES),0,-1,(curr.WRITES - prev.WRITES))),4))
               desc
              )
  loop
    dbms_output.put_line(reco.asm_disk || ': read time ' ||
                         to_char(reco.ms_per_read, '999999.9') || ' ms; write time ' ||
                         to_char(reco.ms_per_write, '999999.9') || ' ms'
                         --|| ': read time min ' || to_char(reco.ms_per_read_min, '9999.9') || ' ms; write time min ' ||
                         --to_char(reco.ms_per_write, '9999.9') || ' ms'
                         );
  end loop;
  rollback;
end;

create global temporary table SYSTEM.V_D_ASM_DISK_LC on commit preserve rows
as select * from SYS.V$ASM_DISK where 1=0
/
