SELECT
  set,scale,
  pg_size_pretty(avg(table_size)::int8) AS table_size,
  pg_size_pretty(avg(index_size)::int8) AS index_size,
  clients,
  rate_limit,
  round(avg(tps)) as tps,
  round(1000 * avg(avg_latency))/1000 AS avg_latency,
  round(1000 * avg(max_latency))/1000 AS max_latency ,
  round(1000 * avg(percentile_90_latency))/1000 AS "90%<",
  to_char(avg(end_time -  start_time),'HH24:MI:SS') AS runtime
FROM tests 
GROUP BY set,scale,clients,rate_limit 
ORDER BY set,scale,clients,rate_limit; 
