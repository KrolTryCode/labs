interface dmx_ctrl_if #(
  parameter int TX_DIR        = 4,
  parameter int DIR_SEL_WIDTH = TX_DIR == 1 ? 1 : $clog2( TX_DIR )
)(
  input logic clk_i
);

  logic                         srst_i;
  logic [DIR_SEL_WIDTH - 1 : 0] dir_i;

endinterface