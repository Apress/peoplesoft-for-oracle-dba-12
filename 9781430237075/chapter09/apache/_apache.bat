del *.lst
del *.bad
del *.dsc

set CONNECT=scott/tiger@gofaster

sqlplus -s %CONNECT% @wl_pre.sql
sqlldr userid=%CONNECT% parfile=apache.par
sqlplus -s %CONNECT% @wl_post.sql

pause

start wl.xls
start wl_avg.xls
start wl_max.xls
start wl_sum.xls


