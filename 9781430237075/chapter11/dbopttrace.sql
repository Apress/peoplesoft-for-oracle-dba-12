REM dbopttrace.sql
REM (c)Go-Faster Consultancy 2012

column process_instance heading 'Process|Instance' format 9999999
column exec_secs heading 'Exec|Secs'
column execute_count heading 'Execs' format 999999
column remarks format a10
column process_name format a12
column detail_id format a30
column statement_id format a40
column run_cntl_id format a10

SELECT  x.process_instance
, x.statement_id2 statement_id, p.remarks
, x.exec_secs, x.execute_count
FROM (
 SELECT l.process_instance
 , l.process_name
 , l.run_cntl_id
 , d.detail_id
 , l.process_name||'.'||SUBSTR(d.detail_id,1,LENGTH(d.detail_id)-1)||
   CASE ASCII(SUBSTR(d.detail_id,-1))
     WHEN 2 THEN 'D' WHEN 4 THEN 'S' ELSE '_' END as statement_id
 , l.process_name||'.'||d.detail_id statement_id2
 , l.process_instance||'-'||l.run_cntl_id||'(%)' remarks
 ,  d.execute_time/1000 exec_secs
 , d.execute_count
 FROM ps_bat_timings_log l
 , ps_bat_timings_dtl d
 WHERE   l.process_instance = d.process_instance
 AND bitand(l.trace_level,4096) = 4096
 ) x
LEFT OUTER JOIN sysadm.plan_table p
 ON p.statement_id LIKE x.statement_id
 AND p.remarks like x.remarks and p.id = 0
WHERE  x.process_instance = &process_instance
ORDER BY exec_secs DESC
/
