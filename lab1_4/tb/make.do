vlib work

vlog -sv bit_population_counter_tb.sv
vlog -sv ../rtl/bit_population_counter.sv

vsim work.bit_population_counter_tb

add wave -b sim:/bit_population_counter_tb/*

run -all
