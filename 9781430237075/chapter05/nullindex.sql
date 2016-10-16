REM nullindex.sql
REM (c) Go-Faster Consultancy Ltd. 2004

DROP TABLE dmk;
spool nullindex
CREATE TABLE dmk(a number,b number,c number,d number);
CREATE UNIQUE INDEX dmk ON dmk(a,b,c);
INSERT INTO dmk VALUES (null,null,0,1);
INSERT INTO dmk VALUES (null,null,0,2) /*this insert fails - correctly*/;
INSERT INTO dmk VALUES (null,null,null,3);
INSERT INTO dmk VALUES (null,null,null,4) /*this insert succeeds!*/;
ANALYZE TABLE dmk COMPUTE STATISTICS;
SELECT * FROM dmk;
SELECT num_rows FROM user_tables WHERE table_name = 'DMK';
SELECT num_rows FROM user_indexes WHERE index_name = 'DMK';
spool off
DrOP TABLE dmk;