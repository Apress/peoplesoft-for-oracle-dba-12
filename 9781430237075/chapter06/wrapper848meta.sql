REM wrapper848meta.sql
REM dbms_stats wrapper script for Oracle 10gR2 PT>=8.48
REM 12. 2.2009 force stats collection on regular tables, skip GTTs
REM 24. 3.2009 added refresh procedure for partitioned objects, gather_table_stats proc for wrapping
REM 26. 5.2009 meta data to control behaviour by PS record
REM 23. 6.2009 collect stats on private instance of GTTs
REM  1.10.2009 change default behaviour if no meta data to gather stats, add extra meta data to suppress stats for rest of TL_TIMEADMIN
REM  2.10.2009 enhanced messages in verbose mode
REM  5. 5.2011 add block sample support

clear screen
set echo on serveroutput on lines 100 wrap off
spool wrapper848meta

ROLLBACK --just to be safe
/

------------------------------------------------------------------------------------------------
--This record should be created in Application Designer
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--DROP TABLE ps_gfc_stats_ovrd;
CREATE TABLE ps_gfc_stats_ovrd 
(  RECNAME          VARCHAR2(15)  NOT NULL, --peoplesoft record name
   GATHER_STATS     VARCHAR2(1)   NOT NULL, --(G)ather Stats / (R)efresh Stats / Do(N)t Gather Stats / (R)efresh stale Stats
   ESTIMATE_PERCENT VARCHAR2(30)  NOT NULL, --dbms_stats sample size - 0 implies automatic sample size
   BLOCK_SAMPLE     VARCHAR2(1)   NOT NULL,
   METHOD_OPT       VARCHAR2(1000)          --same as dbms_stats method_opt parameter
) TABLESPACE PTTBL 
STORAGE (INITIAL 40000 NEXT 100000 MAXEXTENTS UNLIMITED PCTINCREASE 0) 
PCTFREE 10 PCTUSED 80
/
ALTER TABLE ps_gfc_stats_ovrd ADD block_sample VARCHAR2(1)
/
UPDATE ps_gfc_stats_ovrd SET block_sample = ' ' WHERE block_sample IS NULL
/
ALTER TABLE ps_gfc_stats_ovrd MODIFY block_sample NOT NULL
/
   
CREATE UNIQUE  iNDEX ps_gfc_stats_ovrd ON ps_gfc_stats_ovrd (RECNAME)
 TABLESPACE PSINDEX STORAGE (INITIAL 40000 NEXT 100000 MAXEXTENTS
 UNLIMITED PCTINCREASE 0) PCTFREE 10 PARALLEL NOLOGGING
/
ALTER INDEX ps_gfc_stats_ovrd NOPARALLEL LOGGING
/


------------------------------------------------------------------------------------------------
--This function based index is required on PSRECDEFN, but cannot be defined in Application Designer
------------------------------------------------------------------------------------------------
CREATE INDEX pszpsrecdefn_fbi 
ON psrecdefn (DECODE(sqltablename,' ','PS_'||recname,sqltablename))
TABLESPACE PSINDEX PCTFREE 0
/


CREATE OR REPLACE PACKAGE wrapper AS
------------------------------------------------------------------------------------------------
--Procedure to refresh stale stats on table, partition AND subpartition
--24.3.2009 added refresh procedure for partitioned objects, gather_table_stats proc for wrapping
-- 2.4.2009 added flush table monitoring stats to refresh stats pacakge
------------------------------------------------------------------------------------------------
PROCEDURE refresh_stats
(p_ownname             IN VARCHAR2 /*owner of table*/
,p_tabname             IN VARCHAR2 /*table name*/
,p_estpct              IN NUMBER   DEFAULT NULL /*size of sample - 0 or NULL means dbms_stats default*/
,p_method_opt          IN VARCHAR2 DEFAULT NULL
,p_stale_threshold_pct IN INTEGER  DEFAULT 10
,p_block_sample        IN BOOLEAN  DEFAULT FALSE /*if true block sample stats*/
,p_force               IN BOOLEAN  DEFAULT FALSE
,p_verbose             IN BOOLEAN  DEFAULT FALSE /*if true print SQL*/
);
------------------------------------------------------------------------------------------------
--procedure called from DDL model for %UpdateStats
--24.3.2009 adjusted to call local dbms_stats AND refresh stats
------------------------------------------------------------------------------------------------
PROCEDURE ps_stats 
(p_ownname      IN VARCHAR2 /*owner of table*/
,p_tabname      IN VARCHAR2 /*table name*/
,p_estpct       IN NUMBER  DEFAULT NULL /*size of sample: 0 or NULL means dbms_stats default*/
,p_verbose      IN BOOLEAN DEFAULT FALSE /*if true print SQL*/
);
END wrapper;
/

CREATE OR REPLACE PACKAGE BODY wrapper AS

 g_lf VARCHAR2(1) := CHR(10); --line feed character
 table_stats_locked EXCEPTION;
 PRAGMA EXCEPTION_INIT(table_stats_locked,-20005);

------------------------------------------------------------------------------------------------
--wrapper for dbms_stats package procedure with own logic
------------------------------------------------------------------------------------------------
 PROCEDURE gather_table_stats
 (p_ownname       IN VARCHAR2 
 ,p_tabname       IN VARCHAR2 
 ,p_partname      IN VARCHAR2 DEFAULT NULL
 ,p_estpct        IN NUMBER   DEFAULT NULL
 ,p_block_sample  IN BOOLEAN  DEFAULT FALSE
 ,p_method_opt    IN VARCHAR2 DEFAULT NULL
 ,p_degree        IN NUMBER   DEFAULT NULL
 ,p_granularity   IN VARCHAR2 DEFAULT NULL
 ,p_cascade       IN BOOLEAN  DEFAULT NULL
 ,p_stattab       IN VARCHAR2 DEFAULT NULL 
 ,p_statid        IN VARCHAR2 DEFAULT NULL
 ,p_statown       IN VARCHAR2 DEFAULT NULL
 ,p_no_invalidate IN BOOLEAN  DEFAULT NULL
 ,p_force         IN BOOLEAN  DEFAULT FALSE
 ,p_verbose       IN BOOLEAN  DEFAULT FALSE /*if true print SQL*/
 ) IS
  l_sql VARCHAR2(4000 CHAR);
 BEGIN
  l_sql := 'sys.dbms_stats.gather_table_stats'
           ||g_lf||'(ownname => :p_ownname'
           ||g_lf||',tabname => :p_tabname';

  IF p_partname IS NOT NULL THEN
   l_sql := l_sql||g_lf||',partname => '''||p_partname||'''';
  END IF;

  IF p_estpct > 0 THEN
   l_sql := l_sql||g_lf||',estimate_percent => '||p_estpct;
  END IF;

  IF p_block_sample IS NULL THEN
   NULL;
  ELSIF p_block_sample THEN
   l_sql := l_sql||g_lf||',block_sample => TRUE';
  ELSE
   l_sql := l_sql||g_lf||',block_sample => FALSE';
  END IF;

  IF p_method_opt IS NOT NULL THEN
   l_sql := l_sql||g_lf||',method_opt => '''||p_method_opt||'''';
  END IF;

  IF p_degree IS NOT NULL THEN
   l_sql := l_sql||g_lf||',degree => '||p_degree;
  END IF;

  IF p_granularity IS NOT NULL THEN
   l_sql := l_sql||g_lf||',granularity => '''||p_granularity||'''';
  END IF;

  IF p_cascade IS NULL THEN
   NULL;
  ELSIF p_cascade THEN
   l_sql := l_sql||g_lf||',cascade => TRUE';
  ELSE 
   l_sql := l_sql||g_lf||',cascade => FALSE';
  END IF;

  IF p_stattab IS NOT NULL THEN
   l_sql := l_sql||g_lf||',stattab => '''||p_stattab||'''';
  END IF;
  IF p_statid IS NOT NULL THEN
   l_sql := l_sql||g_lf||',statid => '''||p_statid||'''';
  END IF;
  IF p_statown IS NOT NULL THEN
   l_sql := l_sql||g_lf||',statown => '''||p_statown||'''';
  END IF;

  IF p_no_invalidate THEN
   l_sql := l_sql||g_lf||',no_invalidate => TRUE';
  END IF;

  IF p_force THEN
   l_sql := l_sql||g_lf||',force => TRUE';
  END IF;

  l_sql := l_sql||');';

  l_sql := 'BEGIN '||l_sql||' END;';

  IF p_verbose THEN
   dbms_output.put_line('Table:'||p_ownname||'.'||p_tabname||' @ '||TO_CHAR(SYSDATE,'hh24:mi:ss dd.mm.yyyy')); 
   dbms_output.put_line(l_sql); 
  END IF;
  EXECUTE IMMEDIATE l_sql USING IN p_ownname, p_tabname;

 END gather_table_stats;

------------------------------------------------------------------------------------------------
--check for stale/missing states in named table AND gather if stale
------------------------------------------------------------------------------------------------
 PROCEDURE refresh_stats
 (p_ownname             IN VARCHAR2
 ,p_tabname             IN VARCHAR2
 ,p_estpct              IN NUMBER   DEFAULT NULL
 ,p_method_opt          IN VARCHAR2 DEFAULT NULL
 ,p_stale_threshold_pct IN INTEGER  DEFAULT 10
 ,p_block_sample        IN BOOLEAN DEFAULT FALSE /*if true block sample stats*/
 ,p_force               IN BOOLEAN  DEFAULT FALSE
 ,p_verbose             IN BOOLEAN  DEFAULT FALSE /*if true print SQL*/
 ) IS
  l_force VARCHAR(1 CHAR);
 BEGIN
--IF p_verbose THEN
-- dbms_output.put_line('Checking for stale statistics');
--END IF;

  dbms_stats.flush_database_monitoring_info;

  IF p_force THEN --need this is a varchar for SQL
   l_force := 'Y';
  ELSE
   l_force := 'N';
  END IF;

  FOR i IN (
   SELECT p.table_owner, p.table_name, p.partition_name, p.subpartition_name
   FROM   all_tab_subpartitions p
          LEFT OUTER JOIN all_tab_modifications m
          ON  m.table_owner = p.table_owner
          AND m.table_name = p.table_name         
          AND m.partition_name = p.partition_name
          AND m.subpartition_name = p.subpartition_name
          LEFT OUTER JOIN all_tab_statistics s
          ON  s.owner = p.table_owner
          AND s.table_name = p.table_name
          AND s.partition_name = p.partition_name
          AND s.subpartition_name = p.subpartition_name
   WHERE  p.table_owner = p_ownname
   AND    p.table_name = p_tabname
   AND    (s.stattype_locked IS NULL OR l_force = 'Y')
   AND    (  p.num_rows IS NULL
          OR p.num_rows*p_stale_threshold_pct/100 <= (m.inserts+m.updates+m.deletes)
          OR m.truncated = 'YES'
 	 )
  ) LOOP 
   wrapper.gather_table_stats
   (p_ownname      => i.table_owner
   ,p_tabname      => i.table_name
   ,p_partname     => i.subpartition_name
   ,p_estpct       => p_estpct
   ,p_method_opt   => p_method_opt
   ,p_block_sample => p_block_sample
   ,p_cascade      => TRUE
   ,p_granularity  => 'SUBPARTITION'
   ,p_force        => p_force
   ,p_verbose      => p_verbose
   );
  END LOOP;

  FOR i IN (
   SELECT p.table_owner, p.table_name, p.partition_name
   FROM   all_tab_partitions p
          LEFT OUTER JOIN all_tab_modifications m
          ON  m.table_owner = p.table_owner
          AND m.table_name = p.table_name         
          AND m.partition_name = p.partition_name
          AND m.subpartition_name IS NULL
          LEFT OUTER JOIN all_tab_statistics s
          ON  s.owner = p.table_owner
          AND s.table_name = p.table_name
          AND s.partition_name = p.partition_name
          AND s.subpartition_name IS NULL
   WHERE  p.table_owner = p_ownname
   AND    p.table_name = p_tabname
   AND    (s.stattype_locked IS NULL OR l_force = 'Y')
   AND    (  p.num_rows IS NULL
          OR p.num_rows*p_stale_threshold_pct/100 <= (m.inserts+m.updates+m.deletes) 
          OR m.truncated = 'YES'
	  )
  ) LOOP
   wrapper.gather_table_stats
   (p_ownname      => i.table_owner
   ,p_tabname      => i.table_name
   ,p_partname     => i.partition_name
   ,p_estpct       => p_estpct
   ,p_method_opt   => p_method_opt
   ,p_block_sample => p_block_sample
   ,p_cascade      => TRUE
   ,p_granularity  => 'PARTITION'
   ,p_force        => p_force
   ,p_verbose      => p_verbose
   );
  END LOOP;

  FOR i IN (
   SELECT p.owner, p.table_name
   FROM   all_tables p
          LEFT OUTER JOIN all_tab_modifications m
          ON  m.table_owner = p.owner
          AND m.table_name = p.table_name         
          AND m.partition_name IS NULL
          AND m.subpartition_name IS NULL
          LEFT OUTER JOIN all_tab_statistics s
          ON  s.owner = p.owner
          AND s.table_name = p.table_name
          AND s.partition_name IS NULL
          AND s.subpartition_name IS NULL
   WHERE  p.owner = p_ownname
   AND    p.table_name = p_tabname
   AND    (s.stattype_locked IS NULL OR l_force = 'Y')
   AND    (  p.num_rows IS NULL
          OR p.num_rows*p_stale_threshold_pct/100 <= (m.inserts+m.updates+m.deletes)
          OR m.truncated = 'YES'
          )
  ) LOOP
   wrapper.gather_table_stats
   (p_ownname      => i.owner
   ,p_tabname      => i.table_name
   ,p_estpct       => p_estpct
   ,p_method_opt   => p_method_opt
   ,p_block_sample => p_block_sample
   ,p_cascade      => TRUE
   ,p_granularity  => 'GLOBAL'
   ,p_force        => p_force
   ,p_verbose      => p_verbose
   );
  END LOOP;

  IF p_verbose THEN
   dbms_output.put_line('Table:'||p_ownname||'.'||p_tabname||' finished @ '||TO_CHAR(SYSDATE,'hh24:mi:ss dd.mm.yyyy')); 
  END IF;

 END refresh_stats; 

------------------------------------------------------------------------------------------------
--public procedure called from DDL model for %UpdateStats
--12.2.2009 force stats collection on regular tables, skip GTTs
------------------------------------------------------------------------------------------------
 PROCEDURE ps_stats
 (p_ownname      IN VARCHAR2
 ,p_tabname      IN VARCHAR2
 ,p_estpct       IN NUMBER  DEFAULT NULL
 ,p_verbose      IN BOOLEAN DEFAULT FALSE /*if true print SQL*/
 ) IS
  l_temporary        VARCHAR2(1 CHAR);
  l_partitioned      VARCHAR2(1 CHAR);
  l_recname          VARCHAR2(15 CHAR);
  l_rectype          INTEGER;
  l_temptblinstance  VARCHAR2(2 CHAR) := '';
  l_tablen           INTEGER;
  l_msg              VARCHAR2(200 CHAR);

  l_gather_stats     ps_gfc_stats_ovrd.gather_stats%TYPE;
  l_estimate_percent ps_gfc_stats_ovrd.estimate_percent%TYPE := p_estpct;
  l_method_opt       ps_gfc_stats_ovrd.method_opt%TYPE;
  l_block_sample     BOOLEAN := FALSE;
  l_block_samplec    VARCHAR2(1 CHAR);
  l_force            BOOLEAN := FALSE;
 BEGIN
  l_tablen := LENGTH(p_tabname);
  l_msg := p_ownname||'.'||p_tabname||': ';

  BEGIN --is this a GTT or a partitioned table? y/n
   SELECT temporary, SUBSTR(partitioned,1,1)
   INTO   l_temporary, l_partitioned
   FROM   all_tables
   WHERE  owner = p_ownname
   AND    table_name = p_tabname;

   IF l_temporary = 'Y' THEN
    l_msg := l_msg||'GTT. ';
   END IF;

   IF l_partitioned = 'Y' THEN
    l_msg := l_msg||'Partitioned Table. ';
   END IF;

  EXCEPTION WHEN no_data_found THEN
   RAISE_APPLICATION_ERROR(-20001,'Table '||p_ownname||'.'||p_tabname||' does not exist');
  END;

  BEGIN --what is the PeopleSoft record name and type
   SELECT r.rectype, r.recname
   INTO   l_rectype, l_recname
   FROM   psrecdefn r
   WHERE  DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename) = p_tabname
   AND    r.rectype IN(0,7);
   EXCEPTION 
   WHEN no_data_found THEN NULL;
  END;

  IF l_recname IS NULL THEN
   BEGIN --what is the PeopleSoft record name and type
    SELECT r.rectype, r.recname, SUBSTR(p_tabname,-1)
    INTO   l_rectype, l_recname, l_temptblinstance
    FROM   psrecdefn r
    WHERE  DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename) = SUBSTR(p_tabname,1,l_tablen-1)
    AND    r.rectype = 7;

    l_msg := l_msg||'Instance '||l_temptblinstance||'. ';
   EXCEPTION 
    WHEN no_data_found THEN NULL;
   END;
  END IF;

  IF l_recname IS NULL THEN
   BEGIN --what is the PeopleSoft record name and type
    SELECT r.rectype, r.recname, SUBSTR(p_tabname,-2)
    INTO   l_rectype, l_recname, l_temptblinstance
    FROM   psrecdefn r
    WHERE  DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename) = SUBSTR(p_tabname,1,l_tablen-2)
    AND    r.rectype = 7;

    l_msg := l_msg||'Instance '||l_temptblinstance||'. ';
   EXCEPTION 
    WHEN no_data_found THEN NULL;
   END;
  END IF;

  --to introduce new 'per record' behaviour per program use list of programs here
  IF 1=1 /*psftapi.get_prcsname() IN(<program name list>)*/ THEN
   BEGIN --get override meta data
    SELECT o.gather_stats, RTRIM(o.estimate_percent), RTRIM(o.method_opt), RTRIM(o.block_sample)
    INTO   l_gather_stats,       l_estimate_percent ,       l_method_opt ,       l_block_samplec
    FROM   ps_gfc_stats_ovrd o
    WHERE  recname = l_recname;

    l_msg := l_msg||'Meta Data: '||l_gather_stats;
    IF l_estimate_percent IS NOT NULL THEN
     l_msg := l_msg||','||l_estimate_percent;
    END IF;
    IF l_method_opt IS NOT NULL THEN
     l_msg := l_msg||','||l_method_opt;
    END IF;
    l_msg := l_msg||'. ';
    IF l_block_samplec = 'Y' THEN
     l_block_sample := TRUE;
    ELSE
     l_block_sample := FALSE;
    END IF;
    l_force := TRUE;

   EXCEPTION 
    WHEN no_data_found THEN 
     l_estimate_percent := p_estpct;
     l_block_sample := FALSE;
     l_method_opt := sys.dbms_stats.get_param('METHOD_OPT');  
     l_force := TRUE; --17.11.2011 Default is to collect stats if no meta data even if table locked
     l_msg := l_msg||'No Meta Data Found. ';
  
     IF l_rectype = 0 THEN 
      l_msg := l_msg||'SQL Table. ';
      l_gather_stats := 'R'; --default refresh stale on normal tables
     ELSIF l_rectype = 7 THEN
--1.10.2009 changed default from N (No Stats) to G (Gather Stats) on temp records
      l_msg := l_msg||'Temporary Table. ';
      l_gather_stats := 'G'; --default gather stats on temp records
     END IF;
   END;
  ELSE
   l_msg := l_msg||'Default ';
   l_gather_stats := 'G';
  END IF;

  IF l_estimate_percent IS NULL THEN
   l_estimate_percent := p_estpct;
  END IF;

--sys.dbms_output.put_line('Gather Stats='''||l_gather_stats||'''');
--sys.dbms_output.put_line('Temporary   ='''||l_temporary||'''');
--sys.dbms_output.put_line('Temp Inst   ='''||l_temptblinstance||'''');

  IF l_gather_stats = 'N' THEN -- don't collect stats if meta data says N

   l_msg := l_msg||'Statistics Not Collected. ';
   IF p_verbose THEN
    dbms_output.put_line(l_msg);
   END IF;

  ELSIF l_gather_stats != 'N' AND l_temporary = 'Y' AND l_temptblinstance IS NULL THEN -- don't collect stats on shared GTTs

   l_msg := l_msg||'Statistics not collected on shared GTT. ';
   IF p_verbose THEN
    dbms_output.put_line(l_msg);
   END IF;
   l_gather_stats := 'N';

  ELSIF l_partitioned = 'Y' OR l_gather_stats = 'R' THEN --refresh stale if partitioned 

   l_msg := l_msg||'Refresh Stale Statistics. ';
   IF p_verbose THEN
    dbms_output.put_line(l_msg);
   END IF;

   refresh_stats
   (p_ownname      => p_ownname
   ,p_tabname      => p_tabname
   ,p_estpct       => l_estimate_percent
   ,p_method_opt   => l_method_opt
   ,p_block_sample => l_block_sample
   ,p_force        => l_force
   ,p_verbose      => p_verbose
   ); --refresh stale stats only
   
  ELSE

   l_msg := l_msg||'Gather Statistics. ';
   IF p_verbose THEN
    dbms_output.put_line(l_msg);
   END IF;

   wrapper.gather_table_stats
   (p_ownname      => p_ownname
   ,p_tabname      => p_tabname
   ,p_estpct       => l_estimate_percent
   ,p_cascade      => TRUE
   ,p_method_opt   => l_method_opt
   ,p_block_sample => l_block_sample
   ,p_force        => l_force
   ,p_verbose      => p_verbose
   ); 

   IF p_verbose THEN
    dbms_output.put_line('Table:'||p_ownname||'.'||p_tabname||' finished @ '||TO_CHAR(SYSDATE,'hh24:mi:ss dd.mm.yyyy')); 
   END IF;
  END IF;
 EXCEPTION
  WHEN table_stats_locked THEN NULL;
 END ps_stats;

END wrapper;
/
show errors
pause

/*------------------------------------------------------------------------------------------
/* the following commands are to test the stats wrapper
/*------------------------------------------------------------------------------------------

clear screen
set serveroutput on
ALTER SESSION SET NLS_DATE_FORMAT='hh24:mi:ss dd.mm.yyyy';
DELETE FROM ps_gfc_stats_ovrd WHERE recname IN('TL_WRK01_RCD','TL_PROF_LIST','TL_TA_BATCHA');
INSERT INTO ps_gfc_stats_ovrd VALUES('TL_WRK01_RCD','N',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd VALUES('TL_PROF_LIST','G','42','FOR ALL COLUMNS SIZE 1');

--these collect stats iff stale
begin wrapper.ps_stats('SYSADM','PSLOCK',0, TRUE); end;
/
begin wrapper.ps_stats('SYSADM','PSLOCK',.5, TRUE); end;
/
begin wrapper.ps_stats('SYSADM','PSLOCK',1, TRUE); end;
/

--expect collect stats at 42%
begin wrapper.ps_stats('SYSADM','PS_TL_PROF_LIST12',1, TRUE); end;
/
begin wrapper.ps_stats('SYSADM','PS_TL_PROF_LIST6',1, TRUE); end;
/
begin wrapper.ps_stats('SYSADM','PS_TL_PROF_LIST',1, TRUE); end;
/

--if partition will freshed stale partitions
--begin wrapper.ps_stats('SYSADM','PS_TL_RPTD_TIME',0, TRUE); end;
--/

--will not collect stats
begin wrapper.ps_stats('SYSADM','PS_TL_WRK01_RCD',0, TRUE); end;
/

select num_rows, last_analyzed from user_tables
where table_name = 'PS_TL_ST_PCHTIME'
or table_name = 'PS_TL_PROF_LIST12'
/
--no message but it does collect
begin wrapper.ps_stats('SYSADM','PS_TL_PROF_LIST12',1); end;
/
--no message but it does collect iff stale
begin wrapper.ps_stats('SYSADM','PS_TL_ST_PCHTIME',1); end;
/
select num_rows, last_analyzed from user_tables
where table_name = 'PS_TL_ST_PCHTIME'
or table_name = 'PS_TL_PROF_LIST12'
/


--now lets set up for a n --added 6.6.2009
INSERT INTO ps_gfc_stats_ovrd VALUES('TL_TA_BATCHA'  ,'G',' ','FOR ALL COLUMNS SIZE 1'); 
execute psftapi.set_prcsinstance(4,'GFCTEST');

DELETE FROM ps_aetemptblmgr
WHERE process_instance = 0
/
INSERT INTO ps_aetemptblmgr 
(process_instance, recname, curtempinstance, oprid, run_cntl_id, ae_applid, run_dttm, ae_disable_restart, ae_dedicated, ae_truncated)
VALUES (0,'TL_TA_BATCHA',4,'PS','Wibble','GFCTEST',SYSDATE,'N' ,1,1) --restart enabled
/
--this will collect because it is permanent
begin wrapper.ps_stats('SYSADM','PS_TL_TA_BATCHA4',0,TRUE); end;
/
DELETE FROM ps_gfc_stats_ovrd WHERE recname = 'TL_TA_BATCHA';
begin wrapper.ps_stats('SYSADM','PS_TL_TA_BATCHA',0,TRUE); end;
/


DELETE FROM ps_aetemptblmgr
WHERE process_instance = 0
/
INSERT INTO ps_aetemptblmgr
(process_instance, recname, curtempinstance, oprid, run_cntl_id, ae_applid, run_dttm, ae_disable_restart, ae_dedicated, ae_truncated)
VALUES (0,'TL_TA_BATCHA',4,'PS','Wibble','GFCTEST',SYSDATE,'Y'  ,1,1) --restart disabled
/

--and this will collect stats on non-shared instance of GTT.
INSERT INTO ps_gfc_stats_ovrd VALUES('TL_TA_BATCHA'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1'); 
begin wrapper.ps_stats('SYSADM','PS_TL_TA_BATCHA4',0,TRUE); end;
/
DELETE FROM ps_gfc_stats_ovrd WHERE recname = 'TL_TA_BATCHA';
begin wrapper.ps_stats('SYSADM','PS_TL_TA_BATCHA4',0,TRUE); end;
/

INSERT INTO ps_gfc_stats_ovrd VALUES('TL_TA_BATCHA'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1'); 
begin wrapper.ps_stats('SYSADM','PS_TL_TA_BATCHA',0,TRUE); end;
/
DELETE FROM ps_gfc_stats_ovrd WHERE recname = 'TL_TA_BATCHA';
begin wrapper.ps_stats('SYSADM','PS_TL_TA_BATCHA',0,TRUE); end;
/

DELETE FROM ps_gfc_stats_ovrd WHERE recname IN('TL_WRK01_RCD','TL_PROF_LIST','TL_TA_BATCHA')
/


--now lets try GTTs
begin wrapper.ps_stats('SYSADM','PS_GP_PYE_STAT_WRK',1,TRUE); end;
/
begin wrapper.ps_stats('SYSADM','PS_GP_GL_DATATMP',1,TRUE); end;
/
begin wrapper.ps_stats('SYSADM','PS_GP_GL_DATATMP12',1,TRUE); end;
/

pause


--demo partition refresh
set serveroutput on 
update ps_gp_rslt_acum subpartition(GP_RSLT_ACUM_018_Z_OTHERS) set user_key6 = user_key6 where rownum <= 100000;
commit;
begin wrapper.ps_stats(p_ownname=>'SYSADM', p_tabname=>'PS_GP_RSLT_ACUM', p_verbose=>TRUE); end;
/
begin wrapper.ps_stats(p_ownname=>'SYSADM', p_tabname=>'PS_GP_RSLT_ACUM', p_verbose=>TRUE); end;
/





pause
------------------------------------------------------------------------------------------*/
--the following commands populate the meta data table
--For example, These tables in T&L need statistics, but not histograms
--this list is just a suggestion - YOUR MILEAGE MAY VARY
------------------------------------------------------------------------------------------

DELETE FROM ps_gfc_stats_ovrd;
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_FRCS_PYBL_TM','R',' ',' ','');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_IPT1'        ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_MTCHD'       ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_PMTCH1_TMP'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_PMTCH2_TMP'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_PMTCH_TMP1'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_PMTCH_TMP2'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_PROF_LIST'   ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_PROF_WRK'    ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_RESEQ2_WRK'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_RESEQ5_WRK'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_WRK01_RCD'   ,'G',' ',' ','FOR ALL COLUMNS SIZE 1');
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('WRK_SCHRS_TAO'  ,'G',' ',' ','FOR ALL COLUMNS SIZE 1') /*added  6.6.2009*/;
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_ST_PCHTIME'  ,'R',' ',' ','') /*added 11.2.2011 for WMS_ST_LOAD.MAIN.Stats.S*/;
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('TL_VALID_TR'    ,'R',' ',' ','') /*added 11.2.2011 for TL_VALD_MAIN.VALDDEFN.stats1.S*/;

INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('GP_RSLT_ACUM'   ,'R',' ','Y','FOR COLUMNS cal_run_id SIZE AUTO, FOR ALL COLUMNS SIZE 1') /*added 5.5.2011*/;
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt) VALUES('GP_RSLT_PIN'    ,'R',' ','Y','FOR COLUMNS cal_run_id SIZE AUTO, FOR ALL COLUMNS SIZE 1') /*added 5.5.2011*/;

INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt)
SELECT 	DISTINCT recname, 'N', ' ', ' ', ''
FROM	PSAEAPPLTEMPTBL a
WHERE 	a.ae_applid = 'TL_TIMEADMIN'
AND NOT EXISTS(
	SELECT 'x'
	FROM	ps_gfc_stats_ovrd b
 	WHERE 	b.recname = a.recname)
;

commit;


/*------------------------------------------------------------------------------------------
--To set same behaviour for all records then build meta data for all records with following
------------------------------------------------------------------------------------------
DELETE FROM ps_gfc_stats_ovrd
/
INSERT INTO ps_gfc_stats_ovrd (recname, gather_stats, estimate_percent, block_sample, method_opt)
SELECT recname,'G',' ',' ','FOR ALL COLUMNS SIZE AUTO'
FROM psrecdefn WHERE rectype = 7
/
------------------------------------------------------------------------------------------*/

set serveroutput on pages 40
clear screen
column recname          format a15 heading 'PS Record Name'
column method_opt       format a60
column gather_stats     format a6  heading 'Gather|Stats'
column estimate_percent format a8  heading 'Estimate|Percent'
column block_sample     format a6  heading 'Block|Sample'
SELECT recname, gather_stats, estimate_percent, block_sample, method_opt
FROM   ps_gfc_stats_ovrd 
ORDER BY 1
/

------------------------------------------------------------------------------------------



spool off

