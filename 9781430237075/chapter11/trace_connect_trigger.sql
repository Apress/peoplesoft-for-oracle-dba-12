REM trace_connect_trigger.sql
REM (c)Go-Faster Consultancy 2012

rem requires following privileges
set echo on feedback on verify on termout on

GRANT SELECT ON sys.v_$session TO PUBLIC;
GRANT SELECT ON sys.v_$mystat  TO PUBLIC;

CREATE OR REPLACE TRIGGER sysadm.connect_trace
AFTER LOGON
ON sysadm.schema
DECLARE
    l_tfid VARCHAR2(64);
BEGIN

-- if this query returns no rows an exception is raised and trace not set
   SELECT SUBSTR(TRANSLATE(''''
                 ||TO_CHAR(sysdate,'YYYYMMDD.HH24MISS')
                 ||'.'||s.program
                 ||'.'||s.osuser
                 ||''''   
                ,' \/','___'),1,64)
   INTO   l_tfid
   FROM   v$session s
   WHERE  s.sid IN(
              SELECT sid 
              FROM   v$mystat 
              WHERE  rownum = 1)
   AND    s.program = 'sqrw.exe';

   EXECUTE IMMEDIATE 'alter session set TIMED_STATISTICS = TRUE';
   EXECUTE IMMEDIATE 'alter session set MAX_DUMP_FILE_SIZE = UNLIMITED';
   EXECUTE IMMEDIATE 'alter session set TRACEFILE_IDENTIFIER = '||l_tfid;
   EXECUTE IMMEDIATE 'alter session set events ''10046 trace name context forever, level 8''';

   EXCEPTION WHEN OTHERS THEN NULL;
END;
/

--drop trigger sysadm.connect_trace;


