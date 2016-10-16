spool wl_post

create index weblogic on weblogic(timestamp) 
--local 
compress
;

analyze table weblogic estimate statistics;

--rem update scenarios here

exit
