rem colaudit.sql
rem (c) Go-Faster Consultancy Ltd. 2004
rem 17.2.2003 - base version
rem 28.3.2004 - additional columns added for PeopleTools 8.44
rem 28.6.2004 - populate gfc_ps_tab_columns with psrecfielddb
rem NB set compatible to at least 8.1.0.0.0 or do not compress indexes

rem ALTER SESSION SET tracefile_identifier = 'colaudit';
rem ALTER SESSION SET sql_trace = true;
spool off
spool colaudit_prepare
WHENEVER SQLERROR CONTINUE;
ROLLBACK;

set serveroutput ON buffer 1000000000
set echo ON verify ON feedback ON message on

ANALYZE TABLE psrecdefn ESTIMATE statistics;
ANALYZE TABLE psrecfield ESTIMATE statistics;
ANALYZE TABLE psrecfielddb ESTIMATE statistics;
ANALYZE TABLE psdbfield ESTIMATE statistics;

DROP TABLE gfc_objects;
DROP TABLE gfc_ps_tab_columns;
--DROP TABLE gfc_ps_ind_columns;
DROP TABLE gfc_ps_indexdefn;
DROP TABLE gfc_ps_keydefn;
DROP TABLE gfc_ora_tab_columns;
DROP TABLE gfc_ora_ind_columns;
DROP TABLE gfc_rebuild;

CREATE TABLE gfc_rebuild
(recname	varchar2(15) NOT NULL
,indexid	varchar2(1)
) NOLOGGING
;

CREATE TABLE gfc_objects NOLOGGING
AS 
SELECT 	object_type, object_name
FROM	user_objects o
WHERE	o.object_type IN('TABLE','VIEW')
;

CREATE UNIQUE INDEX gfc_objects
ON gfc_objects (object_type, object_name) 
compress 1 TABLESPACE psINDEX NOLOGGING;

CREATE UNIQUE INDEX gfcaobjects 
ON gfc_objects (object_name) 
TABLESPACE psindex NOLOGGING;

ANALYZE TABLE gfc_objects ESTIMATE statistics;

CREATE TABLE gfc_ora_tab_columns NOLOGGING AS 
SELECT	table_name, column_name
,	data_type
,	data_length    
,	data_precision 
,	data_scale     
,	nullable       
,	column_id      
FROM 	user_tab_columns
;

CREATE UNIQUE INDEX gfc_ora_tab_columns 
ON gfc_ora_tab_columns (table_name, column_name) 
TABLESPACE psINDEX COMPRESS 1 NOLOGGING;

DELETE FROM gfc_objects WHERE object_name like 'GFC%';
DELETE FROM gfc_ora_tab_columns WHERE table_name like 'GFC%';
ANALYZE TABLE gfc_ora_tab_columns ESTIMATE statistics;

--user_ind_columns replaced with pregenerated table for performance
CREATE TABLE gfc_ora_ind_columns NOLOGGING AS
SELECT	table_name
, 	index_name
, 	column_position
, 	column_name
FROM	user_ind_columns
;

CREATE UNIQUE INDEX gfc_ora_ind_columns 
ON gfc_ora_ind_columns (table_name, index_name, column_name, column_position) 
TABLESPACE psINDEX COMPRESS 2;

ANALYZE TABLE gfc_ora_ind_columns ESTIMATE STATISTICS;

CREATE TABLE gfc_ps_tab_columns
(recname	varchar2(15) 	NOT NULL
,fieldname	varchar2(18)	NOT NULL
,useedit	number(38)	NOT NULL
,fieldnum	number(38)	NOT NULL
,subrecname 	varchar2(15)	NOT NULL
) 
;

TRUNCATE TABLE gfc_ps_tab_columns;

INSERT /*+APPEND*/ INTO gfc_ps_tab_columns
(	recname, fieldname, useedit, fieldnum, subrecname)
SELECT	r.recname, f.fieldname, f.useedit, f.fieldnum, r.recname
FROM	psrecdefn r
,	psrecfield f
WHERE	r.recname = f.recname
and 	r.rectype IN(
	0, /*TABLES*/
	1, /*views*/
	6, /*QUERY VIEWS*/
	7) /*TEMPORARY TABLE*/
;

COMMIT
;

CREATE UNIQUE INDEX gfc_ps_tab_columns 
ON gfc_ps_tab_columns (recname, fieldname) 
TABLESPACE psINDEX COMPRESS 1  NOLOGGING;

--gfc_ps_indexdefn - expaned version of psindexdefn
CREATE /*GLOBAL TEMPORARY*/ table gfc_ps_indexdefn
(recname	VARCHAR2(15) 	NOT NULL
,indexid	VARCHAR2(1) 	NOT NULL
,subrecname	VARCHAR2(15) 	NOT NULL
,subindexid	VARCHAR2(1) 	NOT NULL
);

CREATE UNIQUE INDEX gfc_ps_indexdefn 
ON gfc_ps_indexdefn(recname, indexid)
TABLESPACE psindex COMPRESS 1
;

CREATE INDEX gfc_ps_indexdefn2 
ON gfc_ps_indexdefn(subrecname, subindexid)
TABLESPACE psindex
;

--gfc_ps_keydefn - expaned version of pskeydefn

CREATE /*GLOBAL TEMPORARY*/ table gfc_ps_keydefn
(recname	VARCHAR2(15) 	NOT NULL
,indexid	VARCHAR2(1) 	NOT NULL
,keyposn	number		NOT NULL
,fieldname	VARCHAR2(18)	NOT NULL
,fieldnum 	NUMBER		NOT NULL
);

CREATE UNIQUE INDEX gfc_ps_keydefn 
ON gfc_ps_keydefn(recname,indexid,keyposn)
TABLESPACE psindex COMPRESS 2
;

CREATE UNIQUE INDEX gfc_ps_keydefn2 
ON gfc_ps_keydefn(recname,indexid,fieldname)
TABLESPACE psindex COMPRESS 2
;

--CREATE TABLE gfc_ps_ind_columns
--(recname 	VARCHAR2(15) 	NOT NULL
--,indexid 	VARCHAR2(1) 	NOT NULL
--,keyposn 	NUMBER 		NOT NULL
--,fieldname 	VARCHAR2(18) 	NOT NULL
--,fieldnum 	NUMBER		NOT NULL
--,ascdesc 	NUMBER 		NOT NULL
--);

--TRUNCATE TABLE gfc_ps_ind_columns;

--INSERT /*+APPEND*/ INTO gfc_ps_ind_columns
--(recname, indexid, keyposn, fieldname, fieldnum, ascdesc)
--SELECT 	k.recname, k.indexid, k.keyposn, k.fieldname, f.fieldnum, k.ascdesc
--FROM 	pskeydefn k
--,	psrecfield f
--WHERE 	f.recname = k.recname
--AND	f.fieldname = k.fieldname;

--CREATE UNIQUE INDEX gfc_ps_ind_columns 
--ON gfc_ps_ind_columns 
--(RECNAME,indexid,KEYPOSN) 
--TABLESPACE PSINDEX;

CREATE OR REPLACE VIEW gfc_ps_alt_ind_cols AS
SELECT	c.recname
,	LTRIM(TO_CHAR(RANK() over (PARTITION BY c.recname 
					ORDER BY c.fieldnum)-1,'9')) indexid
, 	c.subrecname
,	LTRIM(TO_CHAR(RANK() over (PARTITION BY c.recname, c.subrecname 
					ORDER BY c.fieldnum)-1,'9')) subindexid
,	c.fieldname
,	c.fieldnum
FROM	gfc_ps_tab_columns c
WHERE	MOD(useedit/16,2) = 1
;

rem 11.2.2003 - view corrected to handled user indexes
CREATE OR REPLACE VIEW gfc_ps_keydefn_vw AS
SELECT	j.recname, j.indexid
,	RANK() OVER (PARTITION BY j.recname, j.indexid 
			ORDER BY DECODE(i.custkeyorder,1,k.keyposn,c.fieldnum)) as keyposn
,	k.fieldname
,	RANK() OVER (PARTITION BY j.recname, j.indexid ORDER BY c.fieldnum) as fieldposn
FROM	gfc_ps_indexdefn j
,	psindexdefn i
,	gfc_ps_tab_columns c
,	pskeydefn k
WHERE	i.recname = j.subrecname
AND	i.indexid = j.subindexid
AND	j.indexid = '_'
AND	c.recname = j.recname
AND	k.recname = c.subrecname
AND	k.indexid = j.subindexid
AND	k.fieldname = c.fieldname
UNION ALL
SELECT	j.recname, j.indexid
,	RANK() OVER (PARTITION BY j.recname, j.indexid ORDER BY k.keyposn) as keyposn
,	k.fieldname
,	RANK() OVER (PARTITION BY j.recname, j.indexid ORDER BY c.fieldnum) as fieldposn
FROM	gfc_ps_indexdefn j
,	psindexdefn i
,	gfc_ps_tab_columns c
,	pskeydefn k
WHERE	i.recname = j.subrecname
AND	i.indexid = j.subindexid
AND	j.indexid BETWEEN 'A' AND 'Z'
AND	c.recname = j.recname
AND	k.recname = c.subrecname
AND	k.indexid = j.subindexid
AND	k.fieldname = c.fieldname
;

commit;

--rollback;

DECLARE
--populate table of INDEXes - dmk
	PROCEDURE gfc_ps_indexdefn IS
	BEGIN
		INSERT INTO gfc_ps_indexdefn
		(	recname, indexid, subrecname, subindexid)
		SELECT	DISTINCT c.recname, i.indexid, c.recname, i.indexid
		FROM	gfc_ps_tab_columns c
		,	psindexdefn i
		WHERE	i.recname = c.subrecname
		AND	i.platform_ora = 1
		AND	NOT i.indexid BETWEEN '0' AND '9'
		;

		INSERT INTO gfc_ps_indexdefn
		(	recname, indexid, subrecname, subindexid)
		SELECT	DISTINCT x.recname, x.indexid, x.subrecname, x.subindexid
		FROM	gfc_ps_alt_ind_cols x
		,	psindexdefn i
		WHERE	x.indexid BETWEEN '0' AND '9'
		AND	x.subindexid = i.indexid
		AND	x.subrecname = i.recname
		AND	i.platform_ora = 1
		;
	END;

--populate table of INDEXes - dmk
	PROCEDURE gfc_ps_keydefn IS
	BEGIN
		INSERT INTO gfc_ps_keydefn
		(	recname, indexid, keyposn, fieldname, fieldnum)
		SELECT 	recname, indexid, keyposn, fieldname, fieldposn
		FROM 	gfc_ps_keydefn_vw
		;

		INSERT INTO gfc_ps_keydefn
		(	recname, indexid, keyposn, fieldname, fieldnum)
		SELECT	c.recname, c.indexid, 1, c.fieldname, fieldnum
		FROM	gfc_ps_alt_ind_cols c
		;

		INSERT INTO gfc_ps_keydefn
		(	recname, indexid, keyposn, fieldname, fieldnum)
		SELECT	c.recname, c.indexid, k.fieldposn+1, k.fieldname, k.fieldposn 
		FROM	gfc_ps_alt_ind_cols c
		,	gfc_ps_keydefn_vw k
		WHERE	k.recname = c.recname
		AND	k.indexid = '_'
		;

		UPDATE	gfc_ps_keydefn k
		SET	k.keyposn = 
			(SELECT	k1.keyposn
			FROM	pskeydefn k1
			WHERE	k1.recname = k.recname
			AND	k1.indexid = k.indexid
			AND	k1.fieldname = k.fieldname)
		WHERE	(k.recname,k.indexid) IN (
			SELECT	i.recname, i.indexid
			FROM	gfc_ps_indexdefn i
			,	psindexdefn j
			WHERE	j.recname = i.recname
			AND	j.indexid = i.indexid
			AND	j.custkeyorder = 1)
		;

	END;

	PROCEDURE expand_sbr IS	
		CURSOR cols_cursor IS
		SELECT * 
		FROM   gfc_ps_tab_columns
		WHERE  fieldname IN
			(SELECT recname 
			FROM 	psrecdefn 
			WHERE 	rectype = 3)
		ORDER BY recname, fieldnum
		;

		p_cols_cursor cols_cursor%ROWTYPE;
	
		l_found_sbr INTEGER :=0; /*number of subrecords found in loop*/
		l_sbr_cols  INTEGER;     /*number of columns in the subrecord*/
		l_last_recname VARCHAR2(18) := ''; /*name oflast record processed*/
		l_fieldnum_adj INTEGER := 0; /*field number offset when expanding subrecords*/
	BEGIN
		LOOP
			l_found_sbr := 0;
			OPEN cols_cursor;
			LOOP
				FETCH cols_cursor INTO p_cols_cursor;
				EXIT WHEN cols_cursor%NOTFOUND;
	
--				sys.dbms_output.put_line(l_last_recname||'.'||p_cols_cursor.recname||'.'||l_fieldnum_adj);
				IF (l_last_recname != p_cols_cursor.recname OR l_last_recname IS NULL) THEN
					l_fieldnum_adj := 0;
					l_last_recname := p_cols_cursor.recname;
				END IF;

--				sys.dbms_output.put_line(p_cols_cursor.recname||' '||p_cols_cursor.fieldnum||' '||p_cols_cursor.fieldname||' '||l_fieldnum_adj);

				l_found_sbr := l_found_sbr +1;

				SELECT COUNT(*)
				INTO   l_sbr_cols
				FROM   psrecfield f
				WHERE  f.recname = p_cols_cursor.fieldname;

				DELETE FROM gfc_ps_tab_columns
				WHERE  recname = p_cols_cursor.recname
				AND    fieldname = p_cols_cursor.fieldname;

				UPDATE gfc_ps_tab_columns
				SET    fieldnum = fieldnum + l_sbr_cols - 1
				WHERE  recname = p_cols_cursor.recname
				AND    fieldnum > p_cols_cursor.fieldnum + l_fieldnum_adj;

				INSERT INTO gfc_ps_tab_columns
				(	recname, fieldname, useedit
				,	fieldnum, subrecname)
				SELECT  p_cols_cursor.recname, f.fieldname, f.useedit
				,	f.fieldnum + p_cols_cursor.fieldnum + l_fieldnum_adj - 1, f.recname
				FROM    psrecfield f
				WHERE	f.recname = p_cols_cursor.fieldname;
	
				l_fieldnum_adj := l_fieldnum_adj + l_sbr_cols -1;

			END LOOP;
			CLOSE cols_cursor;
			sys.dbms_output.put_line('Found: '||l_found_sbr||' sub-records');
		EXIT WHEN l_found_sbr = 0;
		END LOOP;
	END;

	PROCEDURE shuffle_long IS
		CURSOR cols_cursor IS
		SELECT	c.recname, c.fieldname, c.fieldnum
		FROM	gfc_ps_tab_columns c
		,	psdbfield d
		,	psrecdefn r
		WHERE 	c.fieldname = d.fieldname
		AND	(	(	d.fieldtype = 1
				AND	NOT d.length BETWEEN 1 AND 2000)
			OR	d.fieldtype = 8)
		AND	r.recname = c.recname
		AND	r.rectype IN(0,7)
		AND EXISTS(
			SELECT 'x'
			FROM	gfc_ps_tab_columns c1
			,	psdbfield d1
			WHERE	c1.recname = c.recname
			AND	c1.fieldname = d1.fieldname
			AND	c1.fieldnum > c.fieldnum
			AND NOT (	(	d1.fieldtype = 1
					AND	NOT d1.length BETWEEN 1 AND 2000)
				OR	d1.fieldtype = 8)
			)
		;
		p_cols_cursor cols_cursor%ROWTYPE;
		l_fieldcount INTEGER;
	BEGIN
		OPEN cols_cursor;
		LOOP
			FETCH cols_cursor INTO p_cols_cursor;
			EXIT WHEN cols_cursor%NOTFOUND;

			SELECT 	MAX(fieldnum)
			INTO	l_fieldcount
			FROM	gfc_ps_tab_columns
			WHERE	recname = p_cols_cursor.recname;

			UPDATE	gfc_ps_tab_columns
			SET	fieldnum = DECODE(fieldnum,p_cols_cursor.fieldnum,l_fieldcount,fieldnum-1)
			WHERE	recname = p_cols_cursor.recname
			AND	fieldnum >= p_cols_cursor.fieldnum
			;

		END LOOP;
		CLOSE cols_cursor;
	END;

--	PROCEDURE expand_isbr IS
--		CURSOR cols_cursor IS
--		SELECT 	c.recname, i.indexid, c.fieldname
--		,	c.fieldnum, c.subrecname, c.useedit
--		FROM 	gfc_ps_tab_columns c
--		,	psrecdefn r
--		,	psindexdefn i
--		WHERE 	(	MOD(useedit,2) = 1 /*key*/
--			OR	MOD(FLOOR(useedit/2),2) = 1) /*duplicate order*/
--		AND 	c.subrecname != c.recname
--		AND	r.recname = c.recname
--		AND	r.rectype IN(0,7)
--		AND	i.recname = c.recname
--		AND	i.custkeyorder = 0
--		AND	i.platform_ora = 1
--		AND	i.indexid = '_'
--		ORDER BY c.recname, i.indexid, c.fieldnum
--		;
--
--		c_cols_cursor cols_cursor%ROWTYPE;
--	BEGIN
--		OPEN cols_cursor;
--		LOOP
--			FETCH cols_cursor INTO c_cols_cursor;
--			EXIT WHEN cols_cursor%NOTFOUND;
--
--			INSERT INTO gfc_ps_ind_columns
--			(recname, indexid, keyposn, fieldname, fieldnum, ascdesc)
--			SELECT	c_cols_cursor.recname
--			,	c_cols_cursor.indexid
--			,	MAX(keyposn)+1
--			,	c_cols_cursor.fieldname
--			,	c_cols_cursor.fieldnum
--			,	MOD(FLOOR(c_cols_cursor.useedit/32),2) --ascdesc
--			FROM	gfc_ps_ind_columns
--			WHERE	recname = c_cols_cursor.recname
--			AND	indexid = c_cols_cursor.indexid
--			;
--
--		END LOOP;
--		CLOSE cols_cursor;
--	END;

BEGIN
	expand_sbr;
--	expand_isbr;
	shuffle_long;
	gfc_ps_indexdefn;
	gfc_ps_keydefn;
END;
/

commit;

ANALYZE TABLE gfc_ps_tab_columns ESTIMATE statistics;

set head OFF message OFF verify OFF feedback OFF autotrace OFF echo OFF trimspool ON termout off
column SPOOL_FILENAME 	new_value SPOOL_FILENAME
SELECT /*'c:\temp\colaudit_'||*/lower(dbname)||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS')||'.log' SPOOL_FILENAME 
FROM ps.psdbowner WHERE ownerid = user;
spool &&SPOOL_FILENAME
undefine SPOOL_FILENAME
set head ON verify OFF feedback ON message OFF trimout ON lines 96 timi OFF pages 40 termout ON pause off
column recname 		heading 'PS Record Name'		format a15
column column_name 	heading 'Oracle Column Name'		format a23
column data_length 	heading 'Oracle|Length' 		format 9999
column data_precision   heading 'Oracle|Precision'
column data_scale	heading 'Oracle|Scale'
column data_type 	heading 'Oracle|Data Type'		format a9
column decimalpos	heading 'Decimal|Pos'			format 99999
column fieldname 	heading 'PS Field Name'			format a18
column length		heading 'PS|Length'			format 99999
column nullable		heading 'Oracle|nullable'
column required 	heading 'PS|Required' 			format a9
column object_type	heading 'Oracle|Object|Type'    	format a7
column object_name 	heading 'Oracle Object Name'		format a25
column table_name 	heading 'Oracle Table/View|Name'	format a18
column INDEX_name 	heading 'Oracle Index Name'		format a18
column fieldnum		heading 'Field|Number'			format 9999
column fieldtype_desc	heading 'PS Field|Type' 		format a10
column column_id	heading 'Oracle|Col ID'			format 9999
column rectype_desc   	heading 'PS Obj|Type' 			format a11
column sqltablename 	heading 'PS SQL Table Name'		format a18
column pscols		heading 'PS|Columns'			format 9999
column dbcols		heading 'Oracle|Columns'		format 9999
column keytype		heading 'Key Type'			format a10
column avg_row_len	heading 'Oracle Average|Row Length'	format 99999
column temptblinstances heading 'Temporary|Table|Instances'	format 990

set message ON echo OFF feedback ON

ttitle '(COL-01) Object In PeopleSoft Data Dictionary, but not in Oracle Database'

SELECT	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMPORARY TABLE') rectype_desc
,	r.recname, r.sqltablename
FROM	psrecdefn r
WHERE not exists
	(SELECT 'x'
	FROM	gfc_objects o
	WHERE 	o.object_type = DECODE(r.rectype, 0,'TABLE',1,'VIEW',6,'VIEW',7,'TABLE')  
	AND	o.object_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
	)
and 	r.rectype IN(
	0, /*TABLES*/
	1, /*views*/
	6, /*QUERY VIEWS*/
	7) /*TEMPORARY TABLE*/
order by 1,2
;

INSERT INTO gfc_rebuild (recname)
SELECT	recname
FROM	psrecdefn r
WHERE not exists
	(SELECT 'x'
	FROM	gfc_objects o
	WHERE 	o.object_type = DECODE(r.rectype, 0,'TABLE',1,'VIEW',6,'VIEW',7,'TABLE')  
	AND	o.object_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
	)
and 	r.rectype IN(
	0, /*TABLES*/
	1, /*views*/
	6, /*QUERY VIEWS*/
	7) /*TEMPORARY TABLE*/
;

ttitle '(COL-02) Object In Oracle Database Data Dictionary, but not in PeopleSoft'

SELECT	o.object_type, o.object_name
FROM	gfc_objects o
minus
SELECT	DECODE(r.rectype, 0,'TABLE',1,'VIEW',6,'VIEW',7,'TABLE')
,	DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
FROM	psrecdefn r
WHERE	r.rectype IN(0,1,6,7)
MINUS
SELECT	'TABLE'
,	o.object_name
--,	TO_NUMBER(SUBSTR(o.object_name,LENGTH(r.table_name)+1))
FROM	(SELECT	r.recname
	,	DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename) table_name
	FROM	psrecdefn r
	WHERE	r.rectype = 7 /*temp TABLE*/
	) r
,	gfc_objects o
WHERE	o.object_name like r.table_name||'%'
AND	o.object_name between r.table_name||'1' and r.table_name||'9999Z' 
AND	o.object_type = 'TABLE'
order by 2
;

ttitle '(COL-03) More Instances of PS Temporary Table Exist in Oracle than are defined in PeopleSoft'

SELECT	r.recname
--,	r.table_name
,	o.object_name table_name
,	r.temptblinstances
FROM	gfc_objects o
,	(SELECT	r.recname
	,	DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename) table_name
	,	NVL(c.temptblinstances,0)+o.temptblinstances temptblinstances
	FROM	psrecdefn r
	,	pstemptblcntvw c
	,	psoptions o
	WHERE	r.rectype = 7 /*temp TABLE*/
	AND	c.recname(+) = r.recname) r
WHERE	o.object_type = 'TABLE'
AND	o.object_name like r.table_name||'%'
AND	o.object_name between r.table_name||'1' and r.table_name||'9999' 
AND	TO_NUMBER(SUBSTR(o.object_name,LENGTH(r.table_name)+1)) > r.temptblinstances
--AND	o.object_name > r.table_name||r.temptblinstances
order by 1,2
;

INSERT INTO gfc_rebuild (recname)
SELECT	r.recname
FROM	gfc_objects o
,	(SELECT	r.recname
	,	DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename) table_name
	,	NVL(c.temptblinstances,0)+o.temptblinstances temptblinstances
	FROM	psrecdefn r
	,	pstemptblcntvw c
	,	psoptions o
	WHERE	r.rectype = 7 /*temp TABLE*/
	AND	c.recname(+) = r.recname) r
WHERE	o.object_type = 'TABLE'
AND	o.object_name like r.table_name||'%'
AND	o.object_name between r.table_name||'1' and r.table_name||'9999' 
AND	TO_NUMBER(SUBSTR(o.object_name,LENGTH(r.table_name)+1)) > r.temptblinstances
--AND	o.object_name > r.table_name||r.temptblinstances
;

ttitle '(COL-04) Corresponding PeopleSoft and Oracle Tables and Views with different numbers of columns'

SELECT	r.recname, d.table_name, p.pscols, d.dbcols
FROM	psrecdefn r
,	(	SELECT	recname, COUNT(*) pscols
		FROM	gfc_ps_tab_columns
		GROUP BY recname
	) p
,	(	SELECT	table_name, COUNT(*) dbcols
		FROM	gfc_ora_tab_columns
		GROUP BY table_name
	) d
WHERE	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	r.rectype IN(0,1,6,7)
AND	p.recname = r.recname
AND	p.pscols != d.dbcols
;

INSERT INTO gfc_rebuild (recname)
SELECT	r.recname
FROM	psrecdefn r
,	(	SELECT	recname, COUNT(*) pscols
		FROM	gfc_ps_tab_columns
		GROUP BY recname
	) p
,	(	SELECT	table_name, COUNT(*) dbcols
		FROM	gfc_ora_tab_columns
		GROUP BY table_name
	) d
WHERE	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	r.rectype IN(0,1,6,7)
AND	p.recname = r.recname
AND	p.pscols != d.dbcols
;

ttitle '(COL-05) Columns In PeopleSoft Data Dictionary, but not in Oracle Database'

SELECT	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMPORARY TABLE') rectype_desc
,	p.recname, p.fieldname, r.sqltablename
FROM	gfc_ps_tab_columns P
,	gfc_objects o
,	psrecdefn r
WHERE	r.recname = p.recname
AND	r.rectype IN(0,1,6,7)
AND	o.object_type = DECODE(r.rectype, 0,'TABLE',1,'VIEW',6,'VIEW',7,'TABLE')  
AND	o.object_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
and not exists
	(SELECT 'x'
	FROM	gfc_ora_tab_columns d
	WHERE	d.table_name = o.object_name 
	AND	d.column_name = p.fieldname)
order by 2,3
;

INSERT INTO gfc_rebuild (recname)
SELECT	DISTINCT p.recname
FROM	gfc_ps_tab_columns P
,	gfc_objects o
,	psrecdefn r
WHERE	r.recname = p.recname
AND	r.rectype IN(0,1,6,7)
AND	o.object_type = DECODE(r.rectype, 0,'TABLE',1,'VIEW',6,'VIEW',7,'TABLE')  
AND	o.object_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
and not exists
	(SELECT 'x'
	FROM	gfc_ora_tab_columns d
	WHERE	d.table_name = o.object_name 
	AND	d.column_name = p.fieldname)
;

ttitle '(COL-06) Columns In Oracle Database Data Dictionary, but not in PeopleSoft'

SELECT	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMPORARY TABLE') rectype_desc
,	r.recname, d.column_name, r.sqltablename
FROM	gfc_ora_tab_columns d
,	psrecdefn r
WHERE	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	r.rectype IN(0,1,6,7)
minus
SELECT	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMPORARY TABLE') rectype_desc
,	r.recname, p.fieldname, r.sqltablename
FROM	gfc_ps_tab_columns p
,	psrecdefn r
,	gfc_objects o
WHERE	r.recname = p.recname
AND	r.rectype IN(0,1,6,7)
AND	o.object_type = DECODE(r.rectype, 0,'TABLE',1,'VIEW',6,'VIEW',7,'TABLE')  
AND	o.object_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
order by 2,3
;

INSERT INTO gfc_rebuild (recname)
SELECT	DISTINCT recname
FROM	(
	SELECT	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMPORARY TABLE') rectype_desc
	,	r.recname, d.column_name, r.sqltablename
	FROM	gfc_ora_tab_columns d
	,	psrecdefn r
	WHERE	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
	AND	r.rectype IN(0,1,6,7)
	minus
	SELECT	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMPORARY TABLE') rectype_desc
	,	r.recname, p.fieldname, r.sqltablename
	FROM	gfc_ps_tab_columns p
	,	psrecdefn r
	,	gfc_objects o
	WHERE	r.recname = p.recname
	AND	r.rectype IN(0,1,6,7)
	AND	o.object_type = DECODE(r.rectype, 0,'TABLE',1,'VIEW',6,'VIEW',7,'TABLE')  
	AND	o.object_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
	)
;


ttitle '(COL-07 PT8.1) Columns in both Oracle and PeopleSoft, but different definitions'

SELECT  /*+ORDERED*/ 
	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMP TABLE') rectype_desc
,	r.recname
,	d.column_name
,	r.sqltablename
,	d.DATA_TYPE      
,	d.data_length    
,	d.data_precision 
,	d.data_scale     
,	DECODE(d.nullable,	'Y','nullable',	'N','Not Null') nullable
,	DECODE(f.fieldtype,	0,'Character',	1,'Long Char',	2,'Number',	
		3,'Sign Num',	4,'Date',	5,'Time',	6,'DateTime',	
		8,'Image',	9,'ImageRef'	) fieldtype_desc
,	f.length
,	f.decimalpos
--,	f.format
,	DECODE(mod(p.useedit/256,2),		1,'Required',	0,'Not Req') required
FROM	psrecdefn r
,	gfc_ora_tab_columns d
,	gfc_ps_tab_columns p
,	psdbfield f
,	(	SELECT 	unicode_enabled
		,	toolsrel
		, 	DECODE(unicode_enabled,0,1,1,3) unicode_factor
		FROM 	psstatus
		WHERE	TO_NUMBER(toolsrel) < 8.4
	) u
WHERE	r.rectype IN(0,7)
AND	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	p.recname = r.recname
AND	d.column_name = p.fieldname
AND	f.fieldname = p.fieldname
AND	(	(	mod(p.useedit/256,2) = 1 /*required*/
		AND	d.nullable ='Y'	)
	or	(	f.fieldtype IN(0,2,3) /*number or character*/
		AND	d.nullable = 'Y'
		)
	or	(	d.data_type = 'VARCHAR2' /*length mis match match*/
		AND	f.fieldtype = 0
		AND	d.data_length != LEAST(4000,f.length*u.unicode_factor) /*note unicode adjustment*/
		) 
	or	(	f.fieldtype = 1 /*long*/
		AND	f.length between 1 and 2000
		AND	d.data_type != 'VARCHAR2')
	or	(	f.fieldtype = 1 /*long*/
		AND	not f.length between 1 and 2000
		AND	f.format = 0 /*just long*/
		AND	d.data_type != 'LONG')
	or	(	f.fieldtype = 1 /*long*/
		AND	f.format = 7
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 2 /*number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 1 = f.length
				or	d.data_scale = 0)))
	or	(	f.fieldtype = 3 /*signed number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 2 = f.length
				or	d.data_scale = 0)))
	or 	(	f.fieldtype IN(4,5,6)
		AND	d.data_type != 'DATE')	
	or	(	f.fieldtype = 8 /*image*/
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 9 /*image ref*/
		AND	not 	(	d.data_type = 'VARCHAR2'
				AND	d.data_length = 30)))
order by 3,2
;

INSERT INTO gfc_rebuild (recname)
SELECT  /*+ORDERER*/ DISTINCT r.recname
FROM	psrecdefn r
,	gfc_ora_tab_columns d
,	gfc_ps_tab_columns p
,	psdbfield f
,	(	SELECT 	unicode_enabled
		, 	DECODE(unicode_enabled,0,1,1,3) unicode_factor
		,	toolsrel
		FROM 	psstatus
		WHERE	TO_NUMBER(toolsrel) < 8.4
	) u
WHERE	r.rectype IN(0,7)
AND	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	p.recname = r.recname
AND	d.column_name = p.fieldname
AND	f.fieldname = p.fieldname
AND	(	(	mod(p.useedit/256,2) = 1 /*required*/
		AND	d.nullable ='Y'	)
	or	(	f.fieldtype IN(0,2,3) /*number or character*/
		AND	d.nullable = 'Y'
		AND	(	p.fieldname = r.systemidfieldname /*new in PT8.14 - system id fields can be nullable*/
			OR	(	p.recname = 'PSSYSTEMID'
				AND	p.fieldname = 'PTUPDSYSTEMID'
				)
			)
		)
	or	(	d.data_type = 'VARCHAR2' /*length mis match match*/
		AND	f.fieldtype = 0
		AND	d.data_length != LEAST(4000,f.length*u.unicode_factor) /*note unicode adjustment*/
		) 
	or	(	f.fieldtype = 1 /*long*/
		AND	f.length between 1 and 2000
		AND	d.data_type != 'VARCHAR2')
	or	(	f.fieldtype = 1 /*long*/
		AND	not f.length between 1 and 2000
		AND	f.format = 0 /*just long*/
		AND	d.data_type != 'LONG')
	or	(	f.fieldtype = 1 /*long*/
		AND	f.format = 7
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 2 /*number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 1 = f.length
				or	d.data_scale = 0)))
	or	(	f.fieldtype = 3 /*signed number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 2 = f.length
				or	d.data_scale = 0)))
	or 	(	f.fieldtype IN(4,5,6)
		AND	d.data_type != 'DATE')	
	or	(	f.fieldtype = 8 /*image*/
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 9 /*image ref*/
		AND	not 	(	d.data_type = 'VARCHAR2'
				AND	d.data_length = 30)))
;

rem the following 2 statements will error on a PT8.1x database
ttitle '(COL-07 PT8.4) Columns in both Oracle and PeopleSoft, but different definitions'

SELECT  /*+ORDERED*/ 
	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMP TABLE') rectype_desc
,	r.recname
,	d.column_name
,	r.sqltablename
,	d.DATA_TYPE      
,	d.data_length    
,	d.data_precision 
,	d.data_scale     
,	DECODE(d.nullable,	'Y','nullable',	'N','Not Null') nullable
,	DECODE(f.fieldtype,	0,'Character',	1,'Long Char',	2,'Number',	
		3,'Sign Num',	4,'Date',	5,'Time',	6,'DateTime',	
		8,'Image',	9,'ImageRef'	) fieldtype_desc
,	f.length
,	f.decimalpos
--,	f.format
,	DECODE(mod(p.useedit/256,2),		1,'Required',	0,'Not Req') required
FROM	psrecdefn r
,	gfc_ora_tab_columns d
,	gfc_ps_tab_columns p
,	psdbfield f
,	(	SELECT 	unicode_enabled
		, 	DECODE(unicode_enabled,0,1,1,3) unicode_factor
		,	toolsrel
		FROM 	psstatus
		WHERE	TO_NUMBER(toolsrel) >= 8.4
	) u
WHERE	r.rectype IN(0,7)
AND	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	p.recname = r.recname
AND	d.column_name = p.fieldname
AND	f.fieldname = p.fieldname
AND	(	(	mod(p.useedit/256,2) = 1 /*required*/
		AND	d.nullable ='Y'	)
	or	(	f.fieldtype IN(0,2,3) /*number or character*/
		AND	d.nullable = 'Y'
		AND	NOT 	(	p.fieldname = r.systemidfieldname /*new in PT8.44 - system id fields can be nullable*/
				OR	(	p.recname = 'PSSYSTEMID'
					AND	p.fieldname = 'PTUPDSYSTEMID'
					)
				)
		)
	or	(	d.data_type = 'VARCHAR2' /*length mis match match*/
		AND	f.fieldtype = 0
		AND	d.data_length != LEAST(4000,f.length*u.unicode_factor) /*note unicode adjustment*/
		) 
	or	(	f.fieldtype = 1 /*long*/
		AND	f.length between 1 and 2000
		AND	d.data_type != 'VARCHAR2')
	or	(	f.fieldtype = 1 /*long*/
		AND	not f.length between 1 and 2000
		AND	f.format = 0 /*just long*/
		AND	d.data_type != 'LONG')
	or	(	f.fieldtype = 1 /*long*/
		AND	f.format = 7
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 2 /*number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 1 = f.length
				or	d.data_scale = 0)))
	or	(	f.fieldtype = 3 /*signed number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 2 = f.length
				or	d.data_scale = 0)))
	or 	(	f.fieldtype IN(4,5,6)
		AND	d.data_type != 'DATE')	
	or	(	f.fieldtype = 8 /*image*/
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 9 /*image ref*/
		AND	not 	(	d.data_type = 'VARCHAR2'
				AND	d.data_length = 30)))
order by 3,2
;

INSERT INTO gfc_rebuild (recname)
SELECT  /*+ORDERER*/ DISTINCT r.recname
FROM	psrecdefn r
,	gfc_ora_tab_columns d
,	gfc_ps_tab_columns p
,	psdbfield f
,	(	SELECT 	unicode_enabled
		, 	DECODE(unicode_enabled,0,1,1,3) unicode_factor
		,	toolsrel
		FROM	psstatus
		WHERE	TO_NUMBER(toolsrel) >= 8.4
	) u
WHERE	r.rectype IN(0,7)
AND	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	p.recname = r.recname
AND	d.column_name = p.fieldname
AND	f.fieldname = p.fieldname
AND	(	(	mod(p.useedit/256,2) = 1 /*required*/
		AND	d.nullable ='Y'	)
	or	(	f.fieldtype IN(0,2,3) /*number or character*/
		AND	d.nullable = 'Y'
		AND	NOT 	(	p.fieldname = r.systemidfieldname /*new in PT8.44 - system id fields can be nullable*/
				OR	(	p.recname = 'PSSYSTEMID'
					AND	p.fieldname = 'PTUPDSYSTEMID'
					)
				)
		)
	or	(	d.data_type = 'VARCHAR2' /*length mis match match*/
		AND	f.fieldtype = 0
		AND	d.data_length != LEAST(4000,f.length*u.unicode_factor) /*note unicode adjustment*/
		) 
	or	(	f.fieldtype = 1 /*long*/
		AND	f.length between 1 and 2000
		AND	d.data_type != 'VARCHAR2')
	or	(	f.fieldtype = 1 /*long*/
		AND	not f.length between 1 and 2000
		AND	f.format = 0 /*just long*/
		AND	d.data_type != 'LONG')
	or	(	f.fieldtype = 1 /*long*/
		AND	f.format = 7
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 2 /*number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 1 = f.length
				or	d.data_scale = 0)))
	or	(	f.fieldtype = 3 /*signed number*/
		AND	not
			(	d.data_type = 'NUMBER'
			AND	d.data_scale = f.decimalpos
			AND	(	d.data_precision + 2 = f.length
				or	d.data_scale = 0)))
	or 	(	f.fieldtype IN(4,5,6)
		AND	d.data_type != 'DATE')	
	or	(	f.fieldtype = 8 /*image*/
		AND	d.data_type != 'LONG RAW')
	or	(	f.fieldtype = 9 /*image ref*/
		AND	not 	(	d.data_type = 'VARCHAR2'
				AND	d.data_length = 30)))
;

ttitle '(COL-08) Records referenced as, but no longer defined as subrecords'

SELECT r.recname, f.fieldname
FROM psrecfield f
, psrecdefn r
WHERE r.recname = f.recname
and r.rectype != 3
and not exists(
 SELECT 'x'
 FROM psdbfield d
 WHERE d.fieldname = f.fieldname
 union all
 SELECT 'x'
 FROM psrecdefn r1
 WHERE r1.recname = f.fieldname
 and r1.rectype = 3)
order by 1,2
/

ttitle '(COL-09) Tables/Views with same Number of Columns in both Oracle and PeopleSoft, but in different Positions'

SELECT  /*+ORDERED*/ 
	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMP TABLE') rectype_desc
,	r.recname
,	d.column_name
,	r.sqltablename
,	d.column_id
,	p.fieldnum
FROM	psrecdefn r
,	gfc_ora_tab_columns d
,	gfc_ps_tab_columns p
,	psdbfield f
,	(	SELECT	recname, COUNT(*) pscols
		FROM	gfc_ps_tab_columns
		GROUP BY recname
	) p1
,	(	SELECT	table_name, COUNT(*) dbcols
		FROM	gfc_ora_tab_columns
		GROUP BY table_name
	) d1
WHERE	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	r.rectype IN(0,1,6,7)
AND	p1.recname = p.recname
AND	d1.table_name = d.table_name
AND	p.recname = r.recname
AND	d.column_name = p.fieldname
AND	f.fieldname = p.fieldname
AND	d.column_id != p.fieldnum
AND	p1.pscols = d1.dbcols
order by r.recname, p.fieldnum
;

INSERT INTO gfc_rebuild (recname)
SELECT  /*+ORDERED*/ 
	DISTINCT r.recname
FROM	psrecdefn r
,	gfc_ora_tab_columns d
,	gfc_ps_tab_columns p
,	psdbfield f
,	(	SELECT	recname, COUNT(*) pscols
		FROM	gfc_ps_tab_columns
		GROUP BY recname
	) p1
,	(	SELECT	table_name, COUNT(*) dbcols
		FROM	gfc_ora_tab_columns
		GROUP BY table_name
	) d1
WHERE	d.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	r.rectype IN(0,1,6,7)
AND	p1.recname = p.recname
AND	d1.table_name = d.table_name
AND	p.recname = r.recname
AND	d.column_name = p.fieldname
AND	f.fieldname = p.fieldname
AND	d.column_id != p.fieldnum
AND	p1.pscols = d1.dbcols
;

ttitle '(COL-10) Corresponding PeopleSoft and Oracle Indexes with different numbers of columns'

SELECT	k.recname, k.indexid, i.table_name, i.INDEX_name, i.dbcols, k.pscols
FROM	(
	SELECT	table_name, INDEX_name, count(*) dbcols
	FROM	gfc_ora_ind_columns
	group by table_name, INDEX_name) i
,	(
        SELECT	recname, indexid, count(*) pscols
	FROM	gfc_ps_keydefn
	group by recname, indexid) k
,	psrecdefn r
where	k.recname = r.recname
AND	i.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	i.INDEX_name = 'PS'||k.indexid||k.recname
and 	i.dbcols != k.pscols
order by k.recname, k.indexid
;

INSERT INTO gfc_rebuild
SELECT	k.recname, k.indexid
FROM	(
	SELECT	table_name, INDEX_name, count(*) dbcols
	FROM	gfc_ora_ind_columns
	group by table_name, INDEX_name) i
,	(SELECT	recname, indexid, count(*) pscols
	FROM	gfc_ps_keydefn
	group by recname, indexid) k
,	psrecdefn r
where	k.recname = r.recname
AND	i.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	i.INDEX_name = 'PS'||k.indexid||k.recname
and 	i.dbcols != k.pscols
;

ttitle '(COL-11) Indexes in both Oracle and PeopleSoft, but with Columns in different Positions'

SELECT	k.recname, k.indexid, k.fieldname, k.keyposn, i.column_position
FROM	psrecdefn r
,	gfc_ps_keydefn k
,	gfc_ora_ind_columns i
where	k.recname = r.recname
AND	i.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	i.INDEX_name = 'PS'||k.indexid||k.recname
AND	k.fieldname = i.column_name
and 	k.keyposn != i.column_position
order by k.recname, k.indexid, k.keyposn
;

INSERT INTO gfc_rebuild
SELECT	DISTINCT k.recname, k.indexid
FROM	psrecdefn r
,	gfc_ps_keydefn k
,	gfc_ora_ind_columns i
where	k.recname = r.recname
AND	i.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
AND	i.INDEX_name = 'PS'||k.indexid||k.recname
AND	k.fieldname = i.column_name
and 	k.keyposn != i.column_position
;


ttitle '(COL-12) Warning: Key Columns not at top of Record Definition'

SELECT	DECODE(r.rectype,0,'TABLE',1,'VIEW',6,'QUERY VIEW',7,'TEMP TABLE') rectype_desc
,	a.recname, a.fieldnum, a.fieldname
,	DECODE(mod(a.useedit/2,2),1,'Duplicate','Unique') keytype
,	DECODE(t.avg_row_len,0,TO_NUMBER(NULL),t.avg_row_len) avg_row_len
FROM	gfc_ps_tab_columns a
,	gfc_ps_tab_columns b
,	psrecdefn r
,	user_tables t
where	(	mod(a.useedit/2,2) = 1 /*duplicate key*/
	or	mod(a.useedit  ,2) = 1) /*key*/
AND	b.fieldnum = a.fieldnum - 1
AND	r.rectype IN(0,7)
AND	b.recname = a.recname
AND	r.recname = a.recname
and not (	mod(b.useedit/2,2) = 1 /*duplicate key*/
	or	mod(b.useedit  ,2) = 1) /*key*/
AND	t.table_name(+) = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
and 	1=2 /*TEST DISABLED BECAUSE PSFT NO LONGER ADHERE TO THIS STANDARD*/
order by 2,3
;


spool off
ttitle off
set verify on
set feedback on
set message on
set timi on

lock table pslock in exclusive mode
;

SELECT	VERSION
FROM 	PSLOCK 
WHERE 	OBJECTTYPENAME IN ('PJM') 
FOR UPDATE OF VERSION
;

delete	FROM gfc_rebuild
where 	recname IN(
SELECT	r.recname
FROM	psrecdefn r
,	user_tables t
where	t.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
and 	r.rectype IN(0,7)
AND	t.tablespace_name IS NULL
)
;
	    
DELETE FROM PSPROJECTDEL 	WHERE PROJECTNAME = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD');
DELETE FROM PSPROJECTITEM 	WHERE PROJECTNAME = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD');
DELETE FROM PSPROJECTSEC 	WHERE PROJECTNAME = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD');
DELETE FROM PSPROJECTINC 	WHERE PROJECTNAME = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD');
DELETE FROM PSPROJECTDEP 	WHERE PROJECTNAME = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD');
DELETE FROM PSPROJECTDEFN 	WHERE PROJECTNAME = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD');
DELETE FROM PSPROJDEFNLANG 	WHERE PROJECTNAME = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD');

INSERT INTO psprojectitem
(	PROJECTNAME, OBJECTTYPE, OBJECTID1, OBJECTVALUE1, 
	OBJECTID2, OBJECTVALUE2, OBJECTID3, OBJECTVALUE3, 
	OBJECTID4, OBJECTVALUE4, NODETYPE, SOURCESTATUS, 
	TARGETSTATUS, UPGRADEACTION, TAKEACTION, COPYDONE)
SELECT	'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD'),0,1,recname,
	0,' ',0,' ',
	0,' ',0,0,
	0,0,1,0
FROM	(SELECT DISTINCT recname
	FROM	gfc_rebuild)
;

INSERT INTO psprojectitem
(	PROJECTNAME, OBJECTTYPE, OBJECTID1, OBJECTVALUE1, 
	OBJECTID2, OBJECTVALUE2, OBJECTID3, OBJECTVALUE3, 
	OBJECTID4, OBJECTVALUE4, NODETYPE, SOURCESTATUS, 
	TARGETSTATUS, UPGRADEACTION, TAKEACTION, COPYDONE)
SELECT	'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD'),1,1,recname,
	24,indexid,0,' ',
	0,' ',0,0,
	0,0,1,0
FROM	(SELECT DISTINCT recname, indexid
	FROM	gfc_rebuild
	WHERE	indexid IS NOT NULL)
;

SELECT	p.projectname, r.recname, t.tablespace_name
FROM	psprojectitem p
,	psrecdefn r
,	user_tables t
where	p.objecttype = 0
AND	p.objectid1 = 1
AND	p.objectvalue1 = r.recname
AND	t.table_name = DECODE(r.sqltablename,' ','PS_'||r.recname,r.sqltablename)
and 	r.rectype IN(0,7)
AND	t.tablespace_name IS NULL
AND	p.projectname = 'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD')
;

rem -- For PT8.1x
rem -- this statement will error on PT8.4x, in which case it should be deleted
INSERT INTO PSPROJECTDEFN 
	(VERSION, PROJECTNAME, TGTSERVERNAME, TGTDBNAME, TGTOPRID, 
	TGTOPRACCT, REPORTFILTER, TGTORIENTATION, COMPARETYPE, KEEPTGT, 
	COMMITLIMIT, MAINTPROJ, COMPRELEASE, COMPRELDTTM, LASTUPDDTTM, 
	LASTUPDOPRID, PROJECTDESCR, RELEASELABEL, RELEASEDTTM) 
VALUES ((SELECT	VERSION
	FROM 	PSLOCK 
	WHERE 	OBJECTTYPENAME IN ('PJM')),
	'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD'),' ',' ',' ',
	' ',16232832,0,1,3,
	50,0,' ',NULL,SYSDATE,
	'PS','Project built COLAUDIT script',' ',NULL)
;


rem -- objectowner and descrlong added for PeopleTools 8.4x
rem -- this statement will error on PT8.1x, in which case it should be deleted
INSERT INTO PSPROJECTDEFN 
	(VERSION, PROJECTNAME, TGTSERVERNAME, TGTDBNAME, TGTOPRID, 
	TGTOPRACCT, REPORTFILTER, TGTORIENTATION, COMPARETYPE, KEEPTGT, 
	COMMITLIMIT, MAINTPROJ, COMPRELEASE, COMPRELDTTM, LASTUPDDTTM, 
	LASTUPDOPRID, PROJECTDESCR, RELEASELABEL, RELEASEDTTM, 
	OBJECTOWNERID,DESCRLONG) 
VALUES ((SELECT	VERSION
	FROM 	PSLOCK 
	WHERE 	OBJECTTYPENAME IN ('PJM')),
	'COLAUDIT_'||TO_CHAR(SYSDATE, 'YYYYMMDD'),' ',' ',' ',
	' ',16232832,0,1,3,
	50,0,' ',NULL,SYSDATE,
	'PS','Project built COLAUDIT script',' ',NULL,'GFC',
	'This application designer project was generated by the colaudit.sql script on '
		||TO_CHAR(sysdate,'hh24:MI:SS dd.mm.yyyy'))
;

UPDATE 	psversion 
SET 	version = version + 1 
WHERE 	objecttypename = 'PJM'
;

UPDATE 	pslock 
SET 	version = version + 1 
WHERE 	objecttypename IN ('PJM','SYS')
;

pause

DROP TABLE gfc_ps_tab_columns;
DROP TABLE gfc_ps_ind_columns;
DROP TABLE gfc_ps_indexdefn;
DROP TABLE gfc_ps_keydefn;
DROP TABLE gfc_objects;
DROP TABLE gfc_ora_tab_columns;
DROP TABLE gfc_ora_ind_columns;
DROP TABLE gfc_rebuild;
DROP VIEW  gfc_ps_alt_ind_cols;
DROP VIEW  gfc_ps_keydefn_vw;


WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
spool off
rem ALTER SESSION SET sql_trace = FALSE;
