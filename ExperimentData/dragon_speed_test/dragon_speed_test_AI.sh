data_file="dragon_speed_test_all.txt"
output_file="dragon_speed_test_AI.png"

gnuplot -persist <<- EOF
    set terminal pngcairo enhanced font "Arial,12" size 800,600
    set output "$output_file"
    set title "Stanford dragon baking speed" offset 0, 1
    set xlabel "Cell count"
    set ylabel "Time in sec"
    set xrange [12:132]
    set yrange [0:5500]
    set xtics 16
    plot "$data_file" every ::5::9 using 1:2 with linespoints lc "blue" title "Approximate interpolation"
EOF
