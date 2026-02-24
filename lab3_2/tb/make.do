vlib work

vlog -sv ../rtl/ast_width_extender.sv

vlog -sv ast_conv_if.sv
vlog -sv ast_conv_pkg.sv
vlog -sv ast_conv_tb.sv

vsim work.ast_conv_tb

add wave -divider "Clock / Reset"
add wave sim:/ast_conv_tb/clk_i
add wave sim:/ast_conv_tb/conv_if/srst_i

add wave -divider "Input (sink)"
add wave sim:/ast_conv_tb/conv_if/ast_valid_i
add wave sim:/ast_conv_tb/conv_if/ast_ready_o
add wave sim:/ast_conv_tb/conv_if/ast_startofpacket_i
add wave sim:/ast_conv_tb/conv_if/ast_endofpacket_i
add wave -radix hex sim:/ast_conv_tb/conv_if/ast_data_i
add wave -radix unsigned sim:/ast_conv_tb/conv_if/ast_empty_i
add wave -radix hex sim:/ast_conv_tb/conv_if/ast_channel_i

add wave -divider "Output (source)"
add wave sim:/ast_conv_tb/conv_if/ast_valid_o
add wave sim:/ast_conv_tb/conv_if/ast_ready_i
add wave sim:/ast_conv_tb/conv_if/ast_startofpacket_o
add wave sim:/ast_conv_tb/conv_if/ast_endofpacket_o
add wave -radix hex sim:/ast_conv_tb/conv_if/ast_data_o
add wave -radix unsigned sim:/ast_conv_tb/conv_if/ast_empty_o
add wave -radix hex sim:/ast_conv_tb/conv_if/ast_channel_o

run -all

wave zoom full
