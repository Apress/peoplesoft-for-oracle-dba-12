SELECT jolt_bytes, cum_prop_msg, cum_prop_vol, num_messages
FROM (     SELECT z.*
    ,      SUM(prop_message) OVER (ORDER BY jolt_bytes 
                                   RANGE UNBOUNDED PRECEDING) AS cum_prop_msg
    ,      SUM(prop_volume)  OVER (ORDER BY jolt_bytes 
                                   RANGE UNBOUNDED PRECEDING) AS cum_prop_vol
    FROM   (   SELECT y.*
        ,      ratio_to_report(num_messages) OVER () AS prop_message
        ,      ratio_to_report(sum_bytes) OVER () AS prop_volume
        FROM   (   SELECT x.*, COUNT(*) num_messages, SUM(jolt_bytes) sum_bytes
            FROM   (
                SELECT c.pm_metric_value1 jolt_bytes
                FROM   pspmtranshist c, pspmagent b, pspmsysdefn a
                WHERE  a.pm_systemid = b.pm_systemid
                AND    b.pm_agentid = c.pm_agentid
                AND    c.pm_trans_defn_set = 1 AND  c.pm_trans_defn_id = 115
                AND    c.pm_trans_status = 1
/*              AND    a.dbname IN(<list of database names>)
                AND    c.pm_agent_strt_dttm >= SYSDATE - 3*/
                UNION ALL
                SELECT c.pm_metric_value2 jolt_bytes
                FROM   pspmtranshist c, pspmagent b, pspmsysdefn a
                WHERE  a.pm_systemid = b.pm_systemid
                AND    b.pm_agentid = c.pm_agentid
                AND    c.pm_trans_defn_set = 1 AND  c.pm_trans_defn_id = 115
                AND    c.pm_trans_status = 1
/*              AND    a.dbname IN(<list of database names>)
                AND    c.pm_agent_strt_dttm >= SYSDATE - 3*/
            ) x GROUP by jolt_bytes ) y ) Z
) ORDER BY jolt_bytes
/
