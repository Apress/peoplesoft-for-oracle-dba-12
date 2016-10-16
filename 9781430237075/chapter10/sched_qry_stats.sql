spool sched_qry_stats

column qryname   format a30     heading 'Query Name'
column avg_secs  format 9,999.9 heading 'Average|Exec|(s)'
column sum_secs  format 999,990 heading 'Total|Exec|(s)'
column num_execs format 999,990 heading 'Number|of|Execs'
SELECT QRYNAME
,      AVG(EXEC_SECS) AVG_SECS
,      SUM(EXEC_SECS) SUM_SECS
,      COUNT(*) NUM_EXECS
FROM (
SELECT
 SUBSTR(F.FILENAME,1,INSTR(FILENAME,'-'||LTRIM(TO_CHAR(F.PRCSINSTANCE))||'.')-1
       ) QRYNAME
,(CAST(ENDDTTM AS DATE)-CAST(BEGINDTTM AS DATE))*86400 EXEC_SECS
FROM PSPRCSRQST P, PS_CDM_FILE_LIST F
WHERE P.PRCSNAME = 'PSQUERY'
AND P.RUNSTATUS = 9
AND P.PRCSINSTANCE = F.PRCSINSTANCE
AND NOT F.CDM_FILE_TYPE IN('LOG','AET','TRC')
)
GROUP BY QRYNAME
ORDER BY SUM_SECS DESC
/



spool off
