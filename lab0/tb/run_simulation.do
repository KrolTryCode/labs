vlib work

vlog -sv mux.v mux_tb.sv

vsim work.mux_tb

add wave -unsigned \
sim:/mux_tb/data0_i \
sim:/mux_tb/data1_i \
sim:/mux_tb/data2_i \
sim:/mux_tb/data3_i \
sim:/mux_tb/direction_i \
sim:/mux_tb/data_o

run -all