#!/usr/bin/gnuplot -persist

set term png size 1024,768
set out 'resultados.png'

set title "Performance"
set xlabel "Workloads"
set ylabel "Runtime (milliseconds)"

set xtics ( "Q18" 1,"Q21" 2)

#set logscale y 100
#set border 3 front linetype -1 linewidth 1.000
set boxwidth 0.95 absolute
set style fill   solid 1.00 noborder


set grid nopolar
set grid noxtics nomxtics ytics nomytics noztics nomztics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
set grid layerdefault   linetype 0 linewidth 1.000,  linetype 0 linewidth 1.000

set key left box
#set pointsize 2
set style data histograms
set style histogram clustered gap 1 title  offset character 0, 0, 0

set bmargin  3

set xrange [ 0.5 : 2.5]


plot  'resultados.dat' u 1 t "Default", '' u 2 t "Optimized"
