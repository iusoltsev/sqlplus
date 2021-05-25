select
       a.owner,
       a.object_name,
       a.object_type,
       b.COMPILED_AT,
       b.completed_at,
       c.username compiled_by
from
    dba_objects a,
    UTL_RECOMP_COMPILED b,
    dba_users c
where
    a.OBJECT_ID = b.OBJ# and
    trunc(b.COMPILED_AT) > sysdate-30 and
    c.user_id=b.compiled_by
order by compiled_at
/