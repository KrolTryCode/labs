vdel -lib work -all
vlib work

vlog -sv ../rtl/ast_width_extender.sv

vlog -sv avalon_st_if.sv
vlog -sv ast_conv_ctrl_if.sv
vlog -sv ast_conv_pkg.sv
vlog -sv ast_conv_tb.sv

vsim work.ast_conv_tb -suppress 3839

add wave -divider "Clock / Reset"
add wave sim:/ast_conv_tb/clk_i
add wave sim:/ast_conv_tb/ctrl_if/srst_i

add wave -divider "Input (sink)"
add wave sim:/ast_conv_tb/in_if/valid
add wave sim:/ast_conv_tb/in_if/ready
add wave sim:/ast_conv_tb/in_if/startofpacket
add wave sim:/ast_conv_tb/in_if/endofpacket
add wave -radix hex      sim:/ast_conv_tb/in_if/data
add wave -radix unsigned sim:/ast_conv_tb/in_if/empty
add wave -radix hex      sim:/ast_conv_tb/in_if/channel

add wave -divider "Output (source)"
add wave sim:/ast_conv_tb/out_if/valid
add wave sim:/ast_conv_tb/out_if/ready
add wave sim:/ast_conv_tb/out_if/startofpacket
add wave sim:/ast_conv_tb/out_if/endofpacket
add wave -radix hex      sim:/ast_conv_tb/out_if/data
add wave -radix unsigned sim:/ast_conv_tb/out_if/empty
add wave -radix hex      sim:/ast_conv_tb/out_if/channel

run -all

wave zoom full
