REM listing 11-1.sql
REM (c)Go-Faster Consultancy 2012

SELECT /*+LEADING(x h) USE_NL(h)*/
h.module, h.action, sum(10) ash_secs
FROM dba_hist_active_sess_history h,
, dba_hist_snapshot x
WHERE x.end_interval_time >= TRUNC(SYSDATE)-7
AND h.sample_time >= TRUNC(SYSDATE)-7
AND h.snap_id = x.snap_id
AND h.dbid = x.dbid
AND h.instance_number = x.instance_number
AND x.instance_number = h.instance_number
AND UPPER(h.program) like 'PSAPPSRV%'
GROUP BY h.module, h.action
ORDER BY ash_secs DESC
/