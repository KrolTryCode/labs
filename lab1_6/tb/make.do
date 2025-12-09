vlib work

vlog -sv traffic_lights_tb.sv
vlog -sv ../rtl/traffic_lights.sv

vsim work.traffic_lights_tb

add wave -b sim:/traffic_lights_tb/*

run -all
