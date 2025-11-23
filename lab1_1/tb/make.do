vlib work

vlog -sv serializer_tb.sv
vlog -sv ../rtl/serializer.sv

vsim work.serializer_tb

add wave -b sim:/serializer_tb/*

run -all
