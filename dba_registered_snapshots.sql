SELECT r.NAME snapname, snapid, NVL(r.snapshot_site, 'not registered') snapsite, snaptime FROM   sys.slog$ s, dba_registered_snapshots r
WHERE  s.snapid=r.snapshot_id(+) AND mowner LIKE UPPER('BO') AND MASTER LIKE UPPER('T_CLIENT_DOMAIN2');
