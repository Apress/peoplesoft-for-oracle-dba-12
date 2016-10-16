select 	DISTINCT dbname, pm_host, pm_port, pm_domain_name, pm_agent_dttm
,	pm_instance
, 	PM_METRIC_VALUE1 server_instance
,	PM_METRIC_VALUE7 process
,       PM_ADDTNL_DESCR service
from (
SELECT 	B.DBNAME, 
       	SUBSTR(A.PM_HOST_PORT,1,INSTR(A.PM_HOST_PORT,':')-1) PM_HOST, 
       	SUBSTR(A.PM_HOST_PORT,INSTR(A.PM_HOST_PORT,':')+1) PM_PORT, 
	A.PM_INSTANCE,
	A.PM_DOMAIN_NAME, 
       	ppm.date_floor(C.PM_AGENT_DTTM,B.PM_SAMPLE_INT) pm_agent_dttm,
       	C.PM_METRIC_VALUE1 /*server_instance*/, 
	C.PM_METRIC_VALUE7 /*process*/,
       	longtochar.pspmeventhist(C.rowid) PM_ADDTNL_DESCR --service name
FROM   PSPMAGENT A, PSPMSYSDEFN B, PSPMEVENTHIST C
WHERE  B.PM_SYSTEMID = A.PM_SYSTEMID 
AND    A.PM_AGENT_INACTIVE = 'N'
AND    A.PM_AGENTID = C.PM_AGENTID 
AND    C.PM_EVENT_DEFN_SET = 1 
AND    C.PM_EVENT_DEFN_ID = 302 --Tuxedo PSR data
AND    C.PM_METRIC_VALUE7 LIKE 'PS%' --a peoplesoft process
AND    A.PM_DOMAIN_TYPE = '01' --App Server
) 
ORDER BY PM_AGENT_DTTM, pm_host, pm_port, pm_domain_name
