CREATE OR REPLACE PACKAGE dehex AS
FUNCTION dehex(p_string VARCHAR2) RETURN VARCHAR2;
PRAGMA restrict_references(dehex,wnds,wnps);
END dehex;
/

CREATE OR REPLACE PACKAGE BODY dehex AS
FUNCTION dehex(p_string VARCHAR2) RETURN VARCHAR2 IS
   l_string VARCHAR2(4000);
BEGIN
   l_string := p_string;
   WHILE INSTR(l_string,'%')>0 LOOP
      l_string := 
      SUBSTR(l_string,
         1,
         INSTR(l_string,'%')-1
      )
      ||CHR(
         TO_NUMBER(
            SUBSTR(l_string
               ,   INSTR(l_string,'%')+1
               ,   2
               )
            ,   'XXXXXXXX'
         )
      )
      ||SUBSTR(l_string
      ,   INSTR(l_string,'%')+3
      );
   END LOOP;
   RETURN l_string;
   END dehex;
END dehex;
/

create or replace trigger weblogic_query_string_dehex 
BEFORE INSERT OR UPDATE on weblogic
FOR EACH ROW
BEGIN
   :new.query_string1 := dehex.dehex(:new.query_String1);
   :new.query_string2 := dehex.dehex(:new.query_String2);
   :new.query_string3 := dehex.dehex(:new.query_String3);
   :new.query_string4 := dehex.dehex(:new.query_String4);
   :new.query_string5 := dehex.dehex(:new.query_String5);
   :new.query_string6 := dehex.dehex(:new.query_String6);
   :new.query_string7 := dehex.dehex(:new.query_String7);
   :new.query_string8 := dehex.dehex(:new.query_String8);
END;
/
;