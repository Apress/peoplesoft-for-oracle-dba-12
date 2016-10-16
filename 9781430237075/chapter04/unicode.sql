rem unicode.sql
rem (c) Go-Faster Consultancy Ltd. 2004

spool unicode
set echo on feedback on verify on timi on autotrace off
select * from v$version;

create table test_nocons
(id          number
,field_01 varchar2(30)
,field_02 varchar2(30)
,field_03 varchar2(30)
,field_04 varchar2(30)
,field_05 varchar2(30)
,field_06 varchar2(30)
,field_07 varchar2(30)
,field_08 varchar2(30)
,field_09 varchar2(30)
,field_10 varchar2(30)
,field_11 varchar2(30)
,field_12 varchar2(30)
,field_13 varchar2(30)
,field_14 varchar2(30)
,field_15 varchar2(30)
,field_16 varchar2(30)
,field_17 varchar2(30)
,field_18 varchar2(30)
,field_19 varchar2(30)
,field_20 varchar2(30)
) STORAGE(INITIAL 256K);

create table test_cons
(id          number
,field_01 varchar2(30) CHECK(LENGTH(field_01)<=30)
,field_02 varchar2(30) CHECK(LENGTH(field_02)<=30)
,field_03 varchar2(30) CHECK(LENGTH(field_03)<=30)
,field_04 varchar2(30) CHECK(LENGTH(field_04)<=30)
,field_05 varchar2(30) CHECK(LENGTH(field_05)<=30)
,field_06 varchar2(30) CHECK(LENGTH(field_06)<=30)
,field_07 varchar2(30) CHECK(LENGTH(field_07)<=30)
,field_08 varchar2(30) CHECK(LENGTH(field_08)<=30)
,field_09 varchar2(30) CHECK(LENGTH(field_09)<=30)
,field_10 varchar2(30) CHECK(LENGTH(field_10)<=30)
,field_11 varchar2(30) CHECK(LENGTH(field_11)<=30)
,field_12 varchar2(30) CHECK(LENGTH(field_12)<=30)
,field_13 varchar2(30) CHECK(LENGTH(field_13)<=30)
,field_14 varchar2(30) CHECK(LENGTH(field_14)<=30)
,field_15 varchar2(30) CHECK(LENGTH(field_15)<=30)
,field_16 varchar2(30) CHECK(LENGTH(field_16)<=30)
,field_17 varchar2(30) CHECK(LENGTH(field_17)<=30)
,field_18 varchar2(30) CHECK(LENGTH(field_18)<=30)
,field_19 varchar2(30) CHECK(LENGTH(field_19)<=30)
,field_20 varchar2(30) CHECK(LENGTH(field_20)<=30)
) STORAGE(INITIAL 256K);

truncate table test_cons;
BEGIN
  FOR i IN 1..10000 LOOP
    INSERT INTO test_cons
    VALUES(i
          ,RPAD(TO_CHAR(i),11,'.')
          ,RPAD(TO_CHAR(i),12,'.')
          ,RPAD(TO_CHAR(i),13,'.')
          ,RPAD(TO_CHAR(i),14,'.')
          ,RPAD(TO_CHAR(i),15,'.')
          ,RPAD(TO_CHAR(i),16,'.')
          ,RPAD(TO_CHAR(i),17,'.')
          ,RPAD(TO_CHAR(i),18,'.')
          ,RPAD(TO_CHAR(i),19,'.')
          ,RPAD(TO_CHAR(i),20,'.')
          ,RPAD(TO_CHAR(i),21,'.')
          ,RPAD(TO_CHAR(i),22,'.')
          ,RPAD(TO_CHAR(i),23,'.')
          ,RPAD(TO_CHAR(i),24,'.')
          ,RPAD(TO_CHAR(i),25,'.')
          ,RPAD(TO_CHAR(i),26,'.')
          ,RPAD(TO_CHAR(i),27,'.')
          ,RPAD(TO_CHAR(i),28,'.')
          ,RPAD(TO_CHAR(i),29,'.')
          ,RPAD(TO_CHAR(i),30,'.')
           );
  END LOOP;
  COMMIT;
END;
/
truncate table test_nocons;
BEGIN
  FOR i IN 1..10000 LOOP
     INSERT INTO test_nocons
     VALUES(i
           ,RPAD(TO_CHAR(i),11,'.')
           ,RPAD(TO_CHAR(i),12,'.')
           ,RPAD(TO_CHAR(i),13,'.')
           ,RPAD(TO_CHAR(i),14,'.')
           ,RPAD(TO_CHAR(i),15,'.')
           ,RPAD(TO_CHAR(i),16,'.')
           ,RPAD(TO_CHAR(i),17,'.')
           ,RPAD(TO_CHAR(i),18,'.')
           ,RPAD(TO_CHAR(i),19,'.')
           ,RPAD(TO_CHAR(i),20,'.')
           ,RPAD(TO_CHAR(i),21,'.')
           ,RPAD(TO_CHAR(i),22,'.')
           ,RPAD(TO_CHAR(i),23,'.')
           ,RPAD(TO_CHAR(i),24,'.')
           ,RPAD(TO_CHAR(i),25,'.')
           ,RPAD(TO_CHAR(i),26,'.')
           ,RPAD(TO_CHAR(i),27,'.')
           ,RPAD(TO_CHAR(i),28,'.')
           ,RPAD(TO_CHAR(i),29,'.')
           ,RPAD(TO_CHAR(i),30,'.')
           );
    END LOOP;
    COMMIT;
END;
/

truncate table test_nocons reuse storage;
pause
BEGIN
  FOR i IN 1..10000 LOOP
    INSERT INTO test_nocons
    VALUES(i
          ,RPAD(TO_CHAR(i),11,'.')
          ,RPAD(TO_CHAR(i),12,'.')
          ,RPAD(TO_CHAR(i),13,'.')
          ,RPAD(TO_CHAR(i),14,'.')
          ,RPAD(TO_CHAR(i),15,'.')
          ,RPAD(TO_CHAR(i),16,'.')
          ,RPAD(TO_CHAR(i),17,'.')
          ,RPAD(TO_CHAR(i),18,'.')
          ,RPAD(TO_CHAR(i),19,'.')
          ,RPAD(TO_CHAR(i),20,'.')
          ,RPAD(TO_CHAR(i),21,'.')
          ,RPAD(TO_CHAR(i),22,'.')
          ,RPAD(TO_CHAR(i),23,'.')
          ,RPAD(TO_CHAR(i),24,'.')
          ,RPAD(TO_CHAR(i),25,'.')
          ,RPAD(TO_CHAR(i),26,'.')
          ,RPAD(TO_CHAR(i),27,'.')
          ,RPAD(TO_CHAR(i),28,'.')
          ,RPAD(TO_CHAR(i),29,'.')
          ,RPAD(TO_CHAR(i),30,'.')
           );
  END LOOP;
  COMMIT;
END;
/

truncate table test_cons reuse storage;
pause
BEGIN
  FOR i IN 1..10000 LOOP
     INSERT INTO test_cons
     VALUES(i
           ,RPAD(TO_CHAR(i),11,'.')
           ,RPAD(TO_CHAR(i),12,'.')
           ,RPAD(TO_CHAR(i),13,'.')
           ,RPAD(TO_CHAR(i),14,'.')
           ,RPAD(TO_CHAR(i),15,'.')
           ,RPAD(TO_CHAR(i),16,'.')
           ,RPAD(TO_CHAR(i),17,'.')
           ,RPAD(TO_CHAR(i),18,'.')
           ,RPAD(TO_CHAR(i),19,'.')
           ,RPAD(TO_CHAR(i),20,'.')
           ,RPAD(TO_CHAR(i),21,'.')
           ,RPAD(TO_CHAR(i),22,'.')
           ,RPAD(TO_CHAR(i),23,'.')
           ,RPAD(TO_CHAR(i),24,'.')
           ,RPAD(TO_CHAR(i),25,'.')
           ,RPAD(TO_CHAR(i),26,'.')
           ,RPAD(TO_CHAR(i),27,'.')
           ,RPAD(TO_CHAR(i),28,'.')
           ,RPAD(TO_CHAR(i),29,'.')
           ,RPAD(TO_CHAR(i),30,'.')
           );
    END LOOP;
    COMMIT;
END;
/

truncate table test_nocons reuse storage;
pause
BEGIN
  FOR i IN 1..10000 LOOP
    EXECUTE IMMEDIATE 'INSERT INTO test_nocons VALUES ('||i
      ||',RPAD(TO_CHAR('||i||'),11,''.'')'
      ||',RPAD(TO_CHAR('||i||'),12,''.'')'
      ||',RPAD(TO_CHAR('||i||'),13,''.'')'
      ||',RPAD(TO_CHAR('||i||'),14,''.'')'
      ||',RPAD(TO_CHAR('||i||'),15,''.'')'
      ||',RPAD(TO_CHAR('||i||'),16,''.'')'
      ||',RPAD(TO_CHAR('||i||'),17,''.'')'
      ||',RPAD(TO_CHAR('||i||'),18,''.'')'
      ||',RPAD(TO_CHAR('||i||'),19,''.'')'
      ||',RPAD(TO_CHAR('||i||'),20,''.'')'
      ||',RPAD(TO_CHAR('||i||'),21,''.'')'
      ||',RPAD(TO_CHAR('||i||'),22,''.'')'
      ||',RPAD(TO_CHAR('||i||'),23,''.'')'
      ||',RPAD(TO_CHAR('||i||'),24,''.'')'
      ||',RPAD(TO_CHAR('||i||'),25,''.'')'
      ||',RPAD(TO_CHAR('||i||'),26,''.'')'
      ||',RPAD(TO_CHAR('||i||'),27,''.'')'
      ||',RPAD(TO_CHAR('||i||'),28,''.'')'
      ||',RPAD(TO_CHAR('||i||'),29,''.'')'
      ||',RPAD(TO_CHAR('||i||'),30,''.''))';
  END LOOP;
  COMMIT;
END;
/


truncate table test_cons reuse storage;
pause
BEGIN
  FOR i IN 1..10000 LOOP
    EXECUTE IMMEDIATE 'INSERT INTO test_cons VALUES ('||i
      ||',RPAD(TO_CHAR('||i||'),11,''.'')'
      ||',RPAD(TO_CHAR('||i||'),12,''.'')'
      ||',RPAD(TO_CHAR('||i||'),13,''.'')'
      ||',RPAD(TO_CHAR('||i||'),14,''.'')'
      ||',RPAD(TO_CHAR('||i||'),15,''.'')'
      ||',RPAD(TO_CHAR('||i||'),16,''.'')'
      ||',RPAD(TO_CHAR('||i||'),17,''.'')'
      ||',RPAD(TO_CHAR('||i||'),18,''.'')'
      ||',RPAD(TO_CHAR('||i||'),19,''.'')'
      ||',RPAD(TO_CHAR('||i||'),20,''.'')'
      ||',RPAD(TO_CHAR('||i||'),21,''.'')'
      ||',RPAD(TO_CHAR('||i||'),22,''.'')'
      ||',RPAD(TO_CHAR('||i||'),23,''.'')'
      ||',RPAD(TO_CHAR('||i||'),24,''.'')'
      ||',RPAD(TO_CHAR('||i||'),25,''.'')'
      ||',RPAD(TO_CHAR('||i||'),26,''.'')'
      ||',RPAD(TO_CHAR('||i||'),27,''.'')'
      ||',RPAD(TO_CHAR('||i||'),28,''.'')'
      ||',RPAD(TO_CHAR('||i||'),29,''.'')'
      ||',RPAD(TO_CHAR('||i||'),30,''.''))';
  END LOOP;
  COMMIT;
END;
/

spool off
drop table test_nocons;
drop table test_cons;
