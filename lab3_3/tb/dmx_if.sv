interface dmx_if #(
  parameter int DATA_WIDTH    = 64,
  parameter int EMPTY_WIDTH   = $clog2( DATA_WIDTH / 8 ),
  parameter int CHANNEL_WIDTH = 8,
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
)(
  input logic clk_i
);
  logic                         srst_i;
  logic [DIR_SEL_WIDTH - 1 : 0] dir_i;

  logic [DATA_WIDTH    - 1 : 0] ast_data_i;
  logic                         ast_startofpacket_i;
  logic                         ast_endofpacket_i;
  logic                         ast_valid_i;
  logic [EMPTY_WIDTH   - 1 : 0] ast_empty_i;
  logic [CHANNEL_WIDTH - 1 : 0] ast_channel_i;
  logic                         ast_ready_o;

  logic [DATA_WIDTH    - 1 : 0] ast_data_o          [TX_DIR-1:0];
  logic                         ast_startofpacket_o [TX_DIR-1:0];
  logic                         ast_endofpacket_o   [TX_DIR-1:0];
  logic                         ast_valid_o         [TX_DIR-1:0];
  logic [EMPTY_WIDTH   - 1 : 0] ast_empty_o         [TX_DIR-1:0];
  logic [CHANNEL_WIDTH - 1 : 0] ast_channel_o       [TX_DIR-1:0];
  logic                         ast_ready_i         [TX_DIR-1:0];

  clocking drv_cb @( posedge clk_i );
    output dir_i;
    output ast_data_i;
    output ast_startofpacket_i;
    output ast_endofpacket_i;
    output ast_valid_i;
    output ast_empty_i;
    output ast_channel_i;
    input  ast_ready_o;
    output ast_ready_i;
  endclocking

  clocking mon_cb @( posedge clk_i );
    input ast_data_o;
    input ast_startofpacket_o;
    input ast_endofpacket_o;
    input ast_valid_o;
    input ast_empty_o;
    input ast_ready_i;
  endclocking

  modport driver (
    clocking drv_cb,
    input    clk_i,
    input    ast_ready_o,
    output   srst_i
  );

  modport monitor (
    clocking mon_cb,
    input    ast_channel_o
  );

endinterface