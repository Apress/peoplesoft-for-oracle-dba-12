REM snap_trigger.sql
REM (c)Go-Faster Consultancy 2012

spool snap_trigger
rollback;
rem requires following grants to be made explicitly by perfstat
rem GRANT EXECUTE ON perfstat.statspack TO sysadm;

CREATE OR REPLACE TRIGGER sysadm.snap
BEFORE UPDATE OF runstatus ON sysadm.psprcsrqst
FOR EACH ROW
WHEN (  (new.runstatus = 7 AND old.runstatus != 7)
     OR (new.runstatus != 7 AND old.runstatus = 7))
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_comment VARCHAR2(160);
  l_level INTEGER;
BEGIN
  IF ( :new.runcntlid LIKE '%SNAP%' 
  ----------------------------------------------------------------
  --code conditions for processes for which snapshots to be taken
  ----------------------------------------------------------------
  --  OR (    SUBSTR(:new.prcsname,1,3) = 'TL_'
  --      AND :new.rqstdttm <= TO_DATE('20080509','YYYYMMDD'))
  ----------------------------------------------------------------
     ) THEN
    IF :new.runstatus = 7 THEN
       l_comment := 'Start';
       l_level := 5;
    ELSE
       l_comment := 'End';
       l_level := 6; /*Capture SQL on end snap*/
    END IF;

    l_comment := SUBSTR(:new.prcstype
               ||', '||:new.prcsname
               ||', '||:new.prcsinstance
               ||', '||l_comment
               ||', '||:new.oprid
                      ,1,160);

    perfstat.statspack.snap(
       i_snap_level=>l_level /*SQL captured if level >= 6*/
      ,i_ucomment=>l_comment);
    COMMIT;
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
show errors
