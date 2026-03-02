interface avalon_st_if #(
  parameter int DATA_W    = 64,
  parameter int CHANNEL_W = 8
)(
  input logic clk_i
);

  localparam int EMPTY_W = $clog2( DATA_W / 8 );

  logic [DATA_W-1:0   ] data;
  logic                 startofpacket;
  logic                 endofpacket;
  logic                 valid;
  logic [EMPTY_W-1:0  ] empty;
  logic [CHANNEL_W-1:0] channel;
  logic                 ready;

  clocking src_cb @( posedge clk_i );
    output data, startofpacket, endofpacket, valid, empty, channel;
  endclocking

  clocking snk_cb @( posedge clk_i );
    output ready;
  endclocking

  clocking mon_cb @( posedge clk_i );
    input data, startofpacket, endofpacket, valid, empty, channel, ready;
  endclocking

  modport source (
    clocking src_cb,
    input    clk_i,
    input    ready
  );

  modport sink (
    clocking snk_cb,
    input    clk_i
  );

  modport monitor (
    clocking mon_cb,
    input    clk_i
  );

endinterface