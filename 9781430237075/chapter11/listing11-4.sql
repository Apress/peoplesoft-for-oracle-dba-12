REM listing11-4.sql
REM (c)Go-Faster Consultancy 2012

SELECT /*+leading(r x h) use_nl(h)*/ h.sql_id, h.sql_plan_hash_value
, (NVL(CAST(r.enddttm AS DATE),SYSDATE)-CAST(r.begindttm AS DATE))*86400 exec_secs
, SUM(10) ash_secs
FROM  dba_hist_snapshot x
,      dba_hist_active_sess_history h
,      psprcsrqst r
WHERE X.END_INTERVAL_TIME >= r.begindttm
AND x.begin_interval_time <= NVL(r.enddttm,SYSDATE)
AND  h.snap_id = x.snap_id
AND h.dbid = x.dbid
AND h.instance_number = x.instance_number
AND h.sample_time BETWEEN r.begindttm AND NVL(r.enddttm,SYSDATE)
AND h.module = r.prcsname
AND h.action LIKE 'PI='||r.prcsinstance||'%'
AND r.prcsname = 'GPPDPRUN'
AND r.prcsinstance BETWEEN 18039 AND 18070
GROUP BY h.sql_id, h.sql_plan_hash_value, r.begindttm, r.enddttm
ORDER BY ash_secs desc
/
