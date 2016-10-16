spool tuxlog_pre

DROP TABLE tuxlog;

CREATE TABLE tuxlog
(timestamp  DATE         NOT NULL
,nodename   VARCHAR2(20) NOT NULL
,prcsname   VARCHAR2(20) NOT NULL
,prcsid     VARCHAR2(20) NOT NULL
,funcname   VARCHAR2(20) NOT NULL
     CONSTRAINT funcname CHECK (funcname IN('tpservice','tpreturn'))
,service    VARCHAR2(20) NOT NULL
,msg_size   NUMBER(8)
);


exit

