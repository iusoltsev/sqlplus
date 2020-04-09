--+subscribers
SELECT r.NAME snapname, snapid, NVL(r.snapshot_site, 'not registered') snapsite, snaptime FROM   sys.slog$ s, dba_registered_snapshots r
WHERE  s.snapid=r.snapshot_id(+) AND mowner LIKE UPPER('&1') AND MASTER LIKE UPPER('&2');
