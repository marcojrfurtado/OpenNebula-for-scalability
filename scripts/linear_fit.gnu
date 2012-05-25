#!/usr/bin/gnuplot -p

set xtics 0.1
set xrange [0:1]

file='~/var/calibration_results/1/cpu_operator_cost.dat'

f(x) = m*x + b
fit f(x) file  using 1:2 via m,b
plot file using 1:2 title 'CPU limiting' with points, f(x) title 'Model fit'


