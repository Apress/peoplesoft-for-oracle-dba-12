REM traceallon.sql
REM (c)Go-Faster Consultancy 2009

set serveroutput on buffer 1000000000 echo on 
spool traceallon
DECLARE
   CURSOR c_appsess IS
   SELECT *
   FROM   v$session
   WHERE  type = 'USER'
-- AND    program like '%PSAPPSRV%'
   AND    client_info like '%,PSAPPSRV%';
   p_appsess c_appsess%ROWTYPE;
BEGIN
   OPEN c_appsess;
   LOOP
      FETCH c_appsess INTO p_appsess;
      EXIT WHEN c_appsess%NOTFOUND;
--    sys.dbms_system.set_sql_trace_in_session(
--                    p_appsess.sid, p_appsess.serial#,TRUE);
--    sys.dbms_support.start_trace_in_session(p_appsess.sid, p_appsess.serial#);
      sys.dbms_system.set_ev(p_appsess.sid, p_appsess.serial#,10046,8,'');
      sys.dbms_output.put_line('Enable:'
                               ||p_appsess.sid||','||p_appsess.serial#);
   END LOOP;
   CLOSE c_appsess;
END;
/
