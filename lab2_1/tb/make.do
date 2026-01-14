vlib work

set QUARTUS_PATH $::env(QUARTUS_ROOTDIR)
set ALTERA_LIB "$QUARTUS_PATH/eda/sim_lib"

vlog "$ALTERA_LIB/altera_mf.v" 

vlog -sv ../rtl/simple_dual_port_ram.sv
vlog -sv fifo_tb.sv
vlog -sv ../rtl/fifo.sv

vsim work.fifo_tb

add wave -divider "inputs"
add wave sim:/fifo_tb/clk_i
add wave sim:/fifo_tb/srst_i
add wave sim:/fifo_tb/wrreq_i
add wave sim:/fifo_tb/rdreq_i
add wave -radix hex sim:/fifo_tb/data_i

add wave -divider "output q"
add wave -radix hex sim:/fifo_tb/q_dut
add wave -radix hex sim:/fifo_tb/q_gold

add wave -divider "output empty"
add wave sim:/fifo_tb/empty_dut
add wave sim:/fifo_tb/empty_gold

add wave -divider "output full"
add wave sim:/fifo_tb/full_dut
add wave sim:/fifo_tb/full_gold

add wave -divider "output usedw"
add wave -radix unsigned sim:/fifo_tb/usedw_dut
add wave -radix unsigned sim:/fifo_tb/usedw_gold

add wave -divider "output almost_full"
add wave sim:/fifo_tb/almost_full_dut
add wave sim:/fifo_tb/almost_full_gold

add wave -divider "output almost_empty"
add wave sim:/fifo_tb/almost_empty_dut
add wave sim:/fifo_tb/almost_empty_gold

run -all
