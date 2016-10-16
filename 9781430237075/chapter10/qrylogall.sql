rem qrylogall.sql

UPDATE pslock
SET    version = version + 1
WHERE  objecttypename IN('SYS','QDM');

UPDATE psversion
SET    version = version + 1
WHERE  objecttypename IN('SYS','QDM');

UPDATE psqrydefn
SET    execlogging = 'Y'
,      version = (SELECT version FROM pslock WHERE objecttypename = 'QDM')
WHERE  execlogging != 'Y';
