REM lmtinitial.sql
REM (c) Go-Faster Consultancy Ltd. 2004
set echo on feedback on head on trimspool on
DROP TABLE dmk;
set lines 80
spool lmtinitial

SELECT tablespace_name, block_size, initial_extent, extent_management
FROM dba_tablespaces WHERE tablespace_name = 'HRAPP';

CREATE TABLE dmk (a NUMBER) TABLESPACE hrapp 
STORAGE (INITIAL 100K NEXT 50K MINEXTENTS 2);

COMPUTE SUM OF bytes ON REPORT
COMPUTE SUM OF blocks ON REPORT
BREAK ON REPORT

SELECT 	extent_id, bytes, blocks, tablespace_name
FROM 	user_extents
WHERE 	segment_name = 'DMK'
AND 	segment_type = 'TABLE'
;

spool off
DROP TABLE dmk;
