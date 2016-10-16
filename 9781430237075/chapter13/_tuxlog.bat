del *.lst
del *.bad
del *.dsc

set CONNECT=scott/tiger@gofaster

sqlplus -s %CONNECT% @tuxlog_pre.sql
sqlldr userid=%CONNECT% parfile=tuxlog.par
sqlplus -s %CONNECT% @tuxlog_post.sql

start tuxlog.xls

