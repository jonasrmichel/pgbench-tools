set term png size 640,480
set terminal png small
set output "3d-latency.png"
set title "pgbench latency"
set ylabel "Scaling factor"
set yrange [*:*] reverse
set xlabel "Clients"
set zlabel "Avg Latency (ms)"
set dgrid3d 30,30
set hidden3d
splot "3d-latency.txt" u 2:1:3 with lines
