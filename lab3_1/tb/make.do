vlib work

vlog -sv ../rtl/lifo.sv
vlog -sv lifo_if.sv lifo_pkg.sv
vlog -sv lifo_tb.sv

vsim work.lifo_tb

add wave -divider "clock and reset"
add wave sim:/lifo_tb/clk_i
add wave sim:/lifo_tb/lif/srst_i

add wave -divider "write if"
add wave sim:/lifo_tb/lif/wrreq_i
add wave -radix hex sim:/lifo_tb/lif/data_i

add wave -divider "read if"
add wave sim:/lifo_tb/lif/rdreq_i
add wave -radix hex sim:/lifo_tb/lif/q_o

add wave -divider "flags"
add wave sim:/lifo_tb/lif/empty_o
add wave sim:/lifo_tb/lif/almost_empty_o
add wave sim:/lifo_tb/lif/almost_full_o
add wave sim:/lifo_tb/lif/full_o
add wave -radix unsigned sim:/lifo_tb/lif/usedw_o

run -all

wave zoom full