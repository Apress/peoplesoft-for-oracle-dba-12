REM wrapper848.sql
REM dbms_stats wrapper script for Oracle 10gR2 PT>=8.48
REM 12.2.2009 force stats collection on regular tables, skip GTTs
REM 24.3.2009 added refresh procedure for partitioned objects, gather_table_stats proc for wrapping
spool wrapper

CREATE OR REPLACE PACKAGE wrapper AS
------------------------------------------------------------------------------------------------
--Procedure to refresh stale stats on table, partition AND subpartition
--24.3.2009 added refresh procedure for partitioned objects, gather_table_stats proc for wrapping
-- 2.4.2009 added flush table monitoring stats to refresh stats pacakge
------------------------------------------------------------------------------------------------
PROCEDURE refresh_stats
(p_ownname IN VARCHAR2 /*owner of table*/
,p_tabname IN VARCHAR2 /*table name*/
,p_estpct  IN NUMBER DEFAULT NULL /*size of sample - 0 or NULL means dbms_stats default*/
,p_stale_threshold_pct IN INTEGER DEFAULT 10
,p_verbose IN BOOLEAN DEFAULT FALSE /*if true print SQL*/
);
------------------------------------------------------------------------------------------------
--procedure called from DDL model for %UpdateStats
--24.3.2009 adjusted to call local dbms_stats AND refresh stats
------------------------------------------------------------------------------------------------
PROCEDURE ps_stats 
(p_ownname IN VARCHAR2 /*owner of table*/
,p_tabname IN VARCHAR2 /*table name*/
,p_estpct  IN NUMBER DEFAULT NULL /*size of sample - 0 or NULL means dbms_stats default*/
);
END wrapper;
/

CREATE OR REPLACE PACKAGE BODY wrapper AS

 g_lf VARCHAR2(1) := CHR(10); --line feed character
 table_stats_locked EXCEPTION;
 PRAGMA EXCEPTION_INIT(table_stats_locked,-20005);

------------------------------------------------------------------------------------------------
--procedure to dynamically execute SQL
------------------------------------------------------------------------------------------------
 PROCEDURE exec_sql
 (p_sql     IN OUT VARCHAR2
 ,p_verbose IN     BOOLEAN DEFAULT FALSE) IS
 BEGIN
  IF p_verbose THEN
   dbms_output.put_line(p_sql); 
  END IF;
  EXECUTE IMMEDIATE p_sql;
 END;
 
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

  IF p_block_sample THEN
   l_sql := l_sql||g_lf||',block_sample => TRUE';
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
  exec_sql(p_sql=>l_sql,p_verbose=>p_verbose);

 END gather_table_stats;

------------------------------------------------------------------------------------------------
--check for stale/missing states in named table AND gather if stale
------------------------------------------------------------------------------------------------
 PROCEDURE refresh_stats
 (p_ownname             IN VARCHAR2
 ,p_tabname             IN VARCHAR2
 ,p_estpct              IN NUMBER  DEFAULT NULL
 ,p_stale_threshold_pct IN INTEGER DEFAULT 10
 ,p_verbose             IN BOOLEAN DEFAULT FALSE /*if true print SQL*/
 ) IS
 BEGIN
  dbms_stats.flush_database_monitoring_info;

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
   AND    s.stattype_locked IS NULL
   AND    (  p.num_rows IS NULL
          OR p.num_rows*p_stale_threshold_pct/100 <= (m.inserts+m.updates+m.deletes)
          OR m.truncated = 'YES'
 	 )
  ) LOOP 
   wrapper.gather_table_stats
   (p_ownname => i.table_owner
   ,p_tabname => i.table_name
   ,p_partname => i.subpartition_name
   ,p_estpct => p_estpct
   ,p_cascade => TRUE
   ,p_granularity => 'SUBPARTITION'
   ,p_verbose => p_verbose
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
   AND    s.stattype_locked IS NULL
   AND    (  p.num_rows IS NULL
          OR p.num_rows*p_stale_threshold_pct/100 <= (m.inserts+m.updates+m.deletes) 
          OR m.truncated = 'YES'
	  )
  ) LOOP
   wrapper.gather_table_stats
   (p_ownname => i.table_owner
   ,p_tabname => i.table_name
   ,p_partname => i.partition_name
   ,p_estpct => p_estpct
   ,p_cascade => TRUE
   ,p_granularity => 'PARTITION'
   ,p_verbose => p_verbose
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
   AND    s.stattype_locked IS NULL
   AND    (  p.num_rows IS NULL
          OR p.num_rows*p_stale_threshold_pct/100 <= (m.inserts+m.updates+m.deletes)
          OR m.truncated = 'YES'
          )
  ) LOOP
   wrapper.gather_table_stats
   (p_ownname => i.owner
   ,p_tabname => i.table_name
   ,p_estpct => p_estpct
   ,p_cascade => TRUE
   ,p_granularity => 'GLOBAL'
   ,p_verbose => p_verbose
   );
  END LOOP;

 END refresh_stats; 

------------------------------------------------------------------------------------------------
--public procedure called from DDL model for %UpdateStats
--12.2.2009 force stats collection on regular tables, skip GTTs
------------------------------------------------------------------------------------------------
 PROCEDURE ps_stats
 (p_ownname IN VARCHAR2
 ,p_tabname IN VARCHAR2
 ,p_estpct  IN NUMBER DEFAULT NULL
 ) IS
  l_temporary VARCHAR2(1 CHAR);
  l_partitioned VARCHAR2(1 CHAR);
  l_force BOOLEAN := TRUE;
 BEGIN
  BEGIN
   SELECT temporary, SUBSTR(partitioned,1,1)
   INTO   l_temporary, l_partitioned
   FROM   all_tables
   WHERE  owner = p_ownname
   AND    table_name = p_tabname
   ;
  EXCEPTION WHEN no_data_found THEN
   RAISE_APPLICATION_ERROR(-20001,'Table '||p_ownname||'.'||p_tabname||' does not exist');
  END;

  IF l_temporary = 'Y' THEN 
   l_force := FALSE; --don't force stats collect on GTTs
  ELSE
   l_force := TRUE; --don't force stats collect on GTTs
  END IF;

  IF l_partitioned = 'N' THEN
   wrapper.gather_table_stats
   (p_ownname=>p_ownname
   ,p_tabname=>p_tabname
   ,p_estpct=>p_estpct
   ,p_cascade=>TRUE
   ,p_force=>l_force
-- ,p_method_opt=>'FOR ALL COLUMNS SIZE 1' --uncomment this to supress collection of histograms
   ); 
  ELSE --if it is partitioned
   
   refresh_stats
   (p_ownname=>p_ownname
   ,p_tabname=>p_tabname
   ,p_estpct=>p_estpct
   );
   
  END IF;
 EXCEPTION
  WHEN table_stats_locked THEN NULL;
 END ps_stats;

END wrapper;
/


show errors

begin wrapper.ps_stats('SYSADM','PSLOCK',0); end;
/
begin wrapper.ps_stats('SYSADM','PSLOCK',.5); end;
/
begin wrapper.ps_stats('SYSADM','PSLOCK',1); end;
/
begin wrapper.ps_stats('SYSADM','PS_TL_RPTD_TIME',0); end;
/

spool off
