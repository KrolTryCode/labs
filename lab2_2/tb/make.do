vlib work

vlog -sv avalon_st_sorter_tb.sv
vlog -sv ../rtl/simple_dual_port_ram.sv
vlog -sv ../rtl/avalon_st_sorter.sv


vsim work.avalon_st_sorter_tb

add wave -b sim:/avalon_st_sorter_tb/*

run -all
