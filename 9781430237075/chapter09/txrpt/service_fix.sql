update	txrpt
set	queue = 'JREPQ'
where	queue != 'JREPQ'
and	service IN('.GETSVC','.GETALL')
;

update	txrpt
set	queue = 'SAMQ'
where	queue != 'SAMQ'
and	service = 'SqlAccess'
;

update	txrpt
set	queue = 'QRYQ'
where	queue != 'QRYQ'
and	service = 'SqlQuery'
;

update	txrpt
set	queue = 'QCKQ'
where	queue != 'QCKQ'
and	service IN('SqlRequest','MgrClear','RamList','SamGetParmsSvc')
;

select queue, service, min(stimestamp), max(stimestamp), count(*)
from txrpt
group  by queue, service
;
