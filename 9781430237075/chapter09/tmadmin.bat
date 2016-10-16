REM tmadmin.bat
REM (c) Go-Faster Consultancy Ltd. 2004-2011

set TUXDIR=d:\ps\bea\tuxedo8.1
set PS_SERVDIR=D:\ps\hcm8.9\appserv\HCM89
REM set PS_SERVER_CFG=%PS_SERVDIR%\psappsrv.cfg
set TUXCONFIG=%PS_SERVDIR%\PSTUXCFG

%TUXDIR%\bin\tmadmin -r <tmadmin.in >tmadmin.out

pause