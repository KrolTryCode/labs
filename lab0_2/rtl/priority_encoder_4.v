// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"
// CREATED		"Sun Nov 16 02:00:59 2025"

module priority_encoder_4(
	data_val_i,
	data_i,
	data_val_o,
	data_left_o,
	data_right_o
);


input wire	data_val_i;
input wire	[3:0] data_i;
output wire	data_val_o;
output wire	[3:0] data_left_o;
output wire	[3:0] data_right_o;

wire	[2:0] data_left_o_ALTERA_SYNTHESIZED;
wire	[3:1] data_right_o_ALTERA_SYNTHESIZED;
wire	[3:0] ndata_i;

assign	data_val_o = data_val_i;



assign	data_left_o_ALTERA_SYNTHESIZED[1] = data_i[1] & ndata_i[2] & ndata_i[3];

assign	data_right_o_ALTERA_SYNTHESIZED[1] = data_i[1] & ndata_i[0];

assign	data_right_o_ALTERA_SYNTHESIZED[2] = data_i[2] & ndata_i[1] & ndata_i[0];

assign	data_right_o_ALTERA_SYNTHESIZED[3] = data_i[3] & ndata_i[2] & ndata_i[1] & ndata_i[0];

assign	data_left_o_ALTERA_SYNTHESIZED[2] = data_i[2] & ndata_i[3];

assign	ndata_i[3] =  ~data_i[3];

assign	ndata_i[2] =  ~data_i[2];

assign	data_left_o_ALTERA_SYNTHESIZED[0] = data_i[0] & ndata_i[1] & ndata_i[2] & ndata_i[3];

assign	ndata_i[1] =  ~data_i[1];

assign	ndata_i[0] =  ~data_i[0];

assign	data_left_o[3] = data_i[3];
assign	data_left_o[2:0] = data_left_o_ALTERA_SYNTHESIZED;
assign	data_right_o[3:1] = data_right_o_ALTERA_SYNTHESIZED;
assign	data_right_o[0] = data_i[0];

endmodule
