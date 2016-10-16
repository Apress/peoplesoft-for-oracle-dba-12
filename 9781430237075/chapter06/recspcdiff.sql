REM recspcdiff.sql
REM (c) Go-Faster Consultancy Ltd. 2004
set echo on feedback on head on trimspool on lines 80
set serveroutput ON buffer 1000000000
spool recspcdiff

DECLARE
   CURSOR c_spcdiff IS
   SELECT r.recname, s.ddlspacename
   ,      t.table_name, t.tablespace_name
   FROM   psrecdefn r
   ,      psrectblspc s
   ,      user_tables t
   WHERE  t.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
   AND    r.rectype IN(0,7)
   AND    s.recname = r.recname
   AND    t.tablespace_name != s.ddlspacename
   ;
   p_spcdiff c_spcdiff%ROWTYPE;
   l_updcount INTEGER := 0;
BEGIN
   OPEN c_spcdiff;
   LOOP
      FETCH c_spcdiff INTO p_spcdiff;
      EXIT WHEN c_spcdiff%NOTFOUND;

      UPDATE psrectblspc
      SET    ddlspacename = p_spcdiff.ddlspacename
      WHERE  recname = p_spcdiff.recname
      ;

      l_updcount := l_updcount + 1;
      sys.dbms_output.put_line(
--       ''||l_updcount||':'||
         p_spcdiff.recname||':'||
         p_spcdiff.ddlspacename||'->'||
         p_spcdiff.tablespace_name);
   END LOOP;
   CLOSE c_spcdiff;
   sys.dbms_output.put_line(''||l_updcount||' records updated.');
END;
/

spool off

