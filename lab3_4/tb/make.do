vdel -lib work -all
vlib work

vlog -sv ../rtl/byte_inc.sv
vlog -sv mem_model.sv
vlog -sv avalon_mm_rd_if.sv
vlog -sv avalon_mm_wr_if.sv
vlog -sv inc_ctrl_if.sv
vlog -sv inc_pkg.sv inc_tb.sv

vsim -sv_seed 1 work.inc_tb

add wave -divider "control"
add wave sim:/inc_tb/clk_i
add wave sim:/inc_tb/ctrl_if/srst_i
add wave -radix hex      sim:/inc_tb/ctrl_if/base_addr_i
add wave -radix unsigned sim:/inc_tb/ctrl_if/length_i
add wave sim:/inc_tb/ctrl_if/run_i
add wave sim:/inc_tb/ctrl_if/waitrequest_o

add wave -divider "Avalon-MM read"
add wave -radix hex sim:/inc_tb/rd_if/address
add wave sim:/inc_tb/rd_if/read
add wave sim:/inc_tb/rd_if/waitrequest
add wave -radix hex sim:/inc_tb/rd_if/readdata
add wave sim:/inc_tb/rd_if/readdatavalid

add wave -divider "Avalon-MM write"
add wave -radix hex sim:/inc_tb/wr_if/address
add wave sim:/inc_tb/wr_if/write
add wave sim:/inc_tb/wr_if/waitrequest
add wave -radix hex sim:/inc_tb/wr_if/writedata
add wave -radix hex sim:/inc_tb/wr_if/byteenable

run -all

wave zoom full
