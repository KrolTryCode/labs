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
// CREATED		"Wed Nov 12 10:44:37 2025"

module mux(
	data0_i,
	data1_i,
	data2_i,
	data3_i,
	direction_i,
	data_o
);


input wire	[1:0] data0_i;
input wire	[1:0] data1_i;
input wire	[1:0] data2_i;
input wire	[1:0] data3_i;
input wire	[1:0] direction_i;
output wire	[1:0] data_o;

wire	[1:0] data_o_ALTERA_SYNTHESIZED;
wire	en0;
wire	en1;
wire	en2;
wire	en3;
wire	[1:0] not_direction_i;
wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_1;
wire	SYNTHESIZED_WIRE_2;
wire	SYNTHESIZED_WIRE_3;
wire	SYNTHESIZED_WIRE_4;
wire	SYNTHESIZED_WIRE_5;
wire	SYNTHESIZED_WIRE_6;
wire	SYNTHESIZED_WIRE_7;




assign	en0 = not_direction_i[0] & not_direction_i[1];

assign	en1 = direction_i[0] & not_direction_i[1];

assign	en2 = not_direction_i[0] & direction_i[1];

assign	en3 = direction_i[0] & direction_i[1];

assign	not_direction_i[0] =  ~direction_i[0];

assign	not_direction_i[1] =  ~direction_i[1];

assign	data_o_ALTERA_SYNTHESIZED[0] = SYNTHESIZED_WIRE_0 | SYNTHESIZED_WIRE_1 | SYNTHESIZED_WIRE_2 | SYNTHESIZED_WIRE_3;

assign	SYNTHESIZED_WIRE_3 = en1 & data1_i[0];

assign	data_o_ALTERA_SYNTHESIZED[1] = SYNTHESIZED_WIRE_4 | SYNTHESIZED_WIRE_5 | SYNTHESIZED_WIRE_6 | SYNTHESIZED_WIRE_7;

assign	SYNTHESIZED_WIRE_1 = en2 & data2_i[0];

assign	SYNTHESIZED_WIRE_2 = en3 & data3_i[0];

assign	SYNTHESIZED_WIRE_4 = en0 & data0_i[1];

assign	SYNTHESIZED_WIRE_7 = en1 & data1_i[1];

assign	SYNTHESIZED_WIRE_5 = en2 & data2_i[1];

assign	SYNTHESIZED_WIRE_6 = en3 & data3_i[1];

assign	SYNTHESIZED_WIRE_0 = en0 & data0_i[0];

assign	data_o = data_o_ALTERA_SYNTHESIZED;

endmodule
