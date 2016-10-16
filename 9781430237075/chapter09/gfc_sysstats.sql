rem gfc_sysstats.sql
rem the triggers require the following grants to be issues by SYS
rem GRANT SELECT ON v_$sysstat  TO sysadm;
rem GRANT SELECT ON v_$mystat   TO sysadm;
rem GRANT SELECT ON v_$database TO sysadm;
ROLLBACK;
clear screen

DROP TABLE gfc_sys_stats_temp
/
CREATE GLOBAL TEMPORARY TABLE gfc_sys_stats_temp
(process_instance NUMBER        NOT NULL
,statistic#       NUMBER        NOT NULL
,db_value         NUMBER        NOT NULL
,my_value         NUMBER        NOT NULL
,begindttm        DATE          NOT NULL
)
ON COMMIT PRESERVE ROWS 
/
CREATE INDEX gfc_sys_stats_temp
ON gfc_sys_stats_temp(process_instance, statistic#)
/

DROP TABLE gfc_sys_stats
/
CREATE TABLE gfc_sys_stats
(process_instance NUMBER        NOT NULL
,statistic#       NUMBER        NOT NULL
,db_value_before  NUMBER        NOT NULL
,my_value_before  NUMBER        NOT NULL
,begindttm        DATE		NOT NULL
,db_value_after   NUMBER        NOT NULL
,my_value_after   NUMBER        NOT NULL
,enddttm          DATE		NOT NULL
)
TABLESPACE users
/
DROP INDEX gfc_sys_stats
/
CREATE UNIQUE INDEX gfc_sys_stats
ON gfc_sys_stats(process_instance, statistic#, begindttm)
/

CREATE OR REPLACE TRIGGER sysadm.psprcsrqst_sys_stats_before
AFTER UPDATE OF runstatus ON sysadm.psprcsrqst
FOR EACH ROW
WHEN (new.runstatus = 7 AND old.runstatus != 7)
BEGIN
   INSERT INTO gfc_sys_stats_temp
   (      process_instance, statistic#
   ,      db_value, my_value
   ,      begindttm)
   SELECT :new.prcsinstance, s.statistics#
   ,      S.VALUE, M.VALUE
   ,      NVL(:new.begindttm,SYSDATE)
   FROM   v$sysstat s
   ,      v$mystat m
   WHERE  s.statistics# = m.statistic#
   ;
   EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER sysadm.psprcsrqst_sys_stats_after
AFTER UPDATE OF runstatus ON sysadm.psprcsrqst
FOR EACH ROW
WHEN (new.runstatus != 7 and old.runstatus = 7)
BEGIN
   INSERT INTO gfc_sys_stats
   (      process_instance, statistic#
   ,      db_value_before, my_value_before, begindttm
   ,      db_value_after , my_value_after , enddttm
   )
   SELECT :new.prcsinstance, s.statistics#
   ,      b.db_value, b.my_value, b.begindttm
   ,      S.VALUE, M.VALUE
   ,      NVL(:new.enddttm,SYSDATE)
   FROM   v$sysstat s
   ,      v$mystat  m
   ,      gfc_sys_stats_temp b
   WHERE  s.statistics# = m.statistic#
   AND    b.statistic# = s.statistics#
   AND    b.statistic# = m.statistic#
   AND    b.prcsinstance = :new.prcsinstance
   ;
   --from PT8.4 AE may not shutdown
   DELETE FROM gfc_sys_stats_temp
   WHERE  process_instance = :new.prcsinstance
   ;
   EXCEPTION WHEN OTHERS THEN NULL;
END;
/

show errors

UPDATE  sysadm.psprcsrqst
SET     runstatus = 7
,	begindttm = sysdate
WHERE   runstatus != 7
AND     prcstype IN('Application Engine','COBOL SQL',
        'SQR Process','SQR Report','SQR Report For WF Delivery')
AND     rownum = 1
;

UPDATE  sysadm.psprcsrqst
SET     runstatus = 2
,	enddttm = sysdate
WHERE   runstatus = 7
AND     prcstype IN('Application Engine','COBOL SQL',
        'SQR Process','SQR Report','SQR Report For WF Delivery')
AND     rownum = 1
;
