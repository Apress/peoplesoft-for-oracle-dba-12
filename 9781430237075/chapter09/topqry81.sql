COLUMN durrank    FORMAT 90 
COLUMN query_name FORMAT a30
SPOOL topqry81
SELECT *
FROM   (
       SELECT RANK() OVER (ORDER BY duration DESC) AS durrank
       ,      SUBSTR(query_string2,INSTR(query_string2,'=',1,2)+1) query_name
       ,      duration
       ,      executions
       FROM   (
              SELECT   query_string2 
              ,        SUM(duration) duration
              ,        COUNT(*) executions
              FROM     weblogic
              WHERE    query_string1 = 'ICType=Query'
              AND      query_string2 IS NOT NULL
              GROUP BY query_string2
              ) 
       )
WHERE  durrank <= 20
ORDER BY durrank, executions DESC
/
SPOOL OFF