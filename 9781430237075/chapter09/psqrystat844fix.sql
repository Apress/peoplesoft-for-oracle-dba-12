rem psqrystat844fix.sql
CREATE OR REPLACE TRIGGER psqryexeclog 
AFTER INSERT ON psqryexeclog
FOR EACH ROW
BEGIN
   UPDATE psqrystats
   SET    avgexectime  = (avgexectime * execcount + :new.exectime)/(execcount + 1)
   ,      avgfetchtime = (avgfetchtime * execcount + :new.fetchtime)                                                           /(execcount + 1)
   ,      avgnumrows   = (avgnumrows * execcount + :new.numrows)/(execcount + 1)
   ,      lastexecdttm = GREATEST(lastexecdttm,:new.execdttm)
   ,      execcount    = execcount + 1        
   ,      numkills     = numkills + DECODE(:new.killedreason,' ',0,1)
   WHERE  oprid        = :new.oprid
   AND    qryname      = :new.qryname
   ;
   IF SQL%NOTFOUND THEN
      INSERT INTO PSQRYSTATS (oprid, qryname, execcount, avgexectime, avgfetchtime, lastexecdttm, avgnumrows, numkills) 
      VALUES (:new.oprid,:new.qryname,1,:new.exectime,:new.fetchtime,:new.execdttm,:new.numrows,DECODE(:new.killedreason,' ',0,1));
   END IF;
END;
/

show errors
