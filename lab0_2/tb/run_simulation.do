vlib work

vlog -sv ../rtl/priority_encoder_4.v
vlog -sv priority_encoder_4_tb.sv

vsim work.priority_encoder_4_tb

add wave -binary \
sim:/priority_encoder_4_tb/data_i \
sim:/priority_encoder_4_tb/data_val_i \
sim:/priority_encoder_4_tb/data_left_o \
sim:/priority_encoder_4_tb/data_right_o \
sim:/priority_encoder_4_tb/data_val_o \

run -all
