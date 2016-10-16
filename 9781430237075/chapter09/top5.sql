column prcrnk   format 99
column freq     format 999
--column dur      format 99990
column prcstype format a18
--column descr    format a21
select x.*
--,      d.descr
from   (
       select prcstype, prcsname
       ,      dur
       ,      avg_dur
       ,      freq
       ,      rank() over (order by dur desc) prcrnk
       from   (
              select prcstype, prcsname
              ,      count(*) freq
              ,      sum(enddttm-begindttm)*86400 dur
              ,      avg(enddttm-begindttm)*86400 avg_dur
              from   psprcsrqst p
              where  begindttm IS NOT NULL
              and    enddttm IS NOT NULL /*have completed*/
              and    runstatus IN(9,11,14) /*sucessful processes*/
              and    begindttm > SYSDATE - 30 /*in the last 30 days*/
              group by prcstype, prcsname
              )
       ) x
,      ps_prcsdefn d
where  x.prcrnk <= 5
and    d.prcstype(+) = x.prcstype
and    d.prcsname(+) = x.prcsname
order by x.prcrnk
/
