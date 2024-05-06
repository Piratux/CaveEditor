data_file="dragon_speed_test_all.txt"
output_file="dragon_speed_test_AP.png"

gnuplot -persist <<- EOF
    set terminal pngcairo enhanced font "Arial,12" size 800,600
    set output "$output_file"
    set title "Stanford dragon baking speed" offset 0, 1
    set xlabel "Cell count"
    set ylabel "Time in sec"
    set xrange [8:264]
    set yrange [0:5500]
    set xtics 16
    plot "$data_file" every ::14::19 using 1:2 with linespoints lc "purple" title "Accurate partitioned"
EOF
