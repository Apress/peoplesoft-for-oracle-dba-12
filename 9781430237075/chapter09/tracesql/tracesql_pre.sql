spool tracesql_pre

DROP TABLE tracesql;
DROP VIEW tracesql;
--TRuNCATE TABLE tracesql;

CREATE TABLE tracesql
(program         VARCHAR2(12)   DEFAULT 'Client' NOT NULL
,pid             NUMBER         DEFAULT 0        NOT NULL
,line_id         NUMBER                          NOT NULL
,line_num        NUMBER                          NOT NULL
,timestamp       DATE                            NOT NULL
,time_since_last NUMBER                          NOT NULL
,cursor          NUMBER                          NOT NULL
,database        VARCHAR2(10)                    NOT NULL
,return_code     NUMBER                          NOT NULL
,duration        NUMBER                          NOT NULL
,operation       VARCHAR2(4000)                  NOT NULL
,parent_line_num NUMBER         DEFAULT 0        NOT NULL 
--,CONSTRAINT nonzero CHECK (duration>0 OR time_since_last>0)
);

CREATE UNIQUE INDEX tracesql
ON tracesql
(database,program,pid,line_id,cursor,line_num,timestamp)
TABLESPACE indx 
NOLOGGING 
COMPRESS
;

CREATE OR REPLACE PACKAGE cleansql AS
FUNCTION cleansql(p_operation VARCHAR2) RETURN VARCHAR2;
PRAGMA restrict_references(cleansql,wnds,wnps);
END cleansql;
/

CREATE OR REPLACE PACKAGE BODY cleansql AS
FUNCTION cleansql(p_operation VARCHAR2) RETURN VARCHAR2 IS
   l_newop     VARCHAR2(4000) := '';           --output string
   l_char      VARCHAR2(1)    := '';           --current char in input string
   l_inquote   BOOLEAN        := FALSE;        --are we in a quoted string
   l_inlitnum  BOOLEAN        := FALSE;        --are we in literal number
   l_lastchar  VARCHAR2(1)    := '';           --last char in output string
   l_len       INTEGER;                        --length of input string
   l_opsym     VARCHAR2(20)   := ' =<>+-*/,';  --string of symbols
   l_nextchar  VARCHAR2(1);                    --next character
   l_numbers   VARCHAR2(20)   := '1234567890'; --string of symbols
   l_pos       INTEGER        := 1;            --current pos in input string
BEGIN
   l_len := LENGTH(p_operation);
   WHILE (l_pos <= l_len) LOOP
      l_lastchar := l_char;
      l_char := SUBSTR(p_operation,l_pos,1);
      l_nextchar := SUBSTR(p_operation,l_pos+1,1);
      l_pos := l_pos+1;
      IF l_char = CHR(39) THEN -- we are on a quote mark
         IF l_inquote THEN -- coming out of quote
            l_inquote := FALSE;
         ELSE --going into quote
            l_inquote := TRUE;
            l_newop := l_newop||':';
         END IF;
         l_char := '';
      END IF;
      IF l_inquote THEN
         l_char := '';
      ELSIF (l_char = ' ' 
             AND INSTR(l_opsym,l_lastchar)>0) THEN --after symbol supress space
         l_char := '';
      ELSIF (l_lastchar = ' ' 
             AND INSTR(l_opsym,l_char)>0) THEN -- supress space before symbol
         l_newop := SUBSTR(l_newop,1,LENGTH(l_newop)-1)||l_char;
         l_char := '';
      END IF;

      IF (l_inlitnum) THEN --in a number
         IF (l_char = '.' 
             AND INSTR(l_numbers,l_lastchar)>0 
             AND INSTR(l_numbers,l_nextchar)>0) THEN
            l_inlitnum := TRUE; --still a number if a decimal point
         ELSIF (INSTR(l_numbers,l_char)=0) THEN -- number has finished
            l_inlitnum := FALSE;
         ELSE -- number continues
            l_char := '';
         END IF;
      ELSIF (NOT l_inlitnum 
             AND INSTR(l_opsym,l_lastchar)>0 
             AND INSTR(l_numbers,l_char)>0) THEN --start literal
         l_newop := l_newop||':';
         l_char := '';
         l_inlitnum := TRUE;
      END IF;

      l_newop := l_newop||l_char;

      IF l_newop = 'CEX Stmt=' THEN
         l_newop := '';
      END IF;
   END LOOP;        
    RETURN l_newop;
END cleansql;
END cleansql;
/
show errors

CREATE OR REPLACE TRIGGER tracesql
BEFORE INSERT on tracesql
FOR EACH ROW
DECLARE
   l_parent_line_num INTEGER;
BEGIN
   :new.operation := cleansql.cleansql(:new.operation);
/*
   IF :new.operation = 'Fetch' THEN
      SELECT MAX(a.line_num)
      INTO   l_parent_line_num
      FROM   tracesql a
      WHERE  (a.operation LIKE 'COM Stmt=%'
      OR      a.operation LIKE 'CEX Stmt=%')
      AND    a.database  = :new.database
      AND    a.program   = :new.program
      AND    a.pid       = :new.pid
      AND    a.line_id   = :new.line_id
      AND    a.line_num  < :new.line_num
      AND    a.cursor    = :new.cursor
      AND    a.timestamp <= :new.timestamp
      ;
      :new.parent_line_num := l_parent_line_num;
   END IF;
*/
END;
/
;

show errors

exit
