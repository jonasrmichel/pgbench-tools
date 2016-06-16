set term png size 640,480
set terminal png medium
set output "scaling-latency.png"
set title "pgbench latency"
set grid xtics ytics
set xlabel "Scaling factor"
set ylabel "Avg Latency (ms)"
set y2label "Database Size (MB)"
set ytics nomirror
set y2tics
# y2tics sets the increment between ticks, not their number
set y2tics autofreq

plot \
  "scaling-latency.txt" using 1:3 axis x1y1 title 'Latency' with linespoints,\
  "scaling-latency.txt" using 1:2 axis x1y2 title 'Database Size' with linespoints
