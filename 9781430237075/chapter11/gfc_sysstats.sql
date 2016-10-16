rem gfc_sysstats.sql
REM (c)Go-Faster Consultancy 2012

ROLLBACK;

rem the triggers require the following grants to be made directly by SYS to SYSADM not via a role
GRANT SELECT ON sys.v_$sysstat  TO sysadm;
GRANT SELECT ON sys.v_$mystat   TO sysadm;
GRANT SELECT ON sys.v_$database TO sysadm;
clear screen

DROP TABLE sysadm.gfc_sys_stats_temp
/
CREATE GLOBAL TEMPORARY TABLE sysadm.gfc_sys_stats_temp
(prcsinstance     NUMBER        NOT NULL
,statistic#       NUMBER        NOT NULL
,db_value         NUMBER        NOT NULL
,my_value         NUMBER        NOT NULL
,begindttm        DATE          NOT NULL
)
ON COMMIT PRESERVE ROWS
/
CREATE INDEX gfc_sys_stats_temp
ON gfc_sys_stats_temp(prcsinstance, statistic#)
/

DROP TABLE sysadm.gfc_sys_stats
/
CREATE TABLE sysadm.gfc_sys_stats
(prcsinstance     NUMBER        NOT NULL
,statistic#       NUMBER        NOT NULL
,db_value_before  NUMBER        NOT NULL
,my_value_before  NUMBER        NOT NULL
,begindttm        DATE          NOT NULL
,db_value_after   NUMBER        NOT NULL
,my_value_after   NUMBER        NOT NULL
,enddttm          DATE          NOT NULL
)
TABLESPACE users
/
DROP INDEX sysadm.gfc_sys_stats
/
CREATE UNIQUE INDEX sysadm.gfc_sys_stats
ON gfc_sys_stats(prcsinstance, statistic#, begindttm)
/

CREATE OR REPLACE TRIGGER sysadm.psprcsrqst_sys_stats_before
AFTER UPDATE OF runstatus ON sysadm.psprcsrqst
FOR EACH ROW
WHEN (new.runstatus = 7 AND old.runstatus != 7)
BEGIN
  IF ( :new.runcntlid LIKE '%STAT%' 
  ----------------------------------------------------------------
  --code conditions for processes for which snapshots to be taken
  ----------------------------------------------------------------
  --  OR (    SUBSTR(:new.prcsname,1,3) = 'TL_'
  --      AND :new.rqstdttm <= TO_DATE('20080509','YYYYMMDD'))
  ----------------------------------------------------------------
  ) THEN
    INSERT INTO sysadm.gfc_sys_stats_temp
    (      prcsinstance, statistic#
    ,      db_value, my_value
    ,      begindttm)
    SELECT :new.prcsinstance, s.statistic#
    ,      S.VALUE, M.VALUE
    ,      NVL(:new.begindttm,SYSDATE)
    FROM   sys.v_$sysstat s
    ,      sys.v_$mystat m
    WHERE  s.statistic# = m.statistic#
    ;
  END IF;
EXCEPTION 
  WHEN OTHERS THEN NULL;
END;
/
show errors

CREATE OR REPLACE TRIGGER sysadm.psprcsrqst_sys_stats_after
AFTER UPDATE OF runstatus ON sysadm.psprcsrqst
FOR EACH ROW
WHEN (new.runstatus != 7 and old.runstatus = 7)
BEGIN
  IF ( :new.runcntlid LIKE '%STAT%' 
  ----------------------------------------------------------------
  --code conditions for processes for which snapshots to be taken
  ----------------------------------------------------------------
  --  OR (    SUBSTR(:new.prcsname,1,3) = 'TL_'
  --      AND :new.rqstdttm <= TO_DATE('20080509','YYYYMMDD'))
  ----------------------------------------------------------------
  ) THEN
   INSERT INTO sysadm.gfc_sys_stats
   (      prcsinstance, statistic#
   ,      db_value_before, my_value_before, begindttm
   ,      db_value_after , my_value_after , enddttm
   )
   SELECT :new.prcsinstance, s.statistic#
   ,      b.db_value, b.my_value, b.begindttm
   ,      S.VALUE, M.VALUE
   ,      NVL(:new.enddttm,SYSDATE)
   FROM   sys.v_$sysstat s
   ,      sys.v_$mystat  m
   ,      gfc_sys_stats_temp b
   WHERE  s.statistic# = m.statistic#
   AND    b.statistic# = s.statistic#
   AND    b.statistic# = m.statistic#
   AND    b.prcsinstance = :new.prcsinstance
   ;
   --from PT8.4 AE may not shut down
   DELETE FROM gfc_sys_stats_temp
   WHERE  prcsinstance = :new.prcsinstance
   ;
  END IF;
EXCEPTION 
  WHEN OTHERS THEN NULL;
END;
/
show errors

column name format a30
select	a.prcsinstance, b.name
, 	a.my_value_after-a.my_value_before my_diff
,	a.db_value_after-a.db_value_before db_diff
from	sysadm.gfc_sys_stats a
, 	v$sysstat b
where	a.statistic# = b.statistic#
and	(a.db_value_after!=a.db_value_before
OR	a.my_value_after!=a.my_value_before)
AND   	a.prcsinstance = &prcsinstance
/

