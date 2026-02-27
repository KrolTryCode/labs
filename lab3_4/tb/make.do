vlib work

vlog -sv ../rtl/byte_inc.sv
vlog -sv mem_model.sv
vlog -sv inc_if.sv
vlog -sv inc_pkg.sv inc_tb.sv

vsim -sv_seed 1 work.inc_tb

add wave -divider "control"
add wave sim:/inc_tb/clk_i
add wave sim:/inc_tb/dif/srst_i
add wave -radix hex      sim:/inc_tb/dif/base_addr_i
add wave -radix unsigned sim:/inc_tb/dif/length_i
add wave sim:/inc_tb/dif/run_i
add wave sim:/inc_tb/dif/waitrequest_o

add wave -divider "Avalon-MM read"
add wave -radix hex sim:/inc_tb/dif/amm_rd_address
add wave sim:/inc_tb/dif/amm_rd_read
add wave sim:/inc_tb/dif/amm_rd_waitrequest
add wave -radix hex sim:/inc_tb/dif/amm_rd_readdata
add wave sim:/inc_tb/dif/amm_rd_readdatavalid

add wave -divider "Avalon-MM write"
add wave -radix hex sim:/inc_tb/dif/amm_wr_address
add wave sim:/inc_tb/dif/amm_wr_write
add wave sim:/inc_tb/dif/amm_wr_waitrequest
add wave -radix hex sim:/inc_tb/dif/amm_wr_writedata
add wave -radix hex sim:/inc_tb/dif/amm_wr_byteenable

run -all

wave zoom full
