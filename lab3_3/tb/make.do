vlib work

vlog -sv ../rtl/ast_dmx.sv
vlog -sv ../../lab3_2/tb/avalon_st_if.sv
vlog -sv dmx_ctrl_if.sv dmx_pkg.sv dmx_tb.sv

vsim work.dmx_tb -suppress 3839

add wave -divider "clock / reset"
add wave sim:/dmx_tb/clk_i
add wave sim:/dmx_tb/ctrl_if/srst_i

add wave -divider "dir"
add wave -radix unsigned sim:/dmx_tb/ctrl_if/dir_i

add wave -divider "input AST"
add wave sim:/dmx_tb/ast_in_if/valid
add wave sim:/dmx_tb/ast_in_if/ready
add wave sim:/dmx_tb/ast_in_if/startofpacket
add wave sim:/dmx_tb/ast_in_if/endofpacket
add wave -radix hex      sim:/dmx_tb/ast_in_if/data
add wave -radix unsigned sim:/dmx_tb/ast_in_if/empty
add wave -radix hex      sim:/dmx_tb/ast_in_if/channel

add wave -divider "output AST 0"
add wave sim:/dmx_tb/ast_out0_if/valid
add wave sim:/dmx_tb/ast_out0_if/ready
add wave sim:/dmx_tb/ast_out0_if/startofpacket
add wave sim:/dmx_tb/ast_out0_if/endofpacket
add wave -radix hex      sim:/dmx_tb/ast_out0_if/data
add wave -radix unsigned sim:/dmx_tb/ast_out0_if/empty
add wave -radix hex      sim:/dmx_tb/ast_out0_if/channel

add wave -divider "output AST 1"
add wave sim:/dmx_tb/ast_out1_if/valid
add wave sim:/dmx_tb/ast_out1_if/ready
add wave sim:/dmx_tb/ast_out1_if/startofpacket
add wave sim:/dmx_tb/ast_out1_if/endofpacket
add wave -radix hex      sim:/dmx_tb/ast_out1_if/data
add wave -radix unsigned sim:/dmx_tb/ast_out1_if/empty
add wave -radix hex      sim:/dmx_tb/ast_out1_if/channel

add wave -divider "output AST 2"
add wave sim:/dmx_tb/ast_out2_if/valid
add wave sim:/dmx_tb/ast_out2_if/ready
add wave sim:/dmx_tb/ast_out2_if/startofpacket
add wave sim:/dmx_tb/ast_out2_if/endofpacket
add wave -radix hex      sim:/dmx_tb/ast_out2_if/data
add wave -radix unsigned sim:/dmx_tb/ast_out2_if/empty
add wave -radix hex      sim:/dmx_tb/ast_out2_if/channel

add wave -divider "output AST 3"
add wave sim:/dmx_tb/ast_out3_if/valid
add wave sim:/dmx_tb/ast_out3_if/ready
add wave sim:/dmx_tb/ast_out3_if/startofpacket
add wave sim:/dmx_tb/ast_out3_if/endofpacket
add wave -radix hex      sim:/dmx_tb/ast_out3_if/data
add wave -radix unsigned sim:/dmx_tb/ast_out3_if/empty
add wave -radix hex      sim:/dmx_tb/ast_out3_if/channel

run -all

wave zoom full
