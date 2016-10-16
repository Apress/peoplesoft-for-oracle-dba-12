create or replace view dmk_long_columns
as select table_name,column_name
from	user_tab_columns
where	data_type = 'LONG'
and	table_name like 'PSPMEVENTHIST'
;

set termout off
set head off
set trimout on
set trimspool on
set message off
set echo off
set timi off
set pause off
set feedback off
set lines 80
spool longtochar0.sql

select 'create or replace package '||user||'.longtochar as'
from dual
;
select 	'function '||table_name||'(p_rowid ROWID) return varchar2;',
	'pragma restrict_references('||table_name||',wnds,wnps);'
from dmk_long_columns
;
select 	'end longtochar;                                            ',
	'/                                                          '
from dual
;

select 'create or replace package body '||user||'.longtochar as'
from dual
;

select	'function '||table_name||'(p_rowid ROWID) RETURN VARCHAR2 is',
	'      l_long VARCHAR2(32767):='''';                        ',
	'   BEGIN                                                   ',
	'      SELECT '||column_name||' INTO l_long                 ',
	'      FROM '||user||'.'||table_name||'                     ',
        '      WHERE  rowid = p_rowid;                              ',
	'   RETURN l_long;                                          ',
	'end '||table_name||';                                      '
from dmk_long_columns
;

select 	'end longtochar;                                            ',
	'/                                                          '
from dual
;

spool off
set termout on
set head on
set message on
set echo on
set feedback on
set timi on
pause
spool longtochar0
@longtochar0
show errors






