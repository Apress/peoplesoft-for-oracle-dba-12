del *.lst
del *.bad
del *.dsc

set CONNECT=scott/tiger@gofaster

sqlplus -s %CONNECT% @tracesql_pre.sql
sqlldr userid=%CONNECT% parfile=tracesql.par
sqlplus -s %CONNECT% @tracesql_post.sql

start tracesql.xls
pause
