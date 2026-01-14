// Quartus Prime SystemVerilog Template
//
// Simple Dual-Port RAM with different read/write addresses and single read/write clock with read-during-write

module simple_dual_port_ram
	#(parameter int
		ADDR_WIDTH = 4,
		DATA_WIDTH = 8
)
( 
	input [ADDR_WIDTH-1:0] waddr,
	input [ADDR_WIDTH-1:0] raddr,
	input [DATA_WIDTH-1:0] wdata, 
	input we, clk,
	output [DATA_WIDTH - 1:0] q
);
	localparam int WORDS = 1 << ADDR_WIDTH ;

	logic [DATA_WIDTH-1:0] ram [0:WORDS-1];
	
	always_ff@(posedge clk)
		if(we)
				ram[waddr] <= wdata;

	assign q = ram[raddr];

endmodule : simple_dual_port_ram
