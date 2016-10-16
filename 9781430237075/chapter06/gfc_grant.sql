REM gfc_grant
REM PeopleSoft for the Oracle DBA 2nd Ed, Listing 6-18
REM (c)Go-Faster Consultancy Ltd. 2012

CREATE OR REPLACE PROCEDURE myddl (p_ddl IN VARCHAR2) IS
BEGIN
EXECUTE IMMEDIATE p_ddl;
END;
/

CREATE OR REPLACE TRIGGER gfc_grant
AFTER CREATE ON sysadm.schema
DECLARE
 l_jobno NUMBER;
BEGIN
 IF ora_dict_obj_type = 'TABLE' THEN
  dbms_job.submit(l_jobno,'myddl(''GRANT SELECT ON '
                           ||ora_dict_obj_owner||'.'||ora_dict_obj_name||' TO gofaster'');');
 END IF;
END;
/

