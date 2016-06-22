SELECT
  set,scale,
  pg_size_pretty(avg(table_size)::int8) AS table_size,
  pg_size_pretty(avg(table_size)::int8 / scale) AS table_size_per_scale,
  pg_size_pretty(avg(index_size)::int8) AS index_size,
  pg_size_pretty(avg(index_size)::int8 / scale) AS index_size_per_scale,
  clients,
  round(avg(tps)) as tps,
  round(avg(tps)/clients) as tps_per_client,
  round(1000 * avg(max_latency))/1000 AS max_latency ,
  to_char(avg(end_time -  start_time),'HH24:MI:SS') AS runtime
FROM tests 
GROUP BY set,scale,clients 
ORDER BY set,scale,clients; 
