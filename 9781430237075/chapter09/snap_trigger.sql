spool snap_trigger
rollback;
rem requires following grants to be made explicitly by sys
rem GRANT EXECUTE ON perfstat.sysadm TO sysadm;

CREATE OR REPLACE trigger sysadm.snap
BEFORE UPDATE OF runstatus ON sysadm.psprcsrqst
FOR EACH ROW
WHEN (  (new.runstatus = 7 and old.runstatus != 7)
     or (new.runstatus != 7 and old.runstatus = 7)
     )
DECLARE
   PRAGMA AUTONOMOUS_TRANSACTION;
   l_comment VARCHAR2(160);
BEGIN
   IF :new.runstatus = 7 THEN
      l_comment := 'Start';
   ELSE
      l_comment := 'End';
   END IF;

   l_comment := SUBSTR(:new.prcstype
               ||', '||:new.prcsname
               ||', '||:new.prcsinstance
               ||', '||l_comment
               ||', '||:new.oprid
                      ,1,160);

   perfstat.statspack.snap
      (i_snap_level=>5
      ,i_ucomment=>l_comment
      );
   COMMIT;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

show errors

rem test that the trigger fires by updating something
UPDATE  sysadm.psprcsrqst
SET     runstatus = 7
WHERE   runstatus != 7
AND     prcstype IN('Application Engine','COBOL SQL',
        'SQR Process','SQR Report','SQR Report For WF Delivery')
AND     rownum = 1
;

rollback;
spool off
