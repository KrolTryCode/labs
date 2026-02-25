vlib work

vlog -sv ../rtl/ast_dmx.sv

vlog -sv dmx_if.sv dmx_pkg.sv dmx_tb.sv

vsim work.dmx_tb

add wave -divider "clock / reset"
add wave sim:/dmx_tb/clk_i
add wave sim:/dmx_tb/dif/srst_i

add wave -divider "dir"
add wave -radix unsigned sim:/dmx_tb/dif/dir_i

add wave -divider "input AST"
add wave sim:/dmx_tb/dif/ast_valid_i
add wave sim:/dmx_tb/dif/ast_ready_o
add wave sim:/dmx_tb/dif/ast_startofpacket_i
add wave sim:/dmx_tb/dif/ast_endofpacket_i
add wave -radix hex sim:/dmx_tb/dif/ast_data_i
add wave -radix unsigned sim:/dmx_tb/dif/ast_empty_i
add wave -radix hex sim:/dmx_tb/dif/ast_channel_i

add wave -divider "output AST 0"
add wave sim:/dmx_tb/dif/ast_valid_o(0)
add wave sim:/dmx_tb/dif/ast_ready_i(0)
add wave sim:/dmx_tb/dif/ast_startofpacket_o(0)
add wave sim:/dmx_tb/dif/ast_endofpacket_o(0)
add wave -radix hex sim:/dmx_tb/dif/ast_data_o(0)
add wave -radix unsigned sim:/dmx_tb/dif/ast_empty_o(0)
add wave -radix hex sim:/dmx_tb/dif/ast_channel_o(0)

add wave -divider "output AST 1"
add wave sim:/dmx_tb/dif/ast_valid_o(1)
add wave sim:/dmx_tb/dif/ast_ready_i(1)
add wave sim:/dmx_tb/dif/ast_startofpacket_o(1)
add wave sim:/dmx_tb/dif/ast_endofpacket_o(1)
add wave -radix hex sim:/dmx_tb/dif/ast_data_o(1)
add wave -radix unsigned sim:/dmx_tb/dif/ast_empty_o(1)
add wave -radix hex sim:/dmx_tb/dif/ast_channel_o(1)

add wave -divider "output AST 2"
add wave sim:/dmx_tb/dif/ast_valid_o(2)
add wave sim:/dmx_tb/dif/ast_ready_i(2)
add wave sim:/dmx_tb/dif/ast_startofpacket_o(2)
add wave sim:/dmx_tb/dif/ast_endofpacket_o(2)
add wave -radix hex sim:/dmx_tb/dif/ast_data_o(2)
add wave -radix unsigned sim:/dmx_tb/dif/ast_empty_o(2)
add wave -radix hex sim:/dmx_tb/dif/ast_channel_o(2)

add wave -divider "output AST 3"
add wave sim:/dmx_tb/dif/ast_valid_o(3)
add wave sim:/dmx_tb/dif/ast_ready_i(3)
add wave sim:/dmx_tb/dif/ast_startofpacket_o(3)
add wave sim:/dmx_tb/dif/ast_endofpacket_o(3)
add wave -radix hex sim:/dmx_tb/dif/ast_data_o(3)
add wave -radix unsigned sim:/dmx_tb/dif/ast_empty_o(3)
add wave -radix hex sim:/dmx_tb/dif/ast_channel_o(3)

run -all

wave zoom full
