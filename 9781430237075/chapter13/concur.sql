rem 13-2.concur.sql
spool concur


DECLARE
   l_count INTEGER := 0;

   CURSOR   c_txrpt IS
   SELECT   *
   FROM     txrpt t
   WHERE    concurrent = 0
   ORDER BY queue, stime desc, etime desc, stimestamp desc
   ;

   p_txrpt c_txrpt%ROWTYPE;
BEGIN
   OPEN c_txrpt;
   LOOP
      FETCH c_txrpt into p_txrpt;
      EXIT WHEN c_txrpt%NOTFOUND;

      UPDATE txrpt a
      SET    concurrent = (
             SELECT COUNT(*)
             FROM   txrpt b
             WHERE  b.stime <= a.stime
             AND    b.etime >= a.stime
             AND    b.stimestamp <= a.stimestamp
             AND    b.stimestamp >= a.stimestamp
                    - ceil((a.etime-a.stime)+1)/86400
             AND    b.queue = a.queue
             )
      WHERE service = p_txrpt.service
      AND   pid = p_txrpt.pid
      AND   stimestamp = p_txrpt.stimestamp
      AND   stime = p_txrpt.stime
      AND   etime = p_txrpt.etime
      ;

      IF l_count <= 1000 THEN
         l_count := l_count + 1;
      ELSE
         l_count := 0;
         COMMIT;
      END IF;
   END LOOP;
   COMMIT;
   CLOSE c_txrpt;
END;
/

commit;

spool off
exit
