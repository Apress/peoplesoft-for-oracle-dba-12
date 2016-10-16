DROP TABLE txrpt;
DROP VIEW  txrpt;

CREATE TABLE txrpt
(service	VARCHAR2(20)	NOT NULL
,pid		NUMBER(6)   	NOT NULL
,stimestamp	DATE        	NOT NULL
,stime		NUMBER(10,3) 	NOT NULL
,etime		NUMBER(10,3) 	NOT NULL
,queue		VARCHAR2(5) 	DEFAULT 'XXXXX' NOT NULL
,concurrent	NUMBER(2) 	DEFAULT 0 	NOT NULL
,scenario	NUMBER(2)	DEFAULT 0	NOT NULL
);

CREATE unique index txrpt 
ON txrpt(service,pid,stimestamp,stime,etime);

exit
