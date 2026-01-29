interface avalon_st_if #(
  parameter DWIDTH = 10
)(
  input logic clk,
  input logic srst
);
  logic [DWIDTH-1:0] data;
  logic              startofpacket;
  logic              endofpacket;
  logic              valid;
  logic              ready;

  modport sink (
    input  clk,
    input  srst,
    input  data,
    input  startofpacket,
    input  endofpacket,
    input  valid,
    output ready
  );

  modport source (
    input  clk,
    input  srst,
    output data,
    output startofpacket,
    output endofpacket,
    output valid,
    input  ready
  );

endinterface