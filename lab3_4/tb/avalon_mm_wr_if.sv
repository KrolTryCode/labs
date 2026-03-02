interface avalon_mm_wr_if #(
  parameter int ADDR_W    = 10,
  parameter int DATA_W    = 64
)(
  input logic clk_i
);

  localparam int BE_W = DATA_W / 8;

  logic [ADDR_W-1:0] address;
  logic              write;
  logic [DATA_W-1:0] writedata;
  logic [BE_W-1:0]   byteenable;
  logic              waitrequest;

  modport master (
    input  clk_i,
    output address, write, writedata, byteenable,
    input  waitrequest
  );

  modport slave (
    input  clk_i,
    input  address, write, writedata, byteenable,
    output waitrequest
  );

  modport monitor (
    input clk_i,
    input address, write, writedata, byteenable, waitrequest
  );

endinterface
