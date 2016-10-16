spool txrpt_post

CREATE INDEX tracesql2
ON tracesql
(operation,duration)
TABLESPACE indx 
NOLOGGING 
COMPRESS
;

DECLARE
   CURSOR c_fetches IS
   SELECT *
   FROM   tracesql
   WHERE  operation = 'Fetch'
   AND    parent_line_num <= 0
   ORDER BY database,program,pid,line_id,line_num,cursor,timestamp
   ;
   p_fetches c_fetches%ROWTYPE;
   l_parent_line_num INTEGER;
BEGIN
   OPEN c_fetches;
   LOOP
      FETCH c_fetches INTO p_fetches;
      EXIT WHEN c_fetches%NOTFOUND;

      SELECT MAX(a.line_num)
      INTO   l_parent_line_num
      FROM   tracesql a
      WHERE  (a.operation LIKE 'COM Stmt=%'
      OR      a.operation LIKE 'CEX Stmt=%')
      AND    a.database  = p_fetches.database
      AND    a.program   = p_fetches.program
      AND    a.pid       = p_fetches.pid
      AND    a.line_id   = p_fetches.line_id
      AND    a.line_num  < p_fetches.line_num
      AND    a.cursor    = p_fetches.cursor
      AND    a.timestamp <= p_fetches.timestamp
      ;

      UPDATE tracesql a
      SET    a.parent_line_num = NVL(l_parent_line_num,-1)
      WHERE  a.database  = p_fetches.database
      AND    a.program   = p_fetches.program
      AND    a.pid       = p_fetches.pid
      AND    a.line_id   = p_fetches.line_id
      AND    a.line_num  = p_fetches.line_num
      AND    a.cursor    = p_fetches.cursor
      AND    a.timestamp = p_fetches.timestamp
      ;

   END LOOP;
   CLOSE c_fetches;
END;
/

commit;

exit


