spool wl_pre

DROP TABLE weblogic;
DROP SYNONYM weblogic;
DROP VIEW weblogic;
DROP TABLE apache;
DROP SYNONYM apache;
DROP VIEW apache;
CREATE SYNONYM apache for weblogic;

CREATE TABLE weblogic
(timestamp      DATE             NOT NULL
--     CONSTRAINT weblogic_timestamp_min CHECK (timestamp >= TO_DATE('200209260900','YYYYMMDDHH24MI'))
,duration       NUMBER(9,3)      NOT NULL
,bytes_sent     NUMBER(7)        NOT NULL
,return_status  NUMBER(3)     
,remote_host1   VARCHAR2(3)      NOT NULL
,remote_host2   VARCHAR2(3)      NOT NULL
,remote_host3   VARCHAR2(3)      NOT NULL
,remote_host4   VARCHAR2(3)      NOT NULL
,remote_dns     VARCHAR2(100)          
,user_agent     VARCHAR2(1000)          
,request_method VARCHAR2(8)      
,request_status NUMBER(4)        
,url            VARCHAR2(4000)   NOT NULL
--     CONSTRAINT weblogic_url CHECK (not url like '%HR88%')
,query_string1  VARCHAR2(4000)          
,query_string2  VARCHAR2(4000)     
,query_string3  VARCHAR2(4000)     
,query_string4  VARCHAR2(4000)     
,query_string5  VARCHAR2(4000)     
,query_string6  VARCHAR2(4000)     
,query_string7  VARCHAR2(4000)     
,query_string8  VARCHAR2(4000)     
--,proxy_seq    NUMBER DEFAULT 0 NOT NULL
--,web_seq      NUMBER DEFAULT 0 NOT NULL
--,tuxedo_seq   NUMBER 
,scenario       NUMBER DEFAULT 0
,domain         VARCHAR2(10)
)
--partition by range(timestamp) (
--PARTITION weblogic_maxvalue VALUES LESS THAN (maxvalue)
--)
;

@dehex

CREATE OR REPLACE TRIGGER weblogic_domain 
BEFORE INSERT OR UPDATE ON weblogic
FOR EACH ROW
BEGIN
    IF UPPER(:new.url) like '%/F84D/%' THEN
        :new.domain := 'F84D';
    ELSIF UPPER(:new.url) like '%/HR88/%' THEN
        :new.domain := 'HR88';
    END IF;
END;
/

show errors


--create or replace view weblogic_scenario
--as 
--select scenario
--, min(timestamp) min_timestamp
--, max(timestamp) max_timestamp
--, (max(timestamp)-min(timestamp))*1440 minutes
--from weblogic
--where scenario > 0
--group by scenario
--;

exit
