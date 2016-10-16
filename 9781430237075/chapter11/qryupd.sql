REM qryupd.sql
REM (c)Go-Faster Consultancy Ltd. 2004
REM ----------------------------------------------------------------------
REM STOP! DO NOT RUN THIS SCRIPT UNTIL YOU HAVE READ 
REM CHAPTER 11 OF PEOPLESOFT FOR THE ORACLE DBA
REM THIS SCRIPT IS COMPLETELY UNSUPPORTED
REM IT COULD CORRUPT EVERY QUERY IN YOUR PEOPLESOFT DATABASE
REM ----------------------------------------------------------------------
REM review this script before you run it
REM you will need to edit literal values and adjust some statements.
SET echo on feedback on verify on message on termout on
SPOOL qryupd

ROLLBACK;
DROP TABLE gfc_qryupd;
DROP TABLE gfc_qryupdrec;
DROP TABLE gfc_qryupdrec2;

REM ----------------------------------------------------------------------
REM *** specify the records and correlation names                      ***
REM *** add another psqryrecord for each record/correlation name       ***
REM *** combination that you are looking for                           ***

CREATE TABLE gfc_qryupd AS 
SELECT /*+ORDERED*/ 
       r1.oprid, r1.qryname
FROM   psqryrecord r1
,      psqryrecord r2
,      psqryrecord r3
WHERE  r1.recname = 'PSPRSMDEFN'
AND    r1.corrname  = 'A'
AND    r2.corrname  = 'B'
AND    r2.recname = 'PSPRSMPERM'
AND    r2.qryname = r1.qryname
AND    r2.oprid   = r1.oprid
AND    r3.corrname  = 'C'
AND    r3.recname = 'PSOPRDEFN'
AND    r3.qryname = r1.qryname
AND    r3.oprid   = r1.oprid
;

REM ----------------------------------------------------------------------
REM omit corrupt queries

DELETE FROM gfc_qryupd d
WHERE (d.oprid, d.qryname) IN (
      SELECT f.oprid, f.qryname
      FROM   psqryfield f
      WHERE  (f.oprid, f.qryname) IN 
             (SELECT oprid, qryname
             FROM   gfc_qryupd)
      AND    NOT EXISTS(
             SELECT 'x'
             FROM   psqryrecord r
             WHERE  r.qryname = f.qryname
             AND    r.oprid = f.oprid
             AND    r.recname = f.recname)
             AND   (f.recname != ' '
             OR     f.fieldname != ' ')
             );

REM ----------------------------------------------------------------------
REM create working storage table with queries to be updated

CREATE TABLE gfc_qryupdrec AS
SELECT oprid, qryname, corrname, recname, selnum
,      rcdnum oldrcdnum, rcdnum newrcdnum
FROM   psqryrecord
WHERE  (oprid, qryname) IN (
       SELECT oprid, qryname
       FROM   gfc_qryupd)
;

CREATE UNIQUE INDEX gfc_qryupdrec 
ON gfc_qryupdrec(oprid, qryname, selnum, oldrcdnum, recname)
;

REM ----------------------------------------------------------------------
REM *** apply new order using correlation names to id records          ***
REM *** specify the desired order of you query here                    ***
UPDATE gfc_qryupdrec
SET newrcdnum = DECODE(corrname,
                'A',3,
                'B',2,
                'C',1)
WHERE  (oprid, qryname) IN (
       SELECT oprid, qryname
       FROM   gfc_qryupd)
;

REM ----------------------------------------------------------------------
REM if a query has a sequence of record numbers per select, but only one
REM sequence of table aliases.  Therefore use rank() to produce a list 

CREATE TABLE gfc_qryupdrec2 AS
SELECT oprid, qryname, corrname, recname, selnum, oldrcdnum, newrcdnum
,      RANK() OVER (PARTITION BY oprid, qryname 
                    ORDER     BY selnum, newrcdnum) AS newrank
FROM   gfc_qryupdrec
;

CREATE UNIQUE INDEX gfc_qryupdrec2 
ON gfc_qryupdrec2(oprid, qryname, selnum, oldrcdnum, recname)
;

REM ----------------------------------------------------------------------
REM apply new order to record definitions, simultaneously set new table
REM alias.  If more than 12 tables extend list in decode statement

UPDATE psqryrecord r
SET    (rcdnum, corrname) = (
       SELECT l.newrcdnum
       ,      DECODE(newrank,1,'A',2,'B',3,'C',4,'D',5,'E',6,'F'
                            ,7,'G',8,'H',9,'I',10,'J',11,'K',12,'L')
       FROM   gfc_qryupdrec2 l
       WHERE  l.oprid = r.oprid
       AND    l.qryname = r.qryname
       AND    l.recname = r.recname
       AND    l.selnum = r.selnum
       AND    l.oldrcdnum = r.rcdnum)
WHERE  (oprid, qryname) IN (
       SELECT oprid, qryname
       FROM   gfc_qryupd)
AND    r.recname != ' '
;

REM ----------------------------------------------------------------------
REM apply new order to field definitions

UPDATE psqryfield r
SET    fldrcdnum = (
       SELECT l.newrcdnum
       FROM   gfc_qryupdrec2 l
       WHERE  l.oprid = r.oprid
       AND    l.qryname = r.qryname
       AND    l.recname = r.recname
       AND    l.selnum = r.selnum
       AND    l.oldrcdnum = r.fldrcdnum)
WHERE  (oprid, qryname) IN (
       SELECT oprid, qryname
       FROM   gfc_qryupd)
AND    r.recname != ' '
;

REM ----------------------------------------------------------------------
REM reset versions so that caches are updated
UPDATE pslock
SET    version=version+1
WHERE  objecttypename IN('QDM','SYS')
;

UPDATE psversion
SET    version=version+1
WHERE  objecttypename IN('QDM','SYS')
;

UPDATE psqrydefn
SET    version = (
       SELECT version 
       FROM   pslock 
       WHERE  objecttypename = 'QDM')
WHERE  (oprid, qryname) IN (
       SELECT oprid, qryname
       FROM   gfc_qryupd)
;

REM ----------------------------------------------------------------------
REM if and only if you are satisfied with the results commit the updates
REM COMMIT;
REM DROP TABLE gfc_qryupd;
REM DROP TABLE gfc_qryupdrec;
REM DROP TABLE gfc_qryupdrec2;

SPOOL OFF
