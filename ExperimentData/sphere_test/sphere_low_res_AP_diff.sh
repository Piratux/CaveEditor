data_file="sphere_low_res_AP_diff.txt"

gnuplot -persist <<- EOF
    set title "Low res sphere AP bake duration difference" offset 0, 1
    set xlabel "Partition subdivisions"
    set ylabel "Time in sec"
    set xrange [14:66]
    set yrange [0:12]
    set xtics 8
    plot "$data_file" every ::0::6 using 1:2 with linespoints lc "red" title "Cell count 128 - cell count 2"
EOF
