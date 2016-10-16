spool tuxlog_post

create or replace view tuxlog_cum_vw 
as 
select	msg_size
,	sum(rr_num) over (order by msg_size range unbounded preceding) prop_msg
,	sum(rr_msg_size) over (order by msg_size range unbounded preceding) prop_bndw
from	(
	select  msg_size
	,	ratio_to_report(1) over () rr_num
	,	ratio_to_report(msg_size) over () rr_msg_size
	from	tuxlog
	)
order by msg_size
;

exit

