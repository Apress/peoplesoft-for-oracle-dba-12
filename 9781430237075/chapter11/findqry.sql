REM findqry.sql
REM (c)Go-Faster Consultancy 2012

SELECT a.oprid, a.qryname
FROM   psqryrecord a
,      psqryrecord b
,      psqryrecord d
WHERE  a.oprid = b.oprid
AND    a.qryname = b.qryname
AND    a.oprid = d.oprid
AND    a.qryname = d.qryname
AND    a.corrname = 'A'
AND    a.recname = 'TRAINING'
AND    b.corrname = 'B'
AND    b.recname = 'COURSE_TBL'
AND    d.corrname = 'D'
AND    d.recname = 'PERSONAL_DTA_VW'
/
