set lines 80 trimspool on trimout on
COLUMN qryrank FORMAT 90
COLUMN oprid   FORMAT a10
COLUMN tottime FORMAT 999,990.9
COLUMN pcttime FORMAT 90.0
SPOOL top10qry
SELECT *
FROM   (
       SELECT RANK() OVER (ORDER BY tottime DESC ) as qryrank
       ,      oprid, qryname, totexec, tottime
       ,      100*RATIO_TO_REPORT(tottime) OVER () as pcttime
       FROM   (SELECT oprid, qryname
              ,       SUM(execcount) totexec
              ,       SUM(execcount*avgexectime) tottime
              FROM    psqrystats
              GROUP BY oprid, qryname
              ) a
       )
WHERE  qryrank <= 10
/
spool off