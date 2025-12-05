vlib work

vlog -sv debouncer_tb.sv
vlog -sv ../rtl/debouncer.sv

vsim work.debouncer_tb

add wave -b sim:/debouncer_tb/*

run -all
