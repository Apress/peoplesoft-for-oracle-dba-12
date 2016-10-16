REM trace_remotecall.sql
REM (c)Go-Faster Consultancy 2012

spool trace_trigger81
rem requires following grants to be made explicitly by sys
rollback;

grant alter session to sysadm;

CREATE OR REPLACE TRIGGER sysadm.trace_remotecall
BEFORE INSERT ON sysadm.ps_message_log
FOR EACH ROW
WHEN (new.process_instance = 0
and   new.message_seq      = 1
and   new.program_name     = 'GLPJEDIT'
and   new.dttm_stamp_sec  <= TO_DATE('200407231500','YYYYMMDDHH24MI')
)
begin
   EXECUTE IMMEDIATE 'alter session set TIMED_STATISTICS = TRUE';
   EXECUTE IMMEDIATE 'alter session set MAX_DUMP_FILE_SIZE = 2048000';
   EXECUTE IMMEDIATE 'alter session set TRACEFILE_IDENTIFIER = '''||
		replace(:new.program_name,' -','__')||'''';

   /* disk waits(8) and bind variables(4)*/
   EXECUTE IMMEDIATE 'alter session set events ''10046 trace name context forever, level 8''';

EXCEPTION WHEN OTHERS THEN NULL;
end;
/

show errors

update  sysadm.psprcsrqst
set     runstatus = 7
where   runstatus != 7
and 	prcstype IN('Application Engine','COBOL SQL',
	   'SQR Process','SQR Report','SQR Report For WF Delivery')
and	dbname = 'ABPRD'
and	rownum = 0
;

rollback;
spool off
