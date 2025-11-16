vlib work

vlog -sv crc_16_ansi_tb.sv
vlog -sv ../rtl/crc_16_ansi.v

vsim work.crc_16_ansi_tb

add wave -hex sim:/crc_16_ansi_tb/*

run -all

