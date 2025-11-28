vlib work

vlog -sv priority_encoder_tb.sv
vlog -sv ../rtl/priority_encoder.sv

vsim work.priority_encoder_tb

add wave -b sim:/priority_encoder_tb/*

run -all
