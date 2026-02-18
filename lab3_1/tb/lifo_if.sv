interface lifo_if #(
  parameter int DWIDTH = 16,
  parameter int AWIDTH = 8
)(
  input logic clk_i
);
  
  logic               srst_i;
  logic               wrreq_i;
  logic [DWIDTH-1:0]  data_i;
  logic               rdreq_i;
  logic [DWIDTH-1:0]  q_o;
  logic               almost_empty_o;
  logic               empty_o;
  logic               almost_full_o;
  logic               full_o;
  logic [AWIDTH:0  ]  usedw_o;

  clocking cb @(posedge clk_i);
    output srst_i;
    output wrreq_i;
    output data_i;
    output rdreq_i;
    input  q_o;
    input  almost_empty_o;
    input  empty_o;
    input  almost_full_o;
    input  full_o;
    input  usedw_o;
  endclocking

  modport driver (
    clocking cb,
    input  clk_i,
    output srst_i,
    output wrreq_i,
    output data_i,
    output rdreq_i
  );

modport monitor (
    clocking cb,
    input srst_i,
    input wrreq_i,
    input data_i,
    input rdreq_i
);

endinterface