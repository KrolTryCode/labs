interface inc_if #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
)(
  input logic clk_i
);
  localparam int BYTE_CNT = DATA_WIDTH / 8;

  logic                  srst_i;
  logic [ADDR_WIDTH-1:0] base_addr_i;
  logic [ADDR_WIDTH-1:0] length_i;
  logic                  run_i;
  logic                  waitrequest_o;

  // Avalon-MM read
  logic [ADDR_WIDTH-1:0] amm_rd_address;
  logic                  amm_rd_read;
  logic [DATA_WIDTH-1:0] amm_rd_readdata;
  logic                  amm_rd_readdatavalid;
  logic                  amm_rd_waitrequest;

  // Avalon-MM write
  logic [ADDR_WIDTH-1:0] amm_wr_address;
  logic                  amm_wr_write;
  logic [DATA_WIDTH-1:0] amm_wr_writedata;
  logic [BYTE_CNT-1:0  ] amm_wr_byteenable;
  logic                  amm_wr_waitrequest;

endinterface
