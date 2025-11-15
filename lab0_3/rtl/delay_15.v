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
// CREATED		"Sat Nov 15 21:40:20 2025"

module delay_15(
	clk_i,
	rst_i,
	data_i,
	data_delay_i,
	data_o
);


input wire	clk_i;
input wire	rst_i;
input wire	data_i;
input wire	[3:0] data_delay_i;
output wire	data_o;

reg	[15:1] data;
wire	[0:0] data_;
wire	nrst_i;

wire	[15:0] GDFX_TEMP_SIGNAL_0;


assign	GDFX_TEMP_SIGNAL_0 = {data[15:1],data_[0]};


mux_0	b2v_inst(
	.data(GDFX_TEMP_SIGNAL_0),
	.sel(data_delay_i),
	.result(data_o));


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[6] <= 0;
	end
else
	begin
	data[6] <= data[5];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[8] <= 0;
	end
else
	begin
	data[8] <= data[7];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[9] <= 0;
	end
else
	begin
	data[9] <= data[8];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[10] <= 0;
	end
else
	begin
	data[10] <= data[9];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[11] <= 0;
	end
else
	begin
	data[11] <= data[10];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[12] <= 0;
	end
else
	begin
	data[12] <= data[11];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[13] <= 0;
	end
else
	begin
	data[13] <= data[12];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[7] <= 0;
	end
else
	begin
	data[7] <= data[6];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[14] <= 0;
	end
else
	begin
	data[14] <= data[13];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[15] <= 0;
	end
else
	begin
	data[15] <= data[14];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[1] <= 0;
	end
else
	begin
	data[1] <= data_i;
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[2] <= 0;
	end
else
	begin
	data[2] <= data[1];
	end
end


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[3] <= 0;
	end
else
	begin
	data[3] <= data[2];
	end
end

assign	data_ = data_i & nrst_i;


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[4] <= 0;
	end
else
	begin
	data[4] <= data[3];
	end
end

assign	nrst_i =  ~rst_i;


always@(posedge clk_i or negedge nrst_i)
begin
if (!nrst_i)
	begin
	data[5] <= 0;
	end
else
	begin
	data[5] <= data[4];
	end
end


endmodule
