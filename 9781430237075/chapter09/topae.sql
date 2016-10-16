SET PAUSE OFF AUTOTRACE OFF ECHO OFF PAGES 40 LINES 80
COLUMN stmtrank          HEADING 'Stmt|Rank'        FORMAT 9999
COLUMN detail_id         HEADING 'Statement ID'     FORMAT a21
COLUMN pct_sqltime       HEADING '%|SQL|Time'       FORMAT 90.0 
COLUMN pct_total_time    HEADING '%|Total|Time'     FORMAT 90.0 
COLUMN cum_pc_sqltime    HEADING 'Cum %|SQL|Time'   FORMAT 90.0 
COLUMN cum_pc_total_time HEADING 'Cum %|Total|Time' FORMAT 90.0 
COLUMN executions        HEADING 'Execs'            FORMAT 9990
COLUMN compile_time      HEADING 'Compile|Time'     FORMAT 9990.0
COLUMN compile_count     HEADING 'Compile|Count'    FORMAT 9990
COLUMN fetch_time        HEADING 'Fetch|Time'       FORMAT 9990.0
COLUMN fetch_count       HEADING 'Fetch|Count'      FORMAT 9990
COLUMN retrieve_time     HEADING 'Retrieve|Time'    FORMAT 9990.0
COLUMN retrieve_count    HEADING 'Retrieve|Count'   FORMAT 9990
COLUMN execute_time      HEADING 'Exec|Time'        FORMAT 9990.0
COLUMN execute_count     HEADING 'Exec|Count'       FORMAT 9990
COLUMN ae_sqltime        HEADING 'AE|SQL|Time'      FORMAT 9990.0
COLUMN pc_sqltime        HEADING 'PC|SQL|Time'      FORMAT 9990.0
COLUMN pc_time           HEADING 'PC|Time'          FORMAT 990.0
COLUMN pc_count          HEADING 'PC|Count'         FORMAT 9990
spool topae
SELECT stmtrank
,      detail_id
,      execute_count
,      ae_sqltime
,      pc_sqltime
,      pc_time
,      ratio_sqltime*100 pct_sqltime
,      SUM(ratio_sqltime*100) 
           OVER (ORDER BY stmtrank RANGE UNBOUNDED PRECEDING) cum_pc_sqltime
,      ratio_total_time*100 pct_total_time
,      SUM(ratio_total_time*100) 
           OVER (ORDER BY stmtrank RANGE UNBOUNDED PRECEDING) cum_pc_total_time
FROM   (
       SELECT rank() OVER (ORDER BY sqltime desc) as stmtrank
       ,      a.*
       ,      RATIO_TO_REPORT(sqltime) OVER () as ratio_sqltime
       ,      RATIO_TO_REPORT(total_time) OVER () as ratio_total_time
       FROM   (
              SELECT bat_program_name||'.'||detail_id detail_id
              ,      COUNT(distinct process_instance) executions
--            ,      SUM(compile_time)/1000 compile_time
--            ,      SUM(compile_count) compile_count
--            ,      SUM(fetch_time)/1000 fetch_time
--            ,      SUM(fetch_count) fetch_count
--            ,      SUM(retrieve_time)/1000 retrieve_time
--            ,      SUM(retrieve_count) retrieve_count
              ,      SUM(execute_time)/1000 execute_time
              ,      SUM(execute_count) execute_count
              ,      SUM(peoplecodesqltime)/1000 pc_sqltime
              ,      SUM(peoplecodetime)/1000 pc_time
              ,      SUM(peoplecodecount) pc_count
              ,      SUM(execute_time +compile_time +fetch_time +retrieve_time)
                        /1000 ae_sqltime
              ,      SUM(execute_time +compile_time +fetch_time +retrieve_time
                        +peoplecodesqltime)/1000 sqltime
              ,      SUM(execute_time +compile_time +fetch_time +retrieve_time
                        +peoplecodesqltime +peoplecodetime)/1000 total_time
              FROM   ps_bat_timings_dtl a
--            WHERE  bat_program_name = 'PER099'
              GROUP BY bat_program_name, detail_id
              ) a
       )
WHERE  stmtrank <= 20
/
spool off
