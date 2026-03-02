interface avalon_mm_rd_if #(
  parameter int ADDR_W = 10,
  parameter int DATA_W = 64
)(
  input logic clk_i
);

  logic [ADDR_W-1:0] address;
  logic              read;
  logic [DATA_W-1:0] readdata;
  logic              readdatavalid;
  logic              waitrequest;

  modport master (
    input  clk_i,
    output address, read,
    input  readdata, readdatavalid, waitrequest
  );

  modport slave (
    input  clk_i,
    input  address, read,
    output readdata, readdatavalid, waitrequest
  );

  modport monitor (
    input clk_i,
    input address, read, readdata, readdatavalid, waitrequest
  );

endinterface
