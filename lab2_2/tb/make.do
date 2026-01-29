vlib work

vlog -sv avalon_st_tb_pkg.sv
vlog -sv avalon_st_sorter_tb.sv

vlog -sv ../rtl/simple_dual_port_ram.sv
vlog -sv ../rtl/avalon_st_sorter.sv

vsim work.avalon_st_sorter_tb

add wave -b sim:/avalon_st_sorter_tb/*
add wave -divider "sink"
add wave sim:/avalon_st_sorter_tb/snk_if/*
add wave -divider "source"
add wave sim:/avalon_st_sorter_tb/src_if/*
run -all

