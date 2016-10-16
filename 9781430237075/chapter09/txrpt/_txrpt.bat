del *.lst
del *.bad
del *.dsc

txrpt <APPQ.stderr > txrpt.out

set CONNECT=scott/tiger@gofaster
rem TZ=GMT2

sqlplus -s %CONNECT% @txrpt_pre.sql
sqlldr userid=%CONNECT% parfile=txrpt.par
sqlplus -s %CONNECT% @txrpt_post.sql

start txrpt.xls

