interface inc_ctrl_if #(
  parameter int ADDR_W = 10
)(
  input logic clk_i
);

  logic              srst_i;
  logic [ADDR_W-1:0] base_addr_i;
  logic [ADDR_W-1:0] length_i;
  logic              run_i;
  logic              waitrequest_o;

endinterface