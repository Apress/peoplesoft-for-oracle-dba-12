spool txrpt_post

CREATE unique index txrpt 
ON txrpt(service,pid,stimestamp,stime,etime)
TABLESPACE indx 
NOLOGGING
;

@service_fix

lock TABLE txrpt in exclusive mode;

CREATE index txrpt2
ON txrpt(queue,stime,etime,stimestamp)
TABLESPACE indx 
NOLOGGING
;

create or replace view txrpt_cum_svc_vw
as 
SELECT	timestamp
,	service
,	svc_time
,	sum(num_requests) over (partition by timestamp, service order by svc_time) num_requests
,	sum(cum_svc_time) over (partition by timestamp, service order by svc_time) cum_svc_time
,	sum(pct_request) over (partition by timestamp, service order by svc_time) pct_request
,	sum(pct_cum_svc_time) over (partition by timestamp, service order by svc_time) pct_cum_svc_time
FROM	(
	SELECT	timestamp
	,	service
	,	svc_time
	,	num_requests
	,	cum_svc_time
	,	ratio_to_report(num_requests) over (partition by timestamp, service) pct_request
	,	ratio_to_report(cum_svc_time) over (partition by timestamp, service) pct_cum_svc_time		FROM	(
		SELECT 	trunc(stimestamp) timestamp
		, 	service
		, 	round(etime-stime,2) svc_time
		, 	Count(*) num_requests
		, 	round(etime-stime,2)*Count(*) cum_svc_time
		FROM 	SCOTT.txrpt txrpt
		WHERE	etime>stime
--		AND	service IN('ICScript','ICPanel')
--		AND	TO_NUMBER(TO_CHAR(stimestamp,'d')) between 1 and 5
		GROUP BY trunc(stimestamp), service, round(etime-stime,2)
		)
	)
/

exit
