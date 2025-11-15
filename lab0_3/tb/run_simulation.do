vlib work

vlog -sv ../rtl/delay_15.v
vlog -sv ../rtl/mux_0.v
vlog -sv delay_15_tb.sv

vsim work.delay_15_tb

add wave -unsigned sim:/delay_15_tb/*

run -all

