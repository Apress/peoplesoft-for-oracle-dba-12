rem prcsarch.sql
set head off trimout on trimspool on message off feedback off timi off echo off
spool prcsarch0.sql
SELECT 'CREATE OR REPLACE TRIGGER '||user||'.psprcsrqst_archive'
FROM 	dual
;
SELECT 'before delete on '||user||'.psprcsrqst'
FROM 	dual
;
SELECT 'for each row'
FROM 	dual
;
SELECT 'begin'
FROM 	dual
;
SELECT '   insert into '||user||'.ps_prcsrqstarch'
FROM 	dual
;
SELECT '   '||DECODE(column_id,1,'(',',')||column_name
FROM 	user_tab_columns
WHERE 	table_name = 'PSPRCSRQST'
ORDER BY column_id
;
SELECT 	'   ) values'
FROM 	dual
;
SELECT '   '||DECODE(column_id,1,'(',',')||':old.'||column_name
FROM 	user_tab_columns
WHERE 	table_name = 'PSPRCSRQST'
ORDER BY column_id
;
SELECT '   );'
FROM dual
;
SELECT 'end;'
FROM dual
;
SELECT '/'
FROM dual
;
spool off
set head on message on feedback on echo on
spool prcsarch
@prcsarch0
show errors
set echo off
SELECT COUNT(*) psprcsrqst      FROM psprcsrqst;
DELETE                          FROM psprcsrqst WHERE runstatus=2;
SELECT COUNT(*) psprcsrqst      FROM psprcsrqst;
SELECT COUNT(*) ps_prcsrqstarch FROM ps_prcsrqstarch;
ROLLBACK;
spool off
