data_file="sphere_low_res_AP.txt"

gnuplot -persist <<- EOF
    set title "Low res sphere AP bake duration" offset 0, 1
    set xlabel "Partition subdivisions"
    set ylabel "Time in sec"
    set xrange [14:66]
    set yrange [0:60]
    set xtics 8
    plot "$data_file" every ::0::6 using 2:3 with linespoints lc "red" title "Cell count = 2", \
         "$data_file" every ::7::13 using 2:3 with linespoints lc "blue" title "Cell count = 128"
EOF
