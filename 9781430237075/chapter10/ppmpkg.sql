rem ppmpkg

CREATE OR REPLACE PACKAGE ppm AS 
 FUNCTION date_ceil (p_datetime DATE, p_roundsecs INTEGER) RETURN DATE;
 FUNCTION date_floor(p_datetime DATE, p_roundsecs INTEGER) RETURN DATE;
 FUNCTION date_round(p_datetime DATE, p_roundsecs INTEGER) RETURN DATE;
 FUNCTION linear(p_date1 DATE,p_val1 NUMBER
                ,p_date2 DATE,p_val2 NUMBER
                ,p_date  DATE) RETURN NUMBER;
END ppm;
/

show errors
------------------------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ppm AS 
------------------------------------------------------------------------------------------------
FUNCTION date_ceil(p_datetime DATE,p_roundsecs INTEGER) RETURN DATE IS 
BEGIN
 RETURN TRUNC(p_datetime)+CEIL(TO_NUMBER(TO_CHAR(p_datetime,'SSSSS'))/p_roundsecs)*p_roundsecs/86400;
END date_ceil;
------------------------------------------------------------------------------------------------
FUNCTION date_floor(p_datetime DATE,p_roundsecs INTEGER) RETURN DATE IS 
BEGIN
 RETURN TRUNC(p_datetime)+FLOOR(TO_NUMBER(TO_CHAR(p_datetime,'SSSSS'))/p_roundsecs)*p_roundsecs/86400;
END date_floor;
------------------------------------------------------------------------------------------------
FUNCTION date_round(p_datetime DATE,p_roundsecs INTEGER) RETURN DATE IS 
BEGIN
 RETURN TRUNC(p_datetime)+ROUND(TO_NUMBER(TO_CHAR(p_datetime,'SSSSS'))/p_roundsecs,0)*p_roundsecs/86400;
END date_round;
------------------------------------------------------------------------------------------------
FUNCTION linear(p_date1 DATE,p_val1 NUMBER
               ,p_date2 DATE,p_val2 NUMBER
               ,p_date  DATE) RETURN NUMBER IS 
 l_date DATE;
BEGIN
 IF p_date1 IS NULL OR p_val1 IS NULL OR 
    p_date2 IS NULL OR p_val2 IS NULL OR 
    p_date IS NULL THEN
  RETURN NULL;
 ELSIF p_date1=p_date2 THEN
  RETURN p_val1;
 ELSE
  RETURN p_val1+(p_date-p_date1)*(p_val2-p_val1)/(p_date2-p_date1);
 END IF;
END linear;
------------------------------------------------------------------------------------------------
END ppm;
/

show errors

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW dmk_pmeventhist_round_vw AS
SELECT	x.*
,	ppm.linear(pm_agent_dttm, pm_metric_value1,next_agent_dttm, next_metric_value1,adj_agent_dttm) comp_metric_value1
,	ppm.linear(pm_agent_dttm, pm_metric_value2,next_agent_dttm, next_metric_value2,adj_agent_dttm) comp_metric_value2
,	ppm.linear(pm_agent_dttm, pm_metric_value3,next_agent_dttm, next_metric_value3,adj_agent_dttm) comp_metric_value3
,	ppm.linear(pm_agent_dttm, pm_metric_value4,next_agent_dttm, next_metric_value4,adj_agent_dttm) comp_metric_value4
,	ppm.linear(pm_agent_dttm, pm_metric_value5,next_agent_dttm, next_metric_value5,adj_agent_dttm) comp_metric_value5
,	ppm.linear(pm_agent_dttm, pm_metric_value6,next_agent_dttm, next_metric_value6,adj_agent_dttm) comp_metric_value6
FROM	(
	SELECT	b.pm_systemid, c.*
	,	ppm.date_ceil(c.pm_agent_dttm,b.pm_sample_int) adj_agent_dttm
	FROM	(
		SELECT	c.pm_event_defn_set, c.pm_event_defn_id, c.pm_instance_id, c.pm_agentid, c.pm_process_id
		,	c.pm_agent_dttm  ,  LEAD(c.pm_agent_dttm)    OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id ORDER BY c.pm_agent_dttm) next_agent_dttm
		, 	c.pm_metric_value1, LEAD(c.pm_metric_value1) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id ORDER BY c.pm_agent_dttm) next_metric_value1
		, 	c.pm_metric_value2, LEAD(c.pm_metric_value2) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id ORDER BY c.pm_agent_dttm) next_metric_value2
		, 	c.pm_metric_value3, LEAD(c.pm_metric_value3) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id ORDER BY c.pm_agent_dttm) next_metric_value3
		, 	c.pm_metric_value4, LEAD(c.pm_metric_value4) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id ORDER BY c.pm_agent_dttm) next_metric_value4
		, 	c.pm_metric_value5, LEAD(c.pm_metric_value5) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id ORDER BY c.pm_agent_dttm) next_metric_value5
		, 	c.pm_metric_value6, LEAD(c.pm_metric_value6) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id ORDER BY c.pm_agent_dttm) next_metric_value6
		, 	c.pm_metric_value7
		,	longtochar.pspmeventhist(c.rowid) pm_addtnl_descr
--		,	dbms_lob.substr(c.pm_addtnl_descr) pm_addtnl_descr
		FROM	pspmeventhist c
--		FROM	pspmeventarch c
		) c
	, 	pspmagent A, pspmsysdefn b
	where	b.pm_systemid = a.pm_systemid
	AND 	a.pm_agentid = c.pm_agentid
	and	c.next_agent_dttm-c.pm_agent_dttm < 2*b.pm_sample_int/86400
	and	c.next_agent_dttm IS NOT NULL
	) x
WHERE 	adj_agent_dttm >= pm_agent_dttm 
AND	adj_agent_dttm <  next_agent_dttm
/
CREATE OR REPLACE VIEW dmk_pmeventhist_round302_vw AS
SELECT	x.*
--,	ppm.linear(pm_agent_dttm, pm_metric_value1,next_agent_dttm, next_metric_value1,adj_agent_dttm) comp_metric_value1
,	ppm.linear(pm_agent_dttm, pm_metric_value2,next_agent_dttm, next_metric_value2,adj_agent_dttm) comp_metric_value2
--,	ppm.linear(pm_agent_dttm, pm_metric_value3,next_agent_dttm, next_metric_value3,adj_agent_dttm) comp_metric_value3
,	ppm.linear(pm_agent_dttm, pm_metric_value4,next_agent_dttm, next_metric_value4,adj_agent_dttm) comp_metric_value4
,	ppm.linear(pm_agent_dttm, pm_metric_value5,next_agent_dttm, next_metric_value5,adj_agent_dttm) comp_metric_value5
,	ppm.linear(pm_agent_dttm, pm_metric_value6,next_agent_dttm, next_metric_value6,adj_agent_dttm) comp_metric_value6
FROM	(
	SELECT	b.pm_systemid, c.*
	,	ppm.date_ceil(c.pm_agent_dttm,b.pm_sample_int) adj_agent_dttm
	FROM	(
		SELECT	c.pm_event_defn_set, c.pm_event_defn_id, c.pm_instance_id, c.pm_agentid, c.pm_process_id
		,	c.pm_agent_dttm  ,  LEAD(c.pm_agent_dttm,1)    OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id, c.pm_metric_value1, c.pm_metric_value3 ORDER BY c.pm_agent_dttm) next_agent_dttm
		, 	c.pm_metric_value1 --, LEAD(c.pm_metric_value1,1) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id, c.pm_metric_value1, c.pm_metric_value3 ORDER BY c.pm_agent_dttm) next_metric_value1
		, 	c.pm_metric_value2, LEAD(c.pm_metric_value2,1) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id, c.pm_metric_value1, c.pm_metric_value3 ORDER BY c.pm_agent_dttm) next_metric_value2
		, 	c.pm_metric_value3 --, LEAD(c.pm_metric_value3,1) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id, c.pm_metric_value1, c.pm_metric_value3 ORDER BY c.pm_agent_dttm) next_metric_value3
		, 	c.pm_metric_value4, LEAD(c.pm_metric_value4,1) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id, c.pm_metric_value1, c.pm_metric_value3 ORDER BY c.pm_agent_dttm) next_metric_value4
		, 	c.pm_metric_value5, LEAD(c.pm_metric_value5,1) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id, c.pm_metric_value1, c.pm_metric_value3 ORDER BY c.pm_agent_dttm) next_metric_value5
		, 	c.pm_metric_value6, LEAD(c.pm_metric_value6,1) OVER (PARTITION BY c.pm_event_defn_set, c.pm_event_defn_id, c.pm_agentid, c.pm_process_id, c.pm_metric_value1, c.pm_metric_value3 ORDER BY c.pm_agent_dttm) next_metric_value6
		, 	c.pm_metric_value7
		,	longtochar.pspmeventhist(c.rowid) pm_addtnl_descr
--		,	dbms_lob.substr(c.pm_addtnl_descr) pm_addtnl_descr
		FROM	pspmeventhist c
--		FROM	pspmeventarch c
		WHERE 	c.pm_event_defn_set = 1
		and	c.pm_event_defn_id = 302 /*PSR*/
--		and	c.pm_agent_dttm < TO_DATE('04112008','DDMMYYYY')
		) c
	, 	pspmagent A, pspmsysdefn b
	where	b.pm_systemid = a.pm_systemid
	AND 	a.pm_agentid = c.pm_agentid
	and	c.next_agent_dttm-c.pm_agent_dttm < 2*b.pm_sample_int/86400
	and	c.next_agent_dttm IS NOT NULL
	) x
WHERE 	adj_agent_dttm >= pm_agent_dttm 
AND	adj_agent_dttm <  next_agent_dttm
/
