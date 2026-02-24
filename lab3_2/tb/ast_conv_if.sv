interface ast_conv_if #(
  parameter int DATA_IN_W  = 64,
  parameter int DATA_OUT_W = 256,
  parameter int CHANNEL_W  = 10
)(
  input logic clk_i
);

  localparam int EMPTY_IN_W  = $clog2( DATA_IN_W  / 8 );
  localparam int EMPTY_OUT_W = $clog2( DATA_OUT_W / 8 );

  logic                   srst_i;
  logic [DATA_IN_W-1:0]   ast_data_i;
  logic                   ast_startofpacket_i;
  logic                   ast_endofpacket_i;
  logic                   ast_valid_i;
  logic [EMPTY_IN_W-1:0]  ast_empty_i;
  logic [CHANNEL_W-1:0 ]  ast_channel_i;
  logic                   ast_ready_o;

  logic [DATA_OUT_W-1:0 ] ast_data_o;
  logic                   ast_startofpacket_o;
  logic                   ast_endofpacket_o;
  logic                   ast_valid_o;
  logic [EMPTY_OUT_W-1:0] ast_empty_o;
  logic [CHANNEL_W-1:0  ] ast_channel_o;
  logic                   ast_ready_i;

  clocking cb_in @( posedge clk_i );
    output ast_data_i;
    output ast_startofpacket_i;
    output ast_endofpacket_i;
    output ast_valid_i;
    output ast_empty_i;
    output ast_channel_i;
    input  ast_ready_o;
  endclocking

clocking cb_out @( posedge clk_i );
  output ast_ready_i;
endclocking

endinterface