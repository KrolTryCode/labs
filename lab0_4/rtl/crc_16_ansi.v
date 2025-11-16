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
// CREATED		"Sun Nov 16 14:58:02 2025"

module crc_16_ansi(
	clk_i,
	rst_i,
	data_i,
	data_o
);


input wire	clk_i;
input wire	rst_i;
input wire	data_i;
output wire	[15:0] data_o;

reg	[15:0] data;
wire	nrst_i;
wire	tap;
wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_1;




assign	SYNTHESIZED_WIRE_1 = data[14] ^ tap;

assign	nrst_i =  ~rst_i;


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[3] <= 1;
	end
else
	begin
	data[3] <= data[4];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[11] <= 1;
	end
else
	begin
	data[11] <= data[12];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[2] <= 1;
	end
else
	begin
	data[2] <= data[3];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[10] <= 1;
	end
else
	begin
	data[10] <= data[11];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[1] <= 1;
	end
else
	begin
	data[1] <= data[2];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[9] <= 1;
	end
else
	begin
	data[9] <= data[10];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[0] <= 1;
	end
else
	begin
	data[0] <= SYNTHESIZED_WIRE_0;
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[8] <= 1;
	end
else
	begin
	data[8] <= data[9];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[15] <= 1;
	end
else
	begin
	data[15] <= tap;
	end
end

assign	tap = data[0] ^ data_i;


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[7] <= 1;
	end
else
	begin
	data[7] <= data[8];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[6] <= 1;
	end
else
	begin
	data[6] <= data[7];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[5] <= 1;
	end
else
	begin
	data[5] <= data[6];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[4] <= 1;
	end
else
	begin
	data[4] <= data[5];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[14] <= 1;
	end
else
	begin
	data[14] <= data[15];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[13] <= 1;
	end
else
	begin
	data[13] <= SYNTHESIZED_WIRE_1;
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[12] <= 1;
	end
else
	begin
	data[12] <= data[13];
	end
end

assign	SYNTHESIZED_WIRE_0 = data[1] ^ tap;

assign	data_o = data;

endmodule
