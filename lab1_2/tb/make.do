vlib work

vlog -sv deserializer_tb.sv
vlog -sv ../rtl/deserializer.sv

vsim work.deserializer_tb

add wave -b sim:/deserializer_tb/*

run -all
